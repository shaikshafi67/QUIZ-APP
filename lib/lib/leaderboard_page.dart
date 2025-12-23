import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import 'package:quize_app1/logo_background.dart';
import 'logo_background.dart'; // Keeps your app branding

// --- DATA MODEL ---
class LeaderboardEntry {
  final String displayName;
  final int score;
  final Timestamp timestamp;

  LeaderboardEntry({
    required this.displayName,
    required this.score,
    required this.timestamp,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    // Logic: Try to find 'fullName', if missing use 'email', if missing use 'Anonymous'
    String name = data['fullName'] ?? data['email'] ?? 'Anonymous';
    
    // Optional: If it's an email, hide the @gmail.com part to make it look cleaner
    if (name.contains('@')) {
      name = name.split('@')[0];
    }

    return LeaderboardEntry(
      displayName: name,
      score: data['score'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  // Helper to get Gold/Silver/Bronze icons
  Widget _getRankIcon(int rank) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
    }
    if (rank == 2) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 30);
    }
    if (rank == 3) {
      return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 30); // Bronze
    }
    return Text(
      '$rank.',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Helper to format date
  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, h:mm a').format(dateTime); // e.g., Nov 20, 10:30 AM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      // Use LogoBackground for consistent style
      body: LogoBackground(
        child: StreamBuilder<QuerySnapshot>(
          // Fetch top 20 scores, ordered by Score (High to Low) then Time (Old to New)
          stream: FirebaseFirestore.instance
              .collection('scores')
              .orderBy('score', descending: true)
              .orderBy('timestamp', descending: false) // Tie-breaker: who got the score first
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            // 1. Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            // 2. Error
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            // 3. Empty
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No scores yet.\nBe the first to play!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            final scores = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final entry = LeaderboardEntry.fromFirestore(scores[index]);
                final rank = index + 1;

                return Card(
                  elevation: 3,
                  // Slightly transparent white to see the logo behind it
                  color: Colors.white.withOpacity(0.95),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Rank Icon (Left)
                    leading: SizedBox(
                      width: 40,
                      child: Center(child: _getRankIcon(rank)),
                    ),
                    // User Name
                    title: Text(
                      entry.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Date
                    subtitle: Text(
                      _formatDate(entry.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    // Score (Right)
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Text(
                        '${entry.score} pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
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