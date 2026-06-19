import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'profile_page.dart';
import 'app_theme.dart';

class UserHomePage extends StatefulWidget {
  final Function(int) onTabChange;
  const UserHomePage({super.key, required this.onTabChange});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;

  Future<Map<String, dynamic>> _getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return {'name': 'User', 'photoUrl': ''};
    try {
      final data = await supabase
          .from('users')
          .select('full_name, photo_url')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null) {
        return {
          'name': data['full_name'] ??
              user.email?.split('@')[0] ??
              'User',
          'photoUrl': data['photo_url'] ?? '',
        };
      }
    } catch (_) {}
    return {
      'name': user.email?.split('@')[0] ?? 'User',
      'photoUrl': ''
    };
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
            CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _cardsFade =
        CurvedAnimation(parent: _cardsController, curve: Curves.easeOut);

    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _cardsController.forward());
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withAlpha(30),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -70,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyan.withAlpha(20),
                ),
              ),
            ),
            SafeArea(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getUserData(),
                builder: (context, snapshot) {
                  final name = snapshot.data?['name'] ?? 'User';
                  final photoUrl = snapshot.data?['photoUrl'] ?? '';
                  final displayName = name.isNotEmpty
                      ? name[0].toUpperCase() + name.substring(1)
                      : 'User';

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          child: FadeTransition(
                            opacity: _headerFade,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        date.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Hello, ',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w400,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                            ),
                                            TextSpan(
                                              text: displayName,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.purple,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: ' 👋',
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const DarkModeToggle(),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const ProfilePage()),
                                        ),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                                colors:
                                                    AppColors.primaryGradient),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.purple
                                                    .withAlpha(80),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: photoUrl.isNotEmpty
                                              ? ClipOval(
                                                  child: Image.network(
                                                      photoUrl,
                                                      fit: BoxFit.cover),
                                                )
                                              : const Icon(Icons.person,
                                                  color: Colors.white,
                                                  size: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _cardsFade,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                GlassCard(
                                  gradient: const LinearGradient(
                                    colors: AppColors.primaryGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Ready to challenge\nyourself?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            GestureDetector(
                                              onTap: () =>
                                                  widget.onTabChange(1),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(40),
                                                      blurRadius: 8,
                                                    ),
                                                  ],
                                                ),
                                                child: const Text(
                                                  'Start Quiz →',
                                                  style: TextStyle(
                                                    color: AppColors.purple,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('🧠',
                                          style: TextStyle(fontSize: 64)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _quickActionCard(
                                        icon: '🏆',
                                        label: 'Leaderboard',
                                        subtitle: 'See rankings',
                                        colors: [
                                          AppColors.orange,
                                          AppColors.pink
                                        ],
                                        onTap: () => widget.onTabChange(2),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _quickActionCard(
                                        icon: '📚',
                                        label: 'Categories',
                                        subtitle: 'Browse topics',
                                        colors: [
                                          AppColors.cyan,
                                          AppColors.purple
                                        ],
                                        onTap: () => widget.onTabChange(1),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _quickActionCard(
                                        icon: '👤',
                                        label: 'Profile',
                                        subtitle: 'Edit your info',
                                        colors: [
                                          AppColors.violet,
                                          AppColors.purple
                                        ],
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ProfilePage())),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _quickActionCard(
                                        icon: '⚡',
                                        label: 'Quick Play',
                                        subtitle: 'Random quiz',
                                        colors: const [
                                          Color(0xFFFFD700),
                                          AppColors.orange
                                        ],
                                        onTap: () => widget.onTabChange(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard({
    required String icon,
    required String label,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
