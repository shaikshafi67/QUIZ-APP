import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_page.dart';
import 'user_main_layout.dart';

class ResultPage extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryName;

  const ResultPage({super.key, required this.score, required this.totalQuestions, required this.categoryName});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _saveScore());
  }

  Future<void> _saveScore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String userName = user.email?.split('@')[0] ?? 'Unknown';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) userName = userDoc.data()?['fullName'] ?? userName;
      } catch (_) {}

      await FirebaseFirestore.instance.collection('scores').add({
        'userId': user.uid, 'email': user.email, 'fullName': userName,
        'score': widget.score, 'totalQuestions': widget.totalQuestions,
        'category': widget.categoryName, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) { print(e); }
  }

  @override
  Widget build(BuildContext context) {
    double percentage = widget.totalQuestions > 0 ? (widget.score / widget.totalQuestions) * 100 : 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Results"), automaticallyImplyLeading: false),
      body: PopScope(
        canPop: false,
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Quiz Completed!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Score: ${widget.score} / ${widget.totalQuestions}", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text("${percentage.toInt()}%", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: percentage >= 70 ? Colors.green : Colors.orange)),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardPage())), child: const Text("View Leaderboard")),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserMainLayout()), (route) => false), child: const Text("Back to Home")),
          ]),
        ),
      ),
    );
  }
}