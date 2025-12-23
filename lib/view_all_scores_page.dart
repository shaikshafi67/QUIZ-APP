import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScoreEntry {
  final String email;
  final String fullName; // <--- Added Name
  final int score;
  final int totalQuestions;
  final String category;
  final Timestamp timestamp;

  ScoreEntry({
    required this.email,
    required this.fullName, // <--- Added Name
    required this.score,
    required this.totalQuestions,
    required this.category,
    required this.timestamp,
  });

  factory ScoreEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ScoreEntry(
      email: data['email'] ?? 'Anonymous',
      // Try to get name, fallback to email if missing
      fullName: data['fullName'] ?? data['email'] ?? 'Unknown User', 
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      category: data['category'] ?? 'Unknown',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class ViewAllScoresPage extends StatelessWidget {
  const ViewAllScoresPage({super.key});

  String _formatDate(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Scores (History)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scores')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          final scores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final entry = ScoreEntry.fromFirestore(scores[index]);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(entry.score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(
                    entry.fullName, // <--- Shows Name now!
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${entry.category} • ${_formatDate(entry.timestamp)}"),
                  trailing: Text(
                    '${entry.score}/${entry.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 18,
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
    );
  }
}