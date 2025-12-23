import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

// A simple model for our user data
class AppUser {
  final String id;
  final String email;
  final String role;
  final Timestamp? createdAt; // Make nullable to handle old documents without it

  AppUser({required this.id, required this.email, required this.role, this.createdAt});

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? 'No Email',
      role: data['role'] ?? 'user',
      createdAt: data['createdAt'] as Timestamp?, // Cast to Timestamp?
    );
  }
}

class ViewUsersPage extends StatelessWidget {
  const ViewUsersPage({super.key});

  // Helper to format the timestamp
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A'; // Handle old users
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy').format(dateTime); // Format to just date
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the 'users' collection, order by when they were created
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true) // Sort by creation date
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final appUser = AppUser.fromFirestore(users[index]);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    appUser.role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.person_outline,
                    color: appUser.role == 'admin' ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    appUser.email,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // UPDATED SUBTITLE
                  subtitle: Text(
                    'Joined: ${_formatDate(appUser.createdAt)}',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  trailing: Text(
                    appUser.role,
                    style: TextStyle(
                      color: appUser.role == 'admin' ? Colors.blue : Colors.black,
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