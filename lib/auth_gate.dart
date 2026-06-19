import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'main.dart';
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';

/// Wraps the entire app. Listens to Supabase auth state changes and
/// automatically redirects to Login when the session expires or the
/// user signs out from any page / browser tab.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {

        // ── Still waiting for first auth event ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final event   = snapshot.data?.event;
        final session = snapshot.data?.session;

        // ── No session or explicitly signed out ──
        if (session == null || event == AuthChangeEvent.signedOut) {
          return const LoginPage();
        }

        // ── Active session ─ route by role ──
        return const _RoleRouter();
      },
    );
  }
}

/// Fetches the user's role from the `users` table and routes to the
/// correct home page. Shows a splash while the role is loading.
class _RoleRouter extends StatefulWidget {
  const _RoleRouter();

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  String? _role;
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() { _role = 'user'; _loading = false; });
      return;
    }
    try {
      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _role    = (data?['role'] as String?) ?? 'user';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _role = 'user'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _Splash();
    return _role == 'admin'
        ? const AdminDashboardPage()
        : const UserMainLayout();
  }
}

/// Minimal animated splash shown while auth / role is loading.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.5),
                          blurRadius: 28, spreadRadius: 4),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Image.asset('assets/images/logo.png',
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.quiz_rounded,
                              color: Colors.white, size: 36)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.purple.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
