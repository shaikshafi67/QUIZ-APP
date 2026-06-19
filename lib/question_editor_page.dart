import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'quiz_page.dart';

class _BatchItem {
  final Map<String, dynamic> data;
  final Uint8List? questionImageBytes;
  final Uint8List? categoryImageBytes;

  _BatchItem({
    required this.data,
    this.questionImageBytes,
    this.categoryImageBytes,
  });
}

class QuestionEditorPage extends StatefulWidget {
  final QuizQuestion? questionToEdit;
  const QuestionEditorPage({super.key, this.questionToEdit});

  @override
  State<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  final _categoryController = TextEditingController();
  final _timerController = TextEditingController(text: '30');

  int? _correctAnswerIndex;
  String _selectedDifficulty = 'Easy';
  final List<String> _difficultyOptions = ['Easy', 'Medium', 'Hard'];

  Uint8List? _pickedQuestionImageBytes;
  bool _isQuestionImagePicked = false;
  String _existingQuestionImageUrl = '';

  Uint8List? _pickedCategoryImageBytes;
  bool _isCategoryImagePicked = false;

  final List<_BatchItem> _questionBatch = [];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool get _isEditMode => widget.questionToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final q = widget.questionToEdit!;
      _questionController.text = q.questionText;
      _categoryController.text = q.categoryName;
      _option1Controller.text = q.options[0];
      _option2Controller.text = q.options[1];
      _option3Controller.text = q.options[2];
      _option4Controller.text = q.options[3];
      _correctAnswerIndex = q.correctAnswerIndex;
      _timerController.text = q.timerSeconds.toString();
      _selectedDifficulty = q.difficulty;
      if (q.imageUrl.isNotEmpty) _existingQuestionImageUrl = q.imageUrl;
    }
  }

  Future<void> _pickQuestionImage() async {
    final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 50, maxWidth: 600);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedQuestionImageBytes = bytes;
        _isQuestionImagePicked = true;
        _existingQuestionImageUrl = '';
      });
    }
  }

  Future<void> _pickCategoryImage() async {
    final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 50, maxWidth: 400);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedCategoryImageBytes = bytes;
        _isCategoryImagePicked = true;
      });
    }
  }

  void _addQuestionToBatch() {
    if (!_formKey.currentState!.validate()) return;
    if (_correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the correct answer')));
      return;
    }

    final Map<String, dynamic> questionData = {
      'category': _categoryController.text.trim(),
      'category_image_url': '',
      'question_text': _questionController.text.trim(),
      'image_url': '',
      'options': [
        _option1Controller.text.trim(),
        _option2Controller.text.trim(),
        _option3Controller.text.trim(),
        _option4Controller.text.trim(),
      ],
      'correct_answer_index': _correctAnswerIndex,
      'timer_seconds': int.tryParse(_timerController.text) ?? 30,
      'difficulty': _selectedDifficulty,
    };

    setState(() {
      _questionBatch.add(_BatchItem(
        data: questionData,
        questionImageBytes: _pickedQuestionImageBytes,
        categoryImageBytes: _pickedCategoryImageBytes,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added! Batch size: ${_questionBatch.length}'),
      backgroundColor: Colors.green,
    ));
    _clearForm();
  }

  Future<String> _uploadImage(Uint8List bytes, String path) async {
    await supabase.storage.from('app-images').uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    return supabase.storage.from('app-images').getPublicUrl(path);
  }

  Future<void> _publishBatch() async {
    if (_questionBatch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch is empty. Add questions first.')));
      return;
    }
    setState(() => _isLoading = true);

    bool imageUploadFailed = false;
    final Map<String, String> categoryUrlCache = {};
    final List<Map<String, dynamic>> rowsToInsert = [];

    try {
      for (final item in _questionBatch) {
        final data = Map<String, dynamic>.from(item.data);
        final categoryName = data['category'] as String;

        if (item.categoryImageBytes != null &&
            !categoryUrlCache.containsKey(categoryName)) {
          try {
            final url = await _uploadImage(
              item.categoryImageBytes!,
              'categories/c_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            categoryUrlCache[categoryName] = url;
          } catch (_) {
            imageUploadFailed = true;
          }
        }
        if (categoryUrlCache.containsKey(categoryName)) {
          data['category_image_url'] = categoryUrlCache[categoryName]!;
        }

        if (item.questionImageBytes != null) {
          try {
            final url = await _uploadImage(
              item.questionImageBytes!,
              'quiz/q_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            data['image_url'] = url;
          } catch (_) {
            imageUploadFailed = true;
          }
        }

        rowsToInsert.add(data);
      }

      await supabase.from('quizzes').insert(rowsToInsert);

      if (mounted) {
        if (imageUploadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Questions published! But some images failed. Try again on Android.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ));
          Navigator.of(context).pop();
        } else {
          _showSuccessDialog(isUpdate: false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Publish failed: $e'),
                backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_correctAnswerIndex == null) return;
    setState(() => _isLoading = true);

    try {
      String questionImageUrl = _existingQuestionImageUrl;
      if (_isQuestionImagePicked && _pickedQuestionImageBytes != null) {
        questionImageUrl = await _uploadImage(
          _pickedQuestionImageBytes!,
          'quiz/q_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      await supabase.from('quizzes').update({
        'category': _categoryController.text.trim(),
        'question_text': _questionController.text.trim(),
        'image_url': questionImageUrl,
        'options': [
          _option1Controller.text.trim(),
          _option2Controller.text.trim(),
          _option3Controller.text.trim(),
          _option4Controller.text.trim(),
        ],
        'correct_answer_index': _correctAnswerIndex,
        'timer_seconds': int.tryParse(_timerController.text) ?? 30,
        'difficulty': _selectedDifficulty,
      }).eq('id', widget.questionToEdit!.id);

      if (mounted) _showSuccessDialog(isUpdate: true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Update failed: $e'),
                backgroundColor: Colors.red));
      }
    }
  }

  void _clearForm() {
    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _pickedQuestionImageBytes = null;
      _isQuestionImagePicked = false;
      _existingQuestionImageUrl = '';
      _correctAnswerIndex = null;
    });
  }

  void _showSuccessDialog({required bool isUpdate}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Success!'),
        content:
            Text(isUpdate ? 'Question updated.' : 'Published successfully.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _categoryController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Question' : 'Add New Question'),
        actions: [
          if (!_isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.blue.withAlpha(25),
                ),
                icon: const Icon(Icons.cloud_upload),
                label: Text('Publish (${_questionBatch.length})'),
                onPressed: _publishBatch,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _isCategoryImagePicked
                            ? Image.memory(_pickedCategoryImageBytes!,
                                fit: BoxFit.cover)
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickCategoryImage,
                      child: const Text("Logo", style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder()),
                      items: _difficultyOptions
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDifficulty = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _timerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Timer (Sec)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isQuestionImagePicked
                        ? Image.memory(_pickedQuestionImageBytes!,
                            fit: BoxFit.cover)
                        : _existingQuestionImageUrl.isNotEmpty
                            ? Image.network(_existingQuestionImageUrl,
                                fit: BoxFit.cover)
                            : const Center(
                                child:
                                    Text('Question Image (Optional)')),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickQuestionImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Select Question Image'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Question', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                const Text('Answers',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                _buildOptionField(0, _option1Controller, 'Option 1'),
                _buildOptionField(1, _option2Controller, 'Option 2'),
                _buildOptionField(2, _option3Controller, 'Option 3'),
                _buildOptionField(3, _option4Controller, 'Option 4'),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed:
                            _isEditMode ? _updateQuestion : _addQuestionToBatch,
                        child: Text(
                          _isEditMode ? 'Update' : 'Add to Batch',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionField(
      int index, TextEditingController controller, String label) {
    return Row(children: [
      Radio<int>(
        value: index,
        groupValue: _correctAnswerIndex,
        onChanged: (v) => setState(() => _correctAnswerIndex = v),
      ),
      Expanded(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
      ),
    ]);
  }
}
