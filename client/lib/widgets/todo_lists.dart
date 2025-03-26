import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/todo.dart';

class TodoLists extends StatefulWidget {
  const TodoLists({super.key});

  @override
  State<TodoLists> createState() => _TodoListsState();
}

class _TodoListsState extends State<TodoLists> {
  // Use keys to force rebuilds when needed
  final _generalTodosKey = GlobalKey();
  final Map<String, GlobalKey> _categoryKeys = {};
  
  @override
  void initState() {
    super.initState();
    // Load categories once when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      categoryProvider.loadCategories();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    print('? TodoLists: build() - Building widget');
    return Consumer2<TodoProvider, CategoryProvider>(
      builder: (context, todoProvider, categoryProvider, child) {
        print('? TodoLists: Consumer rebuilding with provider hashCode: ${todoProvider.hashCode}');
        print('? TodoLists: Found ${categoryProvider.categories.length} categories');
        
        // Show loading if category provider is still loading
        if (categoryProvider.isLoading) {
          print('? TodoLists: CategoryProvider is loading');
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Ensure we have keys for all categories
        for (final category in categoryProvider.categories) {
          if (!_categoryKeys.containsKey(category.id)) {
            _categoryKeys[category.id] = GlobalKey();
          }
        }
        
        // Clean up keys for categories that no longer exist
        _categoryKeys.removeWhere((key, value) => 
          !categoryProvider.categories.any((category) => category.id == key));
        
        // Cache future for general todos
        final generalTodosFuture = todoProvider.getGeneralTodos();
        
        // Sort categories alphabetically for display
        final sortedCategories = List<Category>.from(categoryProvider.categories);
        sortedCategories.sort((a, b) => a.name.compareTo(b.name));
        
        return Column(
          children: [
            // General category (no category)
            FutureBuilder(
              key: _generalTodosKey,
              future: generalTodosFuture,
              builder: (context, generalSnapshot) {
                // Handle general todos loading state
                if (generalSnapshot.connectionState == ConnectionState.waiting) {
                  print('? TodoLists: Waiting for general todos data...');
                  return const SizedBox(
                    height: 60, // Reduced height for better UX
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                // Handle errors fetching general todos
                if (generalSnapshot.hasError) {
                  print('? TodoLists: Error loading general todos - ${generalSnapshot.error}');
                  return SizedBox(
                    height: 60,
                    child: Center(child: Text('Error: ${generalSnapshot.error}')),
                  );
                }
                
                final generalTodos = generalSnapshot.data ?? [];
                print('? TodoLists: General Tasks loaded: ${generalTodos.length}');
                
                return CategoryListTile(
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
                              setState(() {}); // Force rebuild
                              todoProvider.getGeneralTodos().then((_) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Refreshed general todos')),
                                );
                              });
                            },
                            child: const Text('Refresh'),
                          ),
                          TextButton(
                            onPressed: () {
                              categoryProvider.loadCategories().then((_) {
                                setState(() {}); // Force rebuild
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Refreshed categories')),
                                );
                              });
                            },
                            child: const Text('Refresh Categories'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            
            // Display a message if no categories are found
            if (sortedCategories.isEmpty && !categoryProvider.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Text('No categories found'),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                          categoryProvider.loadCategories();
                        },
                        child: const Text('Refresh Categories'),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Display sorted categories
            ...sortedCategories.map((category) {
              // Cache the future for each category's todos
              final categoryTodosFuture = todoProvider.getTodosByCategory(category.id);
              
              return FutureBuilder<List<Todo>>(
                key: _categoryKeys[category.id],
                future: categoryTodosFuture,
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