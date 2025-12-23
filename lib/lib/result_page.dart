import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leaderboard_page.dart';
import '../user_main_layout.dart';
import 'leaderboard_page.dart' hide LeaderboardPage;
import 'user_main_layout.dart'; 

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryName;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryName,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    // We wrap the save function in a microtask to ensure it doesn't block the UI build
    Future.microtask(() => _saveScore());
  }

  Future<void> _saveScore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String userName = user.email?.split('@')[0] ?? 'Unknown';
      
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['fullName'] ?? userName;
        }
      } catch (e) {
        print("Error fetching name: $e");
      }

      await FirebaseFirestore.instance.collection('scores').add({
        'userId': user.uid,
        'email': user.email,
        'fullName': userName,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'category': widget.categoryName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Score saved!");
    } catch (e) {
      print('Error saving score: $e');
    }
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UserMainLayout()),
      (route) => false,
    );
  }

  void _goToLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentage safely
    double percentage = 0.0;
    if (widget.totalQuestions > 0) {
      percentage = (widget.score / widget.totalQuestions) * 100;
    }
    
    final String resultMessage = percentage >= 70 ? 'Great Job!' : 'Good Try!';
    final Color resultColor = percentage >= 70 ? Colors.green : Colors.orange;

    // Use Safe Area and Scaffold to ensure a valid widget is always returned
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"), 
        automaticallyImplyLeading: false
      ),
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure width is valid
              children: [
                Icon(
                  percentage >= 70 ? Icons.emoji_events : Icons.replay,
                  color: resultColor,
                  size: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  resultMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Score',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  '${widget.score} / ${widget.totalQuestions}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "${percentage.toInt()}%",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: resultColor),
                ),
                const SizedBox(height: 48),
                
                ElevatedButton(
                  onPressed: () => _goToLeaderboard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('View Leaderboard', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                
                OutlinedButton(
                  onPressed: () => _goToHome(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}