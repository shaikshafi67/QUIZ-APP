import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'question_editor_page.dart'; 
import 'quiz_page.dart'; 

class EditCategoryPage extends StatelessWidget {
  final String categoryName;
  const EditCategoryPage({super.key, required this.categoryName});

  void _editQuestion(BuildContext context, QuizQuestion question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditorPage(questionToEdit: question),
      ),
    );
  }

  Future<void> _deleteQuestion(BuildContext context, String questionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(questionId)
          .delete();

      // We removed the 'context.mounted' check to prevent errors on older Flutter versions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted successfully')),
      );
    } catch (e) {
      print('Error deleting question: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: $categoryName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No questions found.'));
          }

          final questions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: questions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final question = QuizQuestion.fromFirestore(questions[index]);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(question.questionText, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Answer: ${question.options[question.correctAnswerIndex]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editQuestion(context, question),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuestion(context, question.id),
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