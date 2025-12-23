import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'logo_background.dart';
import 'profile_page.dart'; // <-- Import Profile Page

class UserHomePage extends StatelessWidget {
  final Function(int) onTabChange;

  const UserHomePage({super.key, required this.onTabChange});

  // Function to get the user's real name from Firestore
  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fullName'] ?? user.email?.split('@')[0] ?? 'User';
      }
    } catch (e) {
      print("Error fetching name: $e");
    }
    // Fallback to email name if database fails
    return user.email?.split('@')[0] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    final String date = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on home
        actions: [
          // --- PROFILE BUTTON ---
          IconButton(
            icon: const Icon(Icons.account_circle, size: 32, color: Colors.blue),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LogoBackground(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Display
              Text(
                date.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // --- DYNAMIC NAME FETCHING ---
              FutureBuilder<String>(
                future: _getUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                     return const SizedBox(
                       height: 40, 
                       width: 150,
                       child: Align(
                         alignment: Alignment.centerLeft, 
                         child: LinearProgressIndicator()
                       )
                     );
                  }
                  
                  // Default name if data is missing
                  String displayName = snapshot.data ?? "User"; 
                  
                  // Capitalize first letter
                  if (displayName.isNotEmpty) {
                    displayName = displayName[0].toUpperCase() + displayName.substring(1);
                  }

                  return Text(
                    'Hello, \n$displayName 👋',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // "Start Quiz" Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready to test your skills?',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a topic and start learning today!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => onTabChange(1), // Switch to Quiz Tab
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Start Quiz Now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}