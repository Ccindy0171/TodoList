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
        
        // Load categories if needed
        if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
          print('? TodoLists: Categories empty, triggering load');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            categoryProvider.loadCategories();
          });
        }
        
        // Show loading if category provider is still loading
        if (categoryProvider.isLoading) {
          print('? TodoLists: CategoryProvider is loading');
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        return FutureBuilder(
          key: ValueKey('${todoProvider.hashCode}-${categoryProvider.hashCode}'),
          future: todoProvider.getGeneralTodos(),
          builder: (context, generalSnapshot) {
            // Handle general todos loading state
            if (generalSnapshot.connectionState == ConnectionState.waiting) {
              print('? TodoLists: Waiting for general todos data...');
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            // Handle errors fetching general todos
            if (generalSnapshot.hasError) {
              print('? TodoLists: Error loading general todos - ${generalSnapshot.error}');
              return Center(child: Text('Error: ${generalSnapshot.error}'));
            }
            
            final generalTodos = generalSnapshot.data ?? [];
            print('? TodoLists: General Tasks loaded: ${generalTodos.length}');
            
            // Sort categories alphabetically
            final categories = List<Category>.from(categoryProvider.categories);
            categories.sort((a, b) => a.name.compareTo(b.name));
            print('? TodoLists: Categories loaded: ${categories.length}');

            return Column(
              children: [
                // General category (no category)
                CategoryListTile(
                  title: 'General',
                  icon: Icons.folder_outlined,
                  color: Colors.grey,
                  count: generalTodos.length,
                  categoryId: 'General',
                  onLongPress: () {
                    // Debug information
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Debug - General Category'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('General todos count: ${generalTodos.length}'),
                              if (generalTodos.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ...generalTodos.map((todo) => Text(
                                  'Todo: ${todo.title} (Category: ${todo.category?.name ?? "none"})'
                                )).toList(),
                              ]
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                          TextButton(
                            onPressed: () {
                              todoProvider.getGeneralTodos().then((_) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Refreshed general todos')),
                                );
                              });
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // User-created categories
                ...categories.map((category) => FutureBuilder<List<Todo>>(
                  future: todoProvider.getTodosByCategory(category.id),
                  builder: (context, todoSnapshot) {
                    if (todoSnapshot.connectionState == ConnectionState.waiting) {
                      return CategoryListTile(
                        title: category.name,
                        icon: Icons.label_outline,
                        color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                        count: 0,
                        categoryId: category.id,
                        isLoading: true,
                      );
                    }
                    
                    if (todoSnapshot.hasError) {
                      print('?? Error loading tasks for category ${category.name}: ${todoSnapshot.error}');
                      return CategoryListTile(
                        title: category.name,
                        icon: Icons.label_outline,
                        color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                        count: 0,
                        categoryId: category.id,
                        hasError: true,
                      );
                    }
                    
                    final todoCount = todoSnapshot.data?.length ?? 0;
                    
                    return CategoryListTile(
                      title: category.name,
                      icon: Icons.label_outline,
                      color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                      count: todoCount,
                      categoryId: category.id,
                    );
                  },
                )).toList(),
              ],
            );
          },
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
            )
          else if (hasError)
            Icon(Icons.error_outline, color: Colors.red[300], size: 20)
          else
            Text(
              '$count',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
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
    );
  }
} 