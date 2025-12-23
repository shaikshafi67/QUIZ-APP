import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all the admin pages
import 'question_editor_page.dart'; 
import 'login_page.dart'; 
import 'view_users_page.dart';
import 'manage_categories_page.dart';
import 'view_all_scores_page.dart'; // <-- Import the new page

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  void _goToAddQuestion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuestionEditorPage()),
    );
  }

  void _goToManageCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageCategoriesPage()),
    );
  }

  void _goToViewUsers(BuildContext context) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ViewUsersPage()),
    );
  }

  // --- NEW: Function for the Settings button ---
  void _goToViewAllScores(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ViewAllScoresPage()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false, // Remove all previous routes
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), 
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2, 
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          AdminMenuCard(
            title: 'Add Question',
            icon: Icons.add_circle_outline,
            onTap: () => _goToAddQuestion(context),
          ),
          AdminMenuCard(
            title: 'Manage Categories',
            icon: Icons.category_outlined,
            onTap: () => _goToManageCategories(context),
          ),
          AdminMenuCard(
            title: 'View Users',
            icon: Icons.people_outline,
            onTap: () => _goToViewUsers(context),
          ),
          AdminMenuCard(
            title: 'View All Scores', // <-- Title Changed
            icon: Icons.bar_chart_outlined, // <-- Icon Changed
            onTap: () => _goToViewAllScores(context), // <-- Function Updated
          ),
        ],
      ),
    );
  }
}

// --- Re-usable Card Widget (No changes) ---
class AdminMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const AdminMenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 50,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}