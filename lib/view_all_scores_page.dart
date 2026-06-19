import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class ViewAllScoresPage extends StatelessWidget {
  const ViewAllScoresPage({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy - h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Scores (History)')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('scores')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          final scores = snapshot.data!;
          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final entry = scores[index];
              final fullName =
                  entry['full_name'] ?? entry['email'] ?? 'Unknown User';
              final score = (entry['score'] as num?)?.toInt() ?? 0;
              final totalQuestions =
                  (entry['total_questions'] as num?)?.toInt() ?? 0;
              final category = entry['category'] ?? 'Unknown';
              final createdAt = entry['created_at']?.toString();

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(score.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$category • ${_formatDate(createdAt)}'),
                  trailing: Text(
                    '$score/$totalQuestions',
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
