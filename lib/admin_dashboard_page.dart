import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'main.dart';
import 'question_editor_page.dart';
import 'login_page.dart';
import 'view_users_page.dart';
import 'manage_categories_page.dart';
import 'view_all_scores_page.dart';
import 'admin_profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _adminData;
  int _questionCount = 0;
  int _userCount     = 0;
  int _scoreCount    = 0;
  bool _loading      = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;

      final adminData = await supabase
          .from('users')
          .select('full_name, email, photo_url')
          .eq('id', uid)
          .maybeSingle();

      final quizzes = await supabase.from('quizzes').select('id');
      final users   = await supabase.from('users').select('id');
      final scores  = await supabase.from('scores').select('id');

      if (mounted) {
        setState(() {
          _adminData     = adminData;
          _questionCount = quizzes.length;
          _userCount     = users.length;
          _scoreCount    = scores.length;
          _loading       = false;
        });
        _animCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  void _go(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  void _goProfile() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AdminProfilePage()));
    // Reload data after returning from profile page (name/photo may have changed)
    setState(() { _loading = true; });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final name     = _adminData?['full_name'] as String? ?? 'Admin';
    final email    = _adminData?['email']     as String? ?? '';
    final photoUrl = _adminData?['photo_url'] as String? ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Scaffold(
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : FadeTransition(
                opacity: _fadeAnim,
                child: CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Header(
                        name:          name,
                        email:         email,
                        photoUrl:      photoUrl,
                        initials:      initials,
                        onLogout:      _logout,
                        onEditProfile: _goProfile,
                      ),
                    ),

                    // ── Stats bar ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                        child: Row(children: [
                          _StatChip(Icons.quiz_outlined,
                              '$_questionCount', 'Questions', AppColors.purple),
                          const SizedBox(width: 10),
                          _StatChip(Icons.people_outline,
                              '$_userCount', 'Users', AppColors.cyan),
                          const SizedBox(width: 10),
                          _StatChip(Icons.bar_chart_rounded,
                              '$_scoreCount', 'Scores', AppColors.pink),
                        ]),
                      ),
                    ),

                    // ── Section label ────────────────────────────────────────
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(22, 16, 22, 12),
                        child: Text('Quick Actions',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2)),
                      ),
                    ),

                    // ── Menu grid ────────────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverGrid(
                        delegate: SliverChildListDelegate([
                          _MenuCard(
                            icon:     Icons.add_circle_outline_rounded,
                            label:    'Add Question',
                            subtitle: 'Create new quiz questions',
                            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                            onTap:    () => _go(const QuestionEditorPage()),
                          ),
                          _MenuCard(
                            icon:     Icons.category_outlined,
                            label:    'Manage Categories',
                            subtitle: 'Edit or delete categories',
                            gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                            onTap:    () => _go(const ManageCategoriesPage()),
                          ),
                          _MenuCard(
                            icon:     Icons.people_outline_rounded,
                            label:    'View Users',
                            subtitle: 'See all registered users',
                            gradient: const [Color(0xFFFC5C7D), Color(0xFF6A3093)],
                            onTap:    () => _go(const ViewUsersPage()),
                          ),
                          _MenuCard(
                            icon:     Icons.bar_chart_rounded,
                            label:    'View Scores',
                            subtitle: 'Full score history',
                            gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                            onTap:    () => _go(const ViewAllScoresPage()),
                          ),
                        ]),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:   2,
                          mainAxisSpacing:  14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String name, email, photoUrl, initials;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  const _Header({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.initials,
    required this.onLogout,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Stack(children: [
        // Gradient banner
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Decorative circles
        Positioned(top: -40, right: -40,
            child: _Circle(120, AppColors.purple.withValues(alpha: 0.15))),
        Positioned(top: 60, right: 60,
            child: _Circle(60, AppColors.cyan.withValues(alpha: 0.10))),
        Positioned(bottom: 20, left: -20,
            child: _Circle(80, AppColors.violet.withValues(alpha: 0.12))),

        // Safe area + content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: title + logout
                Row(children: [
                  const Text('Admin Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: onLogout,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      borderRadius: BorderRadius.circular(24),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.white70, size: 15),
                        SizedBox(width: 6),
                        Text('Logout',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Profile row
                Row(children: [
                  // Tappable avatar → profile page
                  GestureDetector(
                    onTap: onEditProfile,
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: AppColors.primaryGradient),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.5),
                                blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl.isNotEmpty
                              ? Image.network(photoUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _InitialsAvatar(initials))
                              : _InitialsAvatar(initials),
                        ),
                      ),
                      // Edit badge
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 11),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),

                  // Name + email + badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFFC5C7D), Color(0xFF6A3093)]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('ADMIN',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar(this.initials);

  @override
  Widget build(BuildContext context) => Center(
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
      );
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _StatChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        borderRadius: BorderRadius.circular(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon in gradient circle
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: gradient.first.withValues(alpha: 0.40),
                          blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),

                const Spacer(),

                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11)),
                const SizedBox(height: 10),

                // Arrow row
                Row(children: [
                  const Spacer(),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 15),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
