import 'package:flutter/material.dart';
import '../main.dart';
import '../quiz_page.dart';
import 'question_editor_page.dart';

class EditCategoryPage extends StatelessWidget {
  final String categoryName;

  const EditCategoryPage({super.key, required this.categoryName});

  void _editQuestion(BuildContext context, QuizQuestion question) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => QuestionEditorPage(questionToEdit: question)),
    );
  }

  Future<void> _deleteQuestion(
      BuildContext context, String questionId) async {
    try {
      await supabase.from('quizzes').delete().eq('id', questionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit: $categoryName')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('quizzes')
            .stream(primaryKey: ['id'])
            .eq('category', categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No questions found in this category.',
                    style: TextStyle(color: Colors.grey, fontSize: 16)));
          }

          final questions =
              snapshot.data!.map((d) => QuizQuestion.fromMap(d)).toList();

          return ListView.builder(
            itemCount: questions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(question.questionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border:
                                Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(question.difficulty,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${question.timerSeconds}s',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Question',
                        onPressed: () => _editQuestion(context, question),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Question',
                        onPressed: () =>
                            _deleteQuestion(context, question.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
