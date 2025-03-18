import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../providers/todo_provider.dart';

class TodoLists extends StatelessWidget {
  const TodoLists({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final reminders = todoProvider.todos.where((todo) => 
          todo.category?.name == 'Reminders'
        ).toList();
        
        final futurePlans = todoProvider.todos.where((todo) => 
          todo.category?.name == 'Future Plans'
        ).toList();

        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_none, color: Colors.blue),
              title: const Text('Reminders'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${reminders.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskDetailPage(
                      title: 'Reminders',
                      icon: Icons.notifications_none,
                      color: Colors.blue,
                      type: 'list',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.red),
              title: const Text('Future Plans'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${futurePlans.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskDetailPage(
                      title: 'Future Plans',
                      icon: Icons.calendar_month,
                      color: Colors.red,
                      type: 'list',
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
} 