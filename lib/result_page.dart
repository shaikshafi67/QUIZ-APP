import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_page.dart';
import 'user_main_layout.dart';
import 'app_theme.dart';

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

class _ResultPageState extends State<ResultPage> with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _contentController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _scalePop;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_saveScore);

    _scoreController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _scoreAnimation =
        Tween<double>(begin: 0, end: widget.score.toDouble()).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _displayedScore = _scoreAnimation.value.round());
      });

    _scalePop = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut));

    _contentFade =
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _contentController, curve: Curves.easeOut));

    _scoreController.forward();
    Future.delayed(const Duration(milliseconds: 500),
        () => _contentController.forward());
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveScore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String userName = user.email?.split('@')[0] ?? 'Unknown';
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) userName = doc.data()?['fullName'] ?? userName;
      } catch (_) {}

      await FirebaseFirestore.instance.collection('scores').add({
        'userId': user.uid,
        'email': user.email,
        'fullName': userName,
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'category': widget.categoryName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  String _getEmoji(double pct) {
    if (pct >= 90) return '🏆';
    if (pct >= 70) return '🎉';
    if (pct >= 50) return '👍';
    return '💪';
  }

  String _getMessage(double pct) {
    if (pct >= 90) return 'Outstanding!';
    if (pct >= 70) return 'Great Job!';
    if (pct >= 50) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  List<Color> _getGradient(double pct) {
    if (pct >= 70) return AppColors.primaryGradient;
    if (pct >= 50) return [AppColors.orange, AppColors.pink];
    return [AppColors.pink, AppColors.violet];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = widget.totalQuestions > 0
        ? (widget.score / widget.totalQuestions) * 100
        : 0.0;
    final gradient = _getGradient(pct);

    return Scaffold(
      body: PopScope(
        canPop: false,
        child: GradientBackground(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradient.first.withAlpha(30),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gradient.last.withAlpha(20),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Score circle
                      ScaleTransition(
                        scale: _scalePop,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.first.withAlpha(100),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getEmoji(pct),
                                style: const TextStyle(fontSize: 36),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_displayedScore',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'of ${widget.totalQuestions}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Message
                      FadeTransition(
                        opacity: _contentFade,
                        child: SlideTransition(
                          position: _contentSlide,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => LinearGradient(
                                  colors: gradient,
                                ).createShader(b),
                                child: Text(
                                  _getMessage(pct),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.categoryName,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Stats row
                              Row(
                                children: [
                                  Expanded(
                                    child: _statCard(
                                      label: 'Score',
                                      value:
                                          '${widget.score}/${widget.totalQuestions}',
                                      icon: '🎯',
                                      colors: gradient,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _statCard(
                                      label: 'Accuracy',
                                      value: '${pct.toInt()}%',
                                      icon: '📊',
                                      colors: pct >= 70
                                          ? [AppColors.cyan, AppColors.purple]
                                          : [AppColors.orange, AppColors.pink],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _statCard(
                                      label: 'Wrong',
                                      value:
                                          '${widget.totalQuestions - widget.score}',
                                      icon: '❌',
                                      colors: [AppColors.pink, AppColors.violet],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Progress bar
                              GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Your Progress',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '${pct.toInt()}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: gradient.first,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        backgroundColor:
                                            Colors.white.withAlpha(20),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                gradient.first),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Buttons
                              GradientButton(
                                label: 'View Leaderboard',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const LeaderboardPage()),
                                ),
                                icon: Icons.leaderboard_rounded,
                                colors: gradient,
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const UserMainLayout()),
                                  (_) => false,
                                ),
                                child: GlassCard(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.home_rounded,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Back to Home',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String icon,
    required List<Color> colors,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (b) =>
                LinearGradient(colors: colors).createShader(b),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
