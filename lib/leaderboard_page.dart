import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'logo_background.dart';

class LeaderboardEntry {
  final String displayName; // Changed to generic name
  final int score;
  final Timestamp timestamp;

  LeaderboardEntry({required this.displayName, required this.score, required this.timestamp});

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    // LOOK FOR FULL NAME, FALLBACK TO EMAIL
    String name = data['fullName'] ?? data['email'] ?? 'Anonymous';
    return LeaderboardEntry(
      displayName: name,
      score: data['score'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Widget _getRankIcon(int rank) {
    if (rank == 1) return const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
    if (rank == 2) return const Icon(Icons.emoji_events, color: Colors.grey, size: 30);
    if (rank == 3) return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 30);
    return Text('$rank.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: LogoBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('scores')
              .orderBy('score', descending: true)
              .orderBy('timestamp', descending: false)
              .limit(20) 
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No scores yet. Be the first!'));
            }

            final scores = snapshot.data!.docs;

            return ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final entry = LeaderboardEntry.fromFirestore(scores[index]);
                final rank = index + 1;

                return Card(
                  elevation: 2.0,
                  color: Colors.white.withOpacity(0.95),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: ListTile(
                    leading: SizedBox(
                      width: 40,
                      child: Center(
                        child: _getRankIcon(rank),
                      ),
                    ),
                    // --- DISPLAY NAME HERE ---
                    title: Text(
                      entry.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(entry.timestamp), 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Text(
                      '${entry.score} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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