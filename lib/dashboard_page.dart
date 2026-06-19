import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'difficulty_selection_page.dart';
import 'app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _searchQuery = '';

  // Category gradient palettes
  final List<List<Color>> _gradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF00D4FF), const Color(0xFF667EEA)],
    [const Color(0xFFFF6B9D), const Color(0xFFFF8C42)],
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    [const Color(0xFFF7971E), const Color(0xFFFFD200)],
    [const Color(0xFFDA22FF), const Color(0xFF9733EE)],
    [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    [const Color(0xFFFC5C7D), const Color(0xFF6A82FB)],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withAlpha(25),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar area
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Category',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'What will you learn today?',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _logout,
                          child: GlassCard(
                            padding: const EdgeInsets.all(10),
                            borderRadius: BorderRadius.circular(12),
                            child: Icon(Icons.logout_rounded,
                                color: AppColors.pink, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.purple, size: 20),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Grid
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('quizzes')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.purple));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return _emptyState(isDark);
                        }

                        final docs = snapshot.data!.docs;
                        final Map<String, String> categoriesWithImages = {};
                        for (var doc in docs) {
                          try {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['category'] ?? 'Unknown';
                            final img = data['categoryImageUrl'] ?? '';
                            if (name != 'Unknown') {
                              if (!categoriesWithImages.containsKey(name) ||
                                  img.isNotEmpty) {
                                categoriesWithImages[name] = img;
                              }
                            }
                          } catch (_) {}
                        }

                        final filtered = categoriesWithImages.keys
                            .where((k) => k.toLowerCase().contains(_searchQuery))
                            .toList()
                          ..sort();

                        if (filtered.isEmpty) return _emptyState(isDark);

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final name = filtered[index];
                            final img = categoriesWithImages[name] ?? '';
                            final gradient =
                                _gradients[index % _gradients.length];

                            return _buildCategoryCard(
                                name, img, gradient, index);
                          },
                        );
                      },
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

  Widget _buildCategoryCard(
      String name, String imgUrl, List<Color> gradient, int index) {
    final delay = index * 80;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DifficultySelectionPage(categoryName: name),
          ),
        ),
        child: GlassCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image or gradient icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: imgUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 36),
                        ),
                      )
                    : const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Play Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask admin to add quiz categories',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
