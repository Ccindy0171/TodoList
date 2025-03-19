import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';

class TodoLists extends StatelessWidget {
  const TodoLists({super.key});

  @override
  Widget build(BuildContext context) {
    print('? TodoLists: build() - Building widget');
    return Consumer2<TodoProvider, CategoryProvider>(
      builder: (context, todoProvider, categoryProvider, child) {
        print('? TodoLists: Consumer rebuilding with provider hashCode: ${todoProvider.hashCode}');
        
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Ensure categories are loaded
        if (categoryProvider.categories.isEmpty) {
          categoryProvider.loadCategories();
        }
        
        return FutureBuilder(
          key: ValueKey('${todoProvider.hashCode}-${categoryProvider.hashCode}'),
          future: Future.wait([
            todoProvider.getGeneralTodos(),
            Future.value(categoryProvider.categories),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('? TodoLists: Waiting for data...');
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('? TodoLists: Error loading data - ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final generalTodos = snapshot.data![0] as List<dynamic>;
            final categories = snapshot.data![1] as List<Category>;
            
            print('? TodoLists: Data loaded - General Tasks: ${generalTodos.length}, Categories: ${categories.length}');

            // Sort categories alphabetically
            categories.sort((a, b) => a.name.compareTo(b.name));

            return Column(
              children: [
                // General category (no category)
                CategoryListTile(
                  title: 'General',
                  icon: Icons.folder_outlined,
                  color: Colors.grey,
                  count: generalTodos.length,
                  categoryId: 'none',
                ),
                
                // User-created categories
                ...categories.map((category) => FutureBuilder<List<dynamic>>(
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

  const CategoryListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.categoryId,
    this.isLoading = false,
    this.hasError = false,
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
    );
  }
} 