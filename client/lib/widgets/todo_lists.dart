import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/todo.dart';

class TodoLists extends StatelessWidget {
  const TodoLists({super.key});

  @override
  Widget build(BuildContext context) {
    print('? TodoLists: build() - Building widget');
    return Consumer2<TodoProvider, CategoryProvider>(
      builder: (context, todoProvider, categoryProvider, child) {
        print('? TodoLists: Consumer rebuilding with provider hashCode: ${todoProvider.hashCode}');
        
        final isLoading = todoProvider.isLoading || categoryProvider.isLoading;
        
        if (isLoading) {
          print('? TodoLists: Provider is still loading data');
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final categories = categoryProvider.categories;
        print('? TodoLists: Found ${categories.length} categories');
        
        // Get cached general todos
        final generalTodos = todoProvider.getCachedGeneralTodos ?? [];
        
        // Sort categories alphabetically for display
        final sortedCategories = List<Category>.from(categories);
        sortedCategories.sort((a, b) => a.name.compareTo(b.name));
        
        return Column(
          children: [
            // General category (no category)
            CategoryListTile(
              title: 'General',
              icon: Icons.folder_outlined,
              color: Colors.grey,
              count: generalTodos.length,
              categoryId: 'General',
            ),
            
            // Display a message if no categories are found
            if (sortedCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Text('No categories found'),
                      TextButton(
                        onPressed: () => categoryProvider.loadCategories(),
                        child: const Text('Refresh Categories'),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Display sorted categories
            ...sortedCategories.map((category) {
              // Get cached todos for this category
              final categoryTodos = todoProvider.getCategoryTodos(category.id) ?? [];
              
              return CategoryListTile(
                title: category.name,
                icon: Icons.label_outline,
                color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                count: categoryTodos.length,
                categoryId: category.id,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class CategoryListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final String categoryId;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onLongPress;

  const CategoryListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.categoryId,
    this.isLoading = false,
    this.hasError = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(
                title: title,
                icon: icon,
                color: color,
                type: 'category',
                categoryId: categoryId,
              ),
            ),
          );
        },
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else if (hasError)
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                )
              else
                Text(
                  '$count ${count == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 