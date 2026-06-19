import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'app_theme.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange.withAlpha(25),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.orange, AppColors.pink],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withAlpha(80),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.leaderboard_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Top 20 players',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('scores')
                          .stream(primaryKey: ['id'])
                          .order('score', ascending: false)
                          .limit(20),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.purple));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🏆',
                                    style: TextStyle(fontSize: 56)),
                                const SizedBox(height: 16),
                                Text(
                                  'No scores yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to play!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final scores = snapshot.data!;
                        return ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: scores.length,
                          itemBuilder: (context, index) {
                            final data = scores[index];
                            final rank = index + 1;
                            final displayName = data['full_name'] ??
                                data['email'] ??
                                'Anonymous';
                            final score =
                                (data['score'] as num?)?.toInt() ?? 0;
                            final createdAt = data['created_at'] != null
                                ? DateTime.tryParse(
                                    data['created_at'].toString())
                                : null;

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration:
                                  Duration(milliseconds: 300 + index * 60),
                              curve: Curves.easeOut,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEntry(
                                    displayName, score, createdAt, rank, isDark),
                              ),
                            );
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

  Widget _buildEntry(String displayName, int score, DateTime? createdAt,
      int rank, bool isDark) {
    final isTop3 = rank <= 3;
    final rankData = _getRankData(rank);

    return GlassCard(
      gradient: isTop3
          ? LinearGradient(colors: [
              rankData['color'].withAlpha(40),
              rankData['color'].withAlpha(10),
            ])
          : null,
      borderColor: isTop3 ? rankData['color'].withAlpha(80) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: isTop3
                  ? LinearGradient(
                      colors: [rankData['color'], rankData['color2']])
                  : null,
              color: isTop3 ? null : Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isTop3
                  ? [
                      BoxShadow(
                          color: rankData['color'].withAlpha(80), blurRadius: 8)
                    ]
                  : [],
            ),
            child: Center(
              child: isTop3
                  ? Text(rankData['emoji'],
                      style: const TextStyle(fontSize: 20))
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.primaryGradient),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  createdAt != null
                      ? DateFormat('MMM d, h:mm a').format(createdAt)
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isTop3
                  ? LinearGradient(
                      colors: [rankData['color'], rankData['color2']])
                  : const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: AppColors.purple.withAlpha(60), blurRadius: 8),
              ],
            ),
            child: Text(
              '$score pts',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRankData(int rank) {
    switch (rank) {
      case 1:
        return {
          'emoji': '🥇',
          'color': const Color(0xFFFFD700),
          'color2': const Color(0xFFFFA500),
        };
      case 2:
        return {
          'emoji': '🥈',
          'color': const Color(0xFFC0C0C0),
          'color2': const Color(0xFF808080),
        };
      case 3:
        return {
          'emoji': '🥉',
          'color': const Color(0xFFCD7F32),
          'color2': const Color(0xFF8B4513),
        };
      default:
        return {
          'emoji': '',
          'color': AppColors.purple,
          'color2': AppColors.violet,
        };
    }
  }
}
