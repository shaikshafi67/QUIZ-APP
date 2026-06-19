import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';
import 'otp_verification_page.dart';

// ─── Colour palette ──────────────────────────────────────────────────────────
const _kBlue1 = Color(0xFF4776E6);
const _kBlue2 = Color(0xFF8E54E9);
const _kRed1  = Color(0xFFc0392b);
const _kRed2  = Color(0xFFe74c3c);
const _kGold1 = Color(0xFFf7971e);
const _kGold2 = Color(0xFFffd200);
const _kBg    = Color(0xFFF0F4FF);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  // ── State ──
  bool _showSignup  = false;
  bool _isAdmin     = false;
  bool _isLoading   = false;
  bool _obscureL    = true;
  bool _obscureS    = true;

  // ── Controllers ──
  final _lEmail  = TextEditingController();
  final _lPass   = TextEditingController();
  final _lKey    = GlobalKey<FormState>();

  final _sName   = TextEditingController();
  final _sEmail  = TextEditingController();
  final _sPass   = TextEditingController();
  final _sMaster = TextEditingController();
  final _sKey    = GlobalKey<FormState>();
  // ── Animations ──
  late AnimationController _bgCtrl;   // floating blobs
  late AnimationController _tabCtrl;  // tab slide
  late Animation<double>   _tabAnim;

  Color get c1 => _isAdmin ? _kRed1 : _kBlue1;
  Color get c2 => _isAdmin ? _kRed2 : _kBlue2;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);

    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _tabAnim =
        CurvedAnimation(parent: _tabCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _tabCtrl.dispose();
    for (final c in [_lEmail, _lPass, _sName, _sEmail, _sPass, _sMaster]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toSignup() {
    setState(() => _showSignup = true);
    _tabCtrl.forward();
  }

  void _toLogin() {
    setState(() => _showSignup = false);
    _tabCtrl.reverse();
  }

  void _toggleAdmin() {
    setState(() {
      _isAdmin = !_isAdmin;
      _showSignup = false;
      for (final c in [_lEmail, _lPass, _sName, _sEmail, _sPass, _sMaster]) {
        c.clear();
      }
    });
    _tabCtrl.reset();
  }

  // ── Auth ──
  Future<void> _login() async {
    if (!_lKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
          email: _lEmail.text.trim(), password: _lPass.text.trim());
      final uid = res.user?.id;
      if (uid == null) throw Exception('Login failed');

      final row = await supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (!mounted) return;

      final role = row?['role'] ?? 'user';
      if (_isAdmin && role != 'admin') {
        await supabase.auth.signOut();
        _snack('Access Denied: Not an admin account', error: true);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'admin'
              ? const AdminDashboardPage()
              : const UserMainLayout(),
        ),
      );
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (!_sKey.currentState!.validate()) return;
    if (_isAdmin && _sMaster.text.trim() != '12345') {
      _snack('Incorrect Master Key', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth
          .signUp(email: _sEmail.text.trim(), password: _sPass.text.trim());
      final uid = res.user?.id;
      if (uid == null) throw Exception('Signup failed');

      if (!mounted) return;
      // Navigate to OTP page; image upload + DB insert happen after verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationPage(
            email:    _sEmail.text.trim(),
            fullName: _sName.text.trim(),
            role:     _isAdmin ? 'admin' : 'user',
            userId:   uid,
            picBytes: null,
          ),
        ),
      );
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final isWide = size.width > 750;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // Animated background blobs
        _AnimatedBlobs(ctrl: _bgCtrl, c1: c1, c2: c2),

        // Admin toggle
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _AdminChip(isAdmin: _isAdmin, onTap: _toggleAdmin, c1: c1),
            ),
          ),
        ),

        // Main card
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 80),
            child: isWide
                ? _WideLayout(
                    c1: c1, c2: c2,
                    tabAnim: _tabAnim,
                    showSignup: _showSignup,
                    isAdmin: _isAdmin,
                    onToSignup: _toSignup,
                    onToLogin: _toLogin,
                    loginForm: _buildLoginForm(),
                    signupForm: _buildSignupForm(),
                  )
                : _NarrowLayout(
                    c1: c1, c2: c2,
                    tabAnim: _tabAnim,
                    showSignup: _showSignup,
                    isAdmin: _isAdmin,
                    onToSignup: _toSignup,
                    onToLogin: _toLogin,
                    loginForm: _buildLoginForm(),
                    signupForm: _buildSignupForm(),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _lKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthField(
            ctrl: _lEmail,
            hint: 'Email address',
            icon: Icons.email_outlined,
            type: TextInputType.emailAddress,
            c1: c1,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 14),
          _AuthField(
            ctrl: _lPass,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureL,
            c1: c1,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureL = !_obscureL),
              child: Icon(_obscureL ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: Colors.grey),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text('Forgot Password?',
                  style: TextStyle(fontSize: 12, color: c1)),
            ),
          ),
          const SizedBox(height: 8),
          _GradBtn(
              label: _isAdmin ? 'ACCESS DASHBOARD' : 'SIGN IN',
              onPressed: _login,
              isLoading: _isLoading,
              c1: _kGold1, c2: _kGold2),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _sKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthField(
            ctrl: _sName,
            hint: 'Full Name',
            icon: Icons.person_outline,
            c1: c1,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Enter your name' : null,
          ),
          const SizedBox(height: 12),
          _AuthField(
            ctrl: _sEmail,
            hint: 'Email address',
            icon: Icons.email_outlined,
            type: TextInputType.emailAddress,
            c1: c1,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 12),
          _AuthField(
            ctrl: _sPass,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureS,
            c1: c1,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureS = !_obscureS),
              child: Icon(_obscureS ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20, color: Colors.grey),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            _AuthField(
              ctrl: _sMaster,
              hint: 'Master Key',
              icon: Icons.vpn_key_outlined,
              obscure: true,
              c1: c1,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter master key' : null,
            ),
          ],
          const SizedBox(height: 20),
          _GradBtn(
              label: _isAdmin ? 'REGISTER ADMIN' : 'CREATE ACCOUNT',
              onPressed: _signup,
              isLoading: _isLoading,
              c1: c1, c2: c2),
        ],
      ),
    );
  }
}

