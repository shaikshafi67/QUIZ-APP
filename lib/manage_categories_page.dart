import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_category_page.dart'; 

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  // --- 1. DELETE FUNCTION ---
  Future<void> _confirmDelete(BuildContext context, String categoryName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text('This will permanently delete the "$categoryName" category and ALL questions inside it.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
            onPressed: () {
              _deleteCategory(context, categoryName);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context, String categoryName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: categoryName)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$categoryName" deleted successfully')));
      }
    } catch (e) {
      print('Error deleting: $e');
    }
  }

  // --- 2. RENAME FUNCTION (NEW) ---
  Future<void> _showRenameDialog(BuildContext context, String oldName) async {
    final TextEditingController renameController = TextEditingController(text: oldName);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'New Category Name'),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Rename'),
            onPressed: () {
              if (renameController.text.trim().isNotEmpty) {
                _renameCategory(context, oldName, renameController.text.trim());
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _renameCategory(BuildContext context, String oldName, String newName) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renaming category... please wait.')));
    
    try {
      // 1. Get all questions with the OLD name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: oldName)
          .get();
      
      // 2. Batch update them to the NEW name
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'category': newName});
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category renamed to "$newName"!')));
      }
    } catch (e) {
      print('Error renaming: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error renaming category.')));
      }
    }
  }

  void _editCategoryQuestions(BuildContext context, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditCategoryPage(categoryName: categoryName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No categories found.'));

          final docs = snapshot.data!.docs;
          final Set<String> categoryNames = {};
          for (var doc in docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              categoryNames.add(data['category'] as String);
            } catch (e) { print(e); }
          }
          
          final sortedCategories = categoryNames.toList()..sort();

          return ListView.builder(
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final categoryName = sortedCategories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  // Tap to open questions list
                  onTap: () => _editCategoryQuestions(context, categoryName),
                  title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- RENAME BUTTON ---
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Rename Category',
                        onPressed: () => _showRenameDialog(context, categoryName),
                      ),
                      // --- DELETE BUTTON ---
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Category',
                        onPressed: () => _confirmDelete(context, categoryName),
                      ),
                    ],
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