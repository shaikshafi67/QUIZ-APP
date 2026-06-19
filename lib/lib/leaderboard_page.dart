import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../logo_background.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Widget _getRankIcon(int rank) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
    }
    if (rank == 2) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 30);
    }
    if (rank == 3) {
      return const Icon(Icons.emoji_events,
          color: Color(0xFFCD7F32), size: 30);
    }
    return Text('$rank.',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), elevation: 0),
      body: LogoBackground(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabase
              .from('scores')
              .stream(primaryKey: ['id'])
              .order('score', ascending: false)
              .limit(20),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No scores yet.\nBe the first to play!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final scores = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final entry = scores[index];
                final rank = index + 1;

                String displayName =
                    entry['full_name'] ?? entry['email'] ?? 'Anonymous';
                if (displayName.contains('@')) {
                  displayName = displayName.split('@')[0];
                }
                final score = (entry['score'] as num?)?.toInt() ?? 0;
                final dateStr = entry['created_at']?.toString();

                return Card(
                  elevation: 3,
                  color: Colors.white.withOpacity(0.95),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: SizedBox(
                        width: 40,
                        child: Center(child: _getRankIcon(rank))),
                    title: Text(displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(_formatDate(dateStr),
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text('$score pts',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