// ─── Animated background blobs ────────────────────────────────────────────────

class _AnimatedBlobs extends StatelessWidget {
  final AnimationController ctrl;
  final Color c1, c2;
  const _AnimatedBlobs({required this.ctrl, required this.c1, required this.c2});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return Stack(children: [
          Positioned(
            top: -60 + 40 * sin(t * pi),
            right: -60 + 30 * cos(t * pi),
            child: _Blob(size: 260, color: c1.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -40 + 30 * cos(t * pi),
            left: -40 + 40 * sin(t * pi + 1),
            child: _Blob(size: 220, color: c2.withValues(alpha: 0.14)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4 + 50 * sin(t * pi + 2),
            right: 60 + 30 * cos(t * pi + 1),
            child: _Blob(size: 120, color: _kGold1.withValues(alpha: 0.10)),
          ),
        ]);
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── Wide layout (split panel) ────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final Color c1, c2;
  final Animation<double> tabAnim;
  final bool showSignup, isAdmin;
  final VoidCallback onToSignup, onToLogin;
  final Widget loginForm, signupForm;

  const _WideLayout({
    required this.c1, required this.c2,
    required this.tabAnim, required this.showSignup, required this.isAdmin,
    required this.onToSignup, required this.onToLogin,
    required this.loginForm, required this.signupForm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: c1.withValues(alpha: 0.18),
              blurRadius: 50, offset: const Offset(0, 16)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(builder: (ctx, box) {
          final half = box.maxWidth / 2;
          return AnimatedBuilder(
            animation: tabAnim,
            builder: (_, __) {
              final panelX = half * (1 - tabAnim.value);
              return Stack(children: [
                // ── Left white zone ──
                Positioned(
                  left: 0, top: 0, width: half, height: box.maxHeight,
                  child: _FormZone(
                    child: showSignup
                        ? const SizedBox.shrink()
                        : loginForm,
                  ),
                ),
                // ── Right white zone ──
                Positioned(
                  left: half, top: 0, width: half, height: box.maxHeight,
                  child: _FormZone(
                    child: showSignup ? signupForm : const SizedBox.shrink(),
                  ),
                ),
                // ── Sliding gradient panel ──
                Positioned(
                  left: panelX, top: 0,
                  width: half, height: box.maxHeight,
                  child: _SidePanel(
                    c1: c1, c2: c2, isAdmin: isAdmin,
                    isSignupSide: !showSignup, // panel shows "signup" info when on login page
                    onAction: showSignup ? onToLogin : onToSignup,
                  ),
                ),
              ]);
            },
          );
        }),
      ),
    );
  }
}

class _FormZone extends StatelessWidget {
  final Widget child;
  const _FormZone({required this.child});
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: child.key != null ? child : KeyedSubtree(key: UniqueKey(), child: child),
      transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(anim),
              child: child)),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final Color c1, c2;
  final bool isAdmin, isSignupSide;
  final VoidCallback onAction;

  const _SidePanel({
    required this.c1, required this.c2,
    required this.isAdmin, required this.isSignupSide, required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final title    = isSignupSide
        ? (isAdmin ? 'New Admin?' : 'Hello, Friend!')
        : (isAdmin ? 'Welcome Back,' : 'Welcome Back!');
    final subtitle = isSignupSide
        ? 'Register with your details\nto get started'
        : 'Enter your credentials\nto access the app';
    final btnLabel = isSignupSide ? 'SIGN UP' : 'SIGN IN';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c1, c2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(top: -30, right: -30,
            child: _Blob(size: 150, color: Colors.white.withValues(alpha: 0.08))),
        Positioned(bottom: -40, left: -40,
            child: _Blob(size: 180, color: Colors.white.withValues(alpha: 0.06))),

        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 70, height: 70,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/images/logo.png',
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.quiz, color: Colors.white, size: 36)),
                ),
                const SizedBox(height: 28),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.2)),
                const SizedBox(height: 14),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 14,
                        height: 1.6)),
                const SizedBox(height: 36),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(btnLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Narrow layout ────────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final Color c1, c2;
  final Animation<double> tabAnim;
  final bool showSignup, isAdmin;
  final VoidCallback onToSignup, onToLogin;
  final Widget loginForm, signupForm;

  const _NarrowLayout({
    required this.c1, required this.c2,
    required this.tabAnim, required this.showSignup, required this.isAdmin,
    required this.onToSignup, required this.onToLogin,
    required this.loginForm, required this.signupForm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: c1.withValues(alpha: 0.20),
              blurRadius: 40, offset: const Offset(0, 14)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [c1, c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              // Logo
              Container(
                width: 60, height: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/logo.png',
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.quiz, color: Colors.white, size: 32)),
              ),
              const SizedBox(height: 16),
              Text(
                isAdmin ? 'Admin Portal' : 'Quiz App',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                isAdmin
                    ? 'Manage your quiz platform'
                    : 'Learn. Play. Compete.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80), fontSize: 13),
              ),
              const SizedBox(height: 24),
              // ── Tab row ──
              _TabRow(
                  showSignup: showSignup,
                  onLogin: onToLogin,
                  onSignup: onToSignup),
            ]),
          ),

          // ── Form ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.06), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_showSignup(showSignup)),
                child: showSignup ? signupForm : loginForm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _showSignup(bool v) => v;
}

