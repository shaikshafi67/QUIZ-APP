import 'package:flutter/material.dart';
import 'quiz_page.dart';
import 'logo_background.dart';

class DifficultySelectionPage extends StatelessWidget {
  final String categoryName;

  const DifficultySelectionPage({super.key, required this.categoryName});

  void _startQuiz(BuildContext context, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          categoryName: categoryName,
          difficulty: difficulty, // Passing difficulty
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$categoryName Difficulty')),
      body: LogoBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Mode',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              
              _buildDifficultyCard(context, 'Easy', Colors.green, Icons.sentiment_satisfied_alt),
              const SizedBox(height: 20),
              _buildDifficultyCard(context, 'Medium', Colors.orange, Icons.sentiment_neutral),
              const SizedBox(height: 20),
              _buildDifficultyCard(context, 'Hard', Colors.red, Icons.sentiment_very_dissatisfied),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(BuildContext context, String level, Color color, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: () => _startQuiz(context, level),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        icon: Icon(icon, size: 32),
        label: Text(
          level,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}