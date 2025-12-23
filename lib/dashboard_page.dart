import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; 
import 'logo_background.dart'; 
import 'difficulty_selection_page.dart'; 

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Category'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: LogoBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            // 2. Error State (Fixes infinite loading if permissions are wrong)
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // 3. No Data State
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No categories found.'));
            }

            final docs = snapshot.data!.docs;
            final Map<String, String> categoriesWithImages = {};

            // 4. Safe Data Extraction
            for (var doc in docs) {
              try {
                final data = doc.data() as Map<String, dynamic>;
                
                // Safely get fields, defaulting to '' if missing
                final String categoryName = data['category'] ?? 'Unknown';
                final String categoryImageUrl = data['categoryImageUrl'] ?? ''; 
                
                // Add to map
                if (categoryName != 'Unknown') {
                   if (!categoriesWithImages.containsKey(categoryName) || categoryImageUrl.isNotEmpty) {
                      categoriesWithImages[categoryName] = categoryImageUrl;
                   }
                }
              } catch (e) {
                print('Skipping bad document: $e');
              }
            }

            final sortedCategories = categoriesWithImages.keys.toList()..sort();

            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0, 
              ),
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final categoryName = sortedCategories[index];
                final categoryImageUrl = categoriesWithImages[categoryName];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DifficultySelectionPage(categoryName: categoryName),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    color: Colors.white.withOpacity(0.9), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (categoryImageUrl != null && categoryImageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              categoryImageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                              },
                            ),
                          )
                        else
                          const Icon(Icons.quiz, size: 80, color: Colors.blue),
                          
                        const SizedBox(height: 10),
                        Text(
                          categoryName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
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