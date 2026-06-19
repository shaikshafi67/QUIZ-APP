import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';
import 'app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeIn));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    _handleNavigation();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          if (doc.exists && doc.get('role') == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const UserMainLayout()));
          }
        }
      } catch (_) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: _decorCircle(200, AppColors.purple.withAlpha(40)),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _decorCircle(250, AppColors.violet.withAlpha(30)),
            ),
            Positioned(
              top: 200,
              left: -40,
              child: _decorCircle(120, AppColors.cyan.withAlpha(20)),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withAlpha(120),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Animated text
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.purple, AppColors.cyan],
                            ).createShader(bounds),
                            child: const Text(
                              'QUIZ APP',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Test Your Knowledge',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(150),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  FadeTransition(
                    opacity: _textOpacity,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.purple.withAlpha(180)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
