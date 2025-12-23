import 'package:flutter/material.dart';
import 'quiz_page.dart'; // To access QuizQuestion model

class QuizSummaryPage extends StatelessWidget {
  final List<QuizQuestion> questions;
  final Map<int, int> selectedAnswers;
  final Function() onSubmit;
  final Function(int) onJumpToQuestion;

  const QuizSummaryPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.onSubmit,
    required this.onJumpToQuestion,
  });

  @override
  Widget build(BuildContext context) {
    int answeredCount = selectedAnswers.length;
    int pendingCount = questions.length - answeredCount;

    return Scaffold(
      appBar: AppBar(title: const Text("Review Quiz")),
      body: Column(
        children: [
          // --- STATUS COUNTS ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  Text("$answeredCount", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text("Answered", style: TextStyle(color: Colors.green))
                ]),
                Column(children: [
                  Text("$pendingCount", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const Text("Pending", style: TextStyle(color: Colors.orange))
                ]),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- QUESTION GRID ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, 
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final bool isAnswered = selectedAnswers.containsKey(index);
                return GestureDetector(
                  onTap: () {
                    // Jump back to this question
                    onJumpToQuestion(index);
                    Navigator.pop(context); 
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAnswered ? Colors.green : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isAnswered ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- SUBMIT BUTTON ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close summary
                  onSubmit(); // Finish the quiz
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Submit Quiz", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}