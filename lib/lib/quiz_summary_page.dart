import 'package:flutter/material.dart';
import 'quiz_page.dart';

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
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusItem("Answered", answeredCount, Colors.green),
                _statusItem("Pending", pendingCount, Colors.orange),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final bool isAnswered = selectedAnswers.containsKey(index);
                return GestureDetector(
                  onTap: () { onJumpToQuestion(index); Navigator.pop(context); },
                  child: Container(
                    decoration: BoxDecoration(color: isAnswered ? Colors.green : Colors.grey.shade300, shape: BoxShape.circle),
                    child: Center(child: Text("${index + 1}", style: TextStyle(color: isAnswered ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); onSubmit(); }, child: const Text("Submit Quiz"))),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, int count, Color color) {
    return Column(children: [
      Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ]);
  }
}