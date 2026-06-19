import 'package:flutter/material.dart';
import 'main.dart';
import 'edit_category_page.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  Future<void> _confirmDelete(
      BuildContext context, String categoryName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
            'This will permanently delete the "$categoryName" category and ALL questions inside it.'),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
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

  Future<void> _deleteCategory(
      BuildContext context, String categoryName) async {
    try {
      await supabase
          .from('quizzes')
          .delete()
          .eq('category', categoryName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$categoryName" deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showRenameDialog(
      BuildContext context, String oldName) async {
    final TextEditingController renameController =
        TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: renameController,
          decoration:
              const InputDecoration(labelText: 'New Category Name'),
        ),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Rename'),
            onPressed: () {
              if (renameController.text.trim().isNotEmpty) {
                _renameCategory(
                    context, oldName, renameController.text.trim());
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _renameCategory(
      BuildContext context, String oldName, String newName) async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renaming category... please wait.')));
    try {
      await supabase
          .from('quizzes')
          .update({'category': newName})
          .eq('category', oldName);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category renamed to "$newName"!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error renaming category.')));
      }
    }
  }

  void _editCategoryQuestions(BuildContext context, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EditCategoryPage(categoryName: categoryName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('quizzes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final docs = snapshot.data!;
          final Set<String> categoryNames = {};
          for (var data in docs) {
            try {
              final name = data['category'] as String?;
              if (name != null && name.isNotEmpty) categoryNames.add(name);
            } catch (_) {}
          }

          final sortedCategories = categoryNames.toList()..sort();

          return ListView.builder(
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final categoryName = sortedCategories[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  onTap: () =>
                      _editCategoryQuestions(context, categoryName),
                  title: Text(categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Rename Category',
                        onPressed: () =>
                            _showRenameDialog(context, categoryName),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete Category',
                        onPressed: () =>
                            _confirmDelete(context, categoryName),
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