class _TabRow extends StatelessWidget {
  final bool showSignup;
  final VoidCallback onLogin, onSignup;
  const _TabRow(
      {required this.showSignup,
      required this.onLogin,
      required this.onSignup});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(children: [
        _Tab(label: 'Sign In', active: !showSignup, onTap: onLogin),
        _Tab(label: 'Sign Up', active: showSignup, onTap: onSignup),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: active
                      ? const Color(0xFF4776E6)
                      : Colors.white.withValues(alpha: 0.85))),
        ),
      ),
    );
  }
}

// ─── Admin chip ───────────────────────────────────────────────────────────────

class _AdminChip extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onTap;
  final Color c1;
  const _AdminChip({required this.isAdmin, required this.onTap, required this.c1});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isAdmin ? c1 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12, offset: const Offset(0, 3))
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            size: 15,
            color: isAdmin ? Colors.white : c1,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'Admin Mode' : 'Switch to Admin',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isAdmin ? Colors.white : c1),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared form widgets ──────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? type;
  final Color c1;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.c1,
    this.obscure = false,
    this.suffix,
    this.type,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon:
            Icon(icon, color: Colors.grey.shade400, size: 20),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: suffix)
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c1, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color c1, c2;

  const _GradBtn({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.c1,
    required this.c2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: c1.withValues(alpha: 0.35),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.8)),
      ),
    );
  }
}
