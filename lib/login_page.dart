import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_page.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';
import 'lib/admin_signup_page.dart';
import 'app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isAdminMode = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      if (mounted) {
        if (doc.exists && doc['role'] == 'admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const UserMainLayout()));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'Login failed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
      _emailController.clear();
      _passwordController.clear();
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isAdminMode ? AppColors.pink : AppColors.purple;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withAlpha(35),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withAlpha(25),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const DarkModeToggle(),
                          GestureDetector(
                            onTap: _toggleAdminMode,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              borderRadius: BorderRadius.circular(30),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAdminMode
                                        ? Icons.person
                                        : Icons.admin_panel_settings,
                                    color: accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isAdminMode ? 'User' : 'Admin',
                                    style: TextStyle(
                                        color: accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Logo
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _isAdminMode
                                        ? [AppColors.pink, AppColors.orange]
                                        : AppColors.primaryGradient,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withAlpha(100),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Image.asset('assets/images/logo.png'),
                              ),
                              const SizedBox(height: 24),

                              // Title
                              ShaderMask(
                                shaderCallback: (b) => LinearGradient(
                                  colors: _isAdminMode
                                      ? [AppColors.pink, AppColors.orange]
                                      : [AppColors.purple, AppColors.cyan],
                                ).createShader(b),
                                child: Text(
                                  _isAdminMode ? 'Admin Portal' : 'Welcome Back',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isAdminMode
                                    ? 'Enter your admin credentials'
                                    : 'Login to continue your journey',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(130),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Form card
                              GlassCard(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    GlassTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      accentColor: accent,
                                      validator: (v) =>
                                          (v == null || !v.contains('@'))
                                              ? 'Enter a valid email'
                                              : null,
                                    ),
                                    const SizedBox(height: 16),
                                    GlassTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      icon: Icons.lock_outline,
                                      isPassword: true,
                                      isPasswordVisible: _isPasswordVisible,
                                      accentColor: accent,
                                      onTogglePassword: () => setState(() =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible),
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                              ? 'Min 6 characters'
                                              : null,
                                    ),
                                    const SizedBox(height: 28),
                                    GradientButton(
                                      label: _isAdminMode
                                          ? 'Access Dashboard'
                                          : 'Login',
                                      onPressed: _login,
                                      isLoading: _isLoading,
                                      colors: _isAdminMode
                                          ? [AppColors.pink, AppColors.orange]
                                          : AppColors.primaryGradient,
                                      icon: _isAdminMode
                                          ? Icons.admin_panel_settings
                                          : Icons.login,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Bottom link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isAdminMode
                                        ? 'New Admin? '
                                        : "Don't have an account? ",
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(130),
                                        fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => _isAdminMode
                                            ? const AdminSignUpPage()
                                            : const SignUpPage(),
                                      ),
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (b) => LinearGradient(
                                        colors: _isAdminMode
                                            ? [AppColors.pink, AppColors.orange]
                                            : [AppColors.purple, AppColors.cyan],
                                      ).createShader(b),
                                      child: Text(
                                        _isAdminMode
                                            ? 'Register Here'
                                            : 'Sign Up',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
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
    );
  }
}
