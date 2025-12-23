import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_page.dart'; 

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
  String _lastUploadedQuestionImageUrl = ''; 

  Uint8List? _pickedCategoryImageBytes; 
  bool _isCategoryImagePicked = false;
  String _existingCategoryImageUrl = ''; 
  String _lastUploadedCategoryImageUrl = ''; 

  final List<Map<String, dynamic>> _questionBatch = [];
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
      
      if (q.imageUrl.isNotEmpty) {
        _existingQuestionImageUrl = q.imageUrl;
      }
    }
  }

  // --- FAST UPLOAD FIX: Question Image ---
  Future<void> _pickQuestionImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // <-- COMPRESS QUALITY
      maxWidth: 600,    // <-- RESIZE IMAGE
    );
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _pickedQuestionImageBytes = imageBytes;
        _isQuestionImagePicked = true;
        _existingQuestionImageUrl = ''; 
      });
    }
  }

  // --- FAST UPLOAD FIX: Category Logo ---
  Future<void> _pickCategoryImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // <-- COMPRESS QUALITY
      maxWidth: 400,    // <-- SMALLER RESIZE FOR LOGO
    );
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _pickedCategoryImageBytes = imageBytes;
        _isCategoryImagePicked = true;
        _existingCategoryImageUrl = ''; 
      });
    }
  }

  Future<void> _addQuestionToBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select correct answer')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      String questionImageUrl = '';
      String categoryImageUrl = '';

      if (_isQuestionImagePicked && _pickedQuestionImageBytes != null) {
        final String imageName = 'quiz_images/q_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(imageName);
        final UploadTask uploadTask = storageRef.putData(_pickedQuestionImageBytes!);
        final TaskSnapshot taskSnapshot = await uploadTask;
        questionImageUrl = await taskSnapshot.ref.getDownloadURL();
        _lastUploadedQuestionImageUrl = questionImageUrl; 
      } else {
        questionImageUrl = _lastUploadedQuestionImageUrl; 
      }

      if (_isCategoryImagePicked && _pickedCategoryImageBytes != null) {
        final String imageName = 'category_images/c_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(imageName);
        final UploadTask uploadTask = storageRef.putData(_pickedCategoryImageBytes!);
        final TaskSnapshot taskSnapshot = await uploadTask;
        categoryImageUrl = await taskSnapshot.ref.getDownloadURL();
        _lastUploadedCategoryImageUrl = categoryImageUrl; 
      } else {
        categoryImageUrl = _lastUploadedCategoryImageUrl; 
      }
      
      final Map<String, dynamic> questionData = {
        'category': _categoryController.text.trim(),
        'categoryImageUrl': categoryImageUrl,
        'questionText': _questionController.text.trim(),
        'imageUrl': questionImageUrl,
        'options': [
          _option1Controller.text.trim(),
          _option2Controller.text.trim(),
          _option3Controller.text.trim(),
          _option4Controller.text.trim(),
        ],
        'correctAnswerIndex': _correctAnswerIndex,
        'timerSeconds': int.tryParse(_timerController.text) ?? 30,
        'difficulty': _selectedDifficulty,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      _questionBatch.add(questionData);
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added! Batch size: ${_questionBatch.length}'), backgroundColor: Colors.green));
      _clearForm(); 
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _updateQuestion() async {
     if (!_formKey.currentState!.validate()) return;
    if (_correctAnswerIndex == null) return;
    setState(() { _isLoading = true; });

    try {
      String questionImageUrl = _existingQuestionImageUrl;
      if (_isQuestionImagePicked && _pickedQuestionImageBytes != null) {
        final String imageName = 'quiz_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(imageName);
        final UploadTask uploadTask = storageRef.putData(_pickedQuestionImageBytes!);
        final TaskSnapshot taskSnapshot = await uploadTask;
        questionImageUrl = await taskSnapshot.ref.getDownloadURL();
      }

      final Map<String, dynamic> questionData = {
        'category': _categoryController.text.trim(),
        'questionText': _questionController.text.trim(),
        'imageUrl': questionImageUrl,
        'options': [
          _option1Controller.text.trim(),
          _option2Controller.text.trim(),
          _option3Controller.text.trim(),
          _option4Controller.text.trim(),
        ],
        'correctAnswerIndex': _correctAnswerIndex,
        'timerSeconds': int.tryParse(_timerController.text) ?? 30,
        'difficulty': _selectedDifficulty, 
        'createdAt': widget.questionToEdit!.createdAt, 
      };

      await FirebaseFirestore.instance.collection('quizzes').doc(widget.questionToEdit!.id).update(questionData);
      if (mounted) _showSuccessDialog(isUpdate: true);
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _publishBatch() async {
    if (_questionBatch.isEmpty) return;
    setState(() { _isLoading = true; });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('quizzes');
      for (final data in _questionBatch) {
        final docRef = collection.doc();
        batch.set(docRef, data);
      }
      await batch.commit();
      if (mounted) _showSuccessDialog(isUpdate: false);
    } catch (e) {
      setState(() { _isLoading = false; });
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
        content: Text(isUpdate ? 'Question updated.' : 'Published successfully.'),
        actions: [
          TextButton(child: const Text('OK'), onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose(); _option1Controller.dispose(); _option2Controller.dispose(); _option3Controller.dispose(); _option4Controller.dispose(); _categoryController.dispose(); _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Question' : 'Add New Question'), actions: [
        if (!_isEditMode)
           Padding(padding: const EdgeInsets.only(right: 8.0), child: TextButton.icon(style: TextButton.styleFrom(foregroundColor: Colors.blue, backgroundColor: Colors.blue.withOpacity(0.1)), icon: const Icon(Icons.cloud_upload), label: Text('Publish (${_questionBatch.length})'), onPressed: _publishBatch)),
      ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                    Expanded(child: TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 10),
                    Column(children: [
                       Container(width: 50, height: 50, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _isCategoryImagePicked ? Image.memory(_pickedCategoryImageBytes!, fit: BoxFit.cover) : (_lastUploadedCategoryImageUrl.isNotEmpty ? Image.network(_lastUploadedCategoryImageUrl, fit: BoxFit.cover) : const Icon(Icons.image, color: Colors.grey)))),
                       TextButton(onPressed: _pickCategoryImage, child: const Text("Logo", style: TextStyle(fontSize: 12)))
                    ]),
                ]),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                        items: _difficultyOptions.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedDifficulty = newValue!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _timerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Timer (Sec)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.timer)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(height: 150, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: () { if (_isQuestionImagePicked) return Image.memory(_pickedQuestionImageBytes!, fit: BoxFit.cover); if (_existingQuestionImageUrl.isNotEmpty) return Image.network(_existingQuestionImageUrl, fit: BoxFit.cover); return const Center(child: Text('Question Image (Optional)')); }())),
                TextButton.icon(onPressed: _pickQuestionImage, icon: const Icon(Icons.add_photo_alternate), label: const Text('Select Question Image')),
                const SizedBox(height: 10),
                
                TextFormField(controller: _questionController, maxLines: 2, decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 20),
                
                const Text('Answers', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildOptionField(0, _option1Controller, 'Option 1'),
                _buildOptionField(1, _option2Controller, 'Option 2'),
                _buildOptionField(2, _option3Controller, 'Option 3'),
                _buildOptionField(3, _option4Controller, 'Option 4'),
                const SizedBox(height: 32),
                
                _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _isEditMode ? _updateQuestion : _addQuestionToBatch, child: Text(_isEditMode ? 'Update' : 'Add to Batch', style: const TextStyle(fontSize: 18))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionField(int index, TextEditingController controller, String label) {
    return Row(children: [Radio<int>(value: index, groupValue: _correctAnswerIndex, onChanged: (int? value) { setState(() { _correctAnswerIndex = value; }); }), Expanded(child: TextFormField(controller: controller, decoration: InputDecoration(labelText: label)) )]);
  }
}