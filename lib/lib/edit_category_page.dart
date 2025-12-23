import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_page.dart'; // To use the QuizQuestion model

// Local placeholder editor page so this file compiles even if an external
// question_editor_page.dart is not present or has a different class name.
class QuestionEditorPage extends StatelessWidget {
  final QuizQuestion questionToEdit;

  const QuestionEditorPage({super.key, required this.questionToEdit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Question')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question:', style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 8),
            Text(questionToEdit.questionText),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on TextTheme {
  TextStyle? get subtitle1 => null;
}

class EditCategoryPage extends StatelessWidget {
  final String categoryName;
  
  const EditCategoryPage({super.key, required this.categoryName});

  // Navigate to the editor with the question data pre-filled
  void _editQuestion(BuildContext context, QuizQuestion question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditorPage(questionToEdit: question),
      ),
    );
  }

  // Delete a question from Firebase
  Future<void> _deleteQuestion(BuildContext context, String questionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(questionId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting question: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit: $categoryName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch questions only for this specific category
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No questions found in this category.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // 4. List of Questions
          final questions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: questions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              // Convert Firebase document to our Model
              final question = QuizQuestion.fromFirestore(questions[index]);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    question.questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Show useful info like Difficulty and Timer
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        // Difficulty Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            question.difficulty,
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Timer Icon
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${question.timerSeconds}s',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Question',
                        onPressed: () => _editQuestion(context, question),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Question',
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