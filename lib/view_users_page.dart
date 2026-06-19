import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class ViewUsersPage extends StatelessWidget {
  const ViewUsersPage({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return 'N/A';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('users')
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
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final email = user['email'] ?? 'No Email';
              final role = user['role'] ?? 'user';
              final createdAt = user['created_at']?.toString();

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.person_outline,
                    color: role == 'admin' ? Colors.blue : Colors.grey,
                  ),
                  title: Text(email,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'Joined: ${_formatDate(createdAt)}',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  trailing: Text(
                    role,
                    style: TextStyle(
                      color: role == 'admin' ? Colors.blue : Colors.black,
                      fontWeight: FontWeight.bold,
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
