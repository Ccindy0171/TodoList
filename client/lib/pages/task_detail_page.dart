import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/add_task_dialog.dart';

class TaskDetailPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String type;

  const TaskDetailPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
        actions: [
          if (title == 'Today')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddTaskDialog(),
                );
              },
            )
          else if (title != 'Completed')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(
                    categoryId: type == 'list' ? title : null,
                  ),
                );
              },
            ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          List<Todo> filteredTodos = [];
          
          if (type == 'stat') {
            if (title == 'Planned') {
              filteredTodos = todoProvider.getUpcomingTodos();
            } else if (title == 'Completed') {
              filteredTodos = todoProvider.todos.where((todo) => todo.completed).toList();
            } else if (title == 'All') {
              filteredTodos = todoProvider.todos;
            }
          } else if (type == 'list') {
            filteredTodos = todoProvider.todos.where((todo) => 
              todo.category?.name == title
            ).toList();
          }

          if (todoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (todoProvider.error != null) {
            return Center(child: Text('Error: ${todoProvider.error}'));
          }

          if (filteredTodos.isEmpty) {
            return Center(
              child: Text('No tasks in $title'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredTodos.length,
            itemBuilder: (context, index) {
              final todo = filteredTodos[index];
              return _buildTaskItem(context, todo);
            },
          );
        },
      ),
      floatingActionButton: title != 'Completed' ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              categoryId: type == 'list' ? title : null,
            ),
          );
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildTaskItem(BuildContext context, Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.completed ? Colors.green : color,
          ),
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null)
              Text(
                todo.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            if (todo.dueDate != null)
              Text(
                '${todo.dueDate!.year}-${todo.dueDate!.month.toString().padLeft(2, '0')}-${todo.dueDate!.day.toString().padLeft(2, '0')} ${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id);
          },
        ),
      ),
    );
  }
} 