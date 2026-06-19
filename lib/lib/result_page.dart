import 'package:flutter/material.dart';
import '../leaderboard_page.dart';
import '../user_main_layout.dart';
import '../main.dart';

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
    Future.microtask(() => _saveScore());
  }

  Future<void> _saveScore() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String userName = user.email?.split('@')[0] ?? 'Unknown';

      try {
        final userDoc = await supabase
            .from('users')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (userDoc != null) {
          userName = userDoc['full_name'] ?? userName;
        }
      } catch (e) {
        debugPrint("Error fetching name: $e");
      }

      await supabase.from('scores').insert({
        'user_id': user.id,
        'email': user.email,
        'full_name': userName,
        'score': widget.score,
        'total_questions': widget.totalQuestions,
        'category': widget.categoryName,
      });
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserMainLayout()),
      (route) => false,
    );
  }

  void _goToLeaderboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaderboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = widget.totalQuestions > 0
        ? (widget.score / widget.totalQuestions) * 100
        : 0.0;

    final String resultMessage =
        percentage >= 70 ? 'Great Job!' : 'Good Try!';
    final Color resultColor =
        percentage >= 70 ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Results"),
          automaticallyImplyLeading: false),
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Score',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  '${widget.score} / ${widget.totalQuestions}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "${percentage.toInt()}%",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: resultColor),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => _goToLeaderboard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('View Leaderboard',
                      style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _goToHome(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
