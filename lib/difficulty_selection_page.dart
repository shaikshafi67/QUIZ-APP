import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'quiz_page.dart';

class DifficultySelectionPage extends StatefulWidget {
  final String categoryName;
  const DifficultySelectionPage({super.key, required this.categoryName});

  @override
  State<DifficultySelectionPage> createState() =>
      _DifficultySelectionPageState();
}

class _DifficultySelectionPageState extends State<DifficultySelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  final _levels = const [
    _Level(
      label:    'Easy',
      emoji:    '😊',
      desc:     'Perfect for beginners',
      detail:   'Basic concepts & simple questions',
      colors:   [Color(0xFF11998E), Color(0xFF38EF7D)],
      shadow:   Color(0xFF11998E),
    ),
    _Level(
      label:    'Medium',
      emoji:    '🤔',
      desc:     'Test your knowledge',
      detail:   'Mixed topics & moderate difficulty',
      colors:   [Color(0xFFF7971E), Color(0xFFFFD200)],
      shadow:   Color(0xFFF7971E),
    ),
    _Level(
      label:    'Hard',
      emoji:    '🔥',
      desc:     'Expert challenge',
      detail:   'Advanced questions & tricky concepts',
      colors:   [Color(0xFFFC5C7D), Color(0xFF6A3093)],
      shadow:   Color(0xFFFC5C7D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _start(String difficulty) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => QuizPage(
          categoryName: widget.categoryName,
          difficulty:   difficulty,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: GradientBackground(
        child: Stack(children: [
          // Decorative blobs
          Positioned(top: -60, right: -60,
              child: _Blob(200, AppColors.purple.withValues(alpha: 0.12))),
          Positioned(bottom: -80, left: -60,
              child: _Blob(220, AppColors.cyan.withValues(alpha: 0.08))),

          SafeArea(
            child: Column(children: [
              // ── AppBar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: FadeTransition(
                  opacity: _ctrl,
                  child: Column(children: [
                    // Category pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: AppColors.primaryGradient),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(widget.categoryName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Choose Difficulty',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 8),
                    Text('Pick a level that matches your skill',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 13)),
                  ]),
                ),
              ),

              // ── Difficulty cards ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_levels.length, (i) {
                      final level = _levels[i];
                      final delay  = i * 0.15;
                      final anim   = CurvedAnimation(
                        parent: _ctrl,
                        curve: Interval(delay, delay + 0.6,
                            curve: Curves.easeOutBack),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ScaleTransition(
                          scale: anim,
                          child: FadeTransition(
                            opacity: anim,
                            child: _LevelCard(
                              level: level,
                              onTap: () => _start(level.label),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Level data ────────────────────────────────────────────────────────────────

class _Level {
  final String label, emoji, desc, detail;
  final List<Color> colors;
  final Color shadow;
  const _Level({
    required this.label, required this.emoji,
    required this.desc,  required this.detail,
    required this.colors, required this.shadow,
  });
}

// ── Level card ────────────────────────────────────────────────────────────────

class _LevelCard extends StatefulWidget {
  final _Level level;
  final VoidCallback onTap;
  const _LevelCard({required this.level, required this.onTap});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l = widget.level;
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: l.shadow.withValues(alpha: 0.25),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
                child: Row(children: [
                  // Gradient icon box
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: l.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: l.shadow.withValues(alpha: 0.40),
                            blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(l.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Text
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(l.desc,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(l.detail,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 11)),
                    ]),
                  ),

                  // Arrow
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: l.colors),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
