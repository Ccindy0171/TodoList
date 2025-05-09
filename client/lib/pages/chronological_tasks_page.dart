import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';

class ChronologicalTasksPage extends StatefulWidget {
  const ChronologicalTasksPage({super.key});

  @override
  State<ChronologicalTasksPage> createState() => _ChronologicalTasksPageState();
}

class _ChronologicalTasksPageState extends State<ChronologicalTasksPage> {
  List<Todo> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    _loadChronologicalTasks();
  }

  Future<void> _loadChronologicalTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get tasks sorted chronologically
      final tasks = await context.read<TodoProvider>().getChronologicalTodos(
        completed: _showCompletedTasks ? null : false,
      );
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chronological View'),
        actions: [
          Switch(
            value: _showCompletedTasks,
            onChanged: (value) {
              setState(() {
                _showCompletedTasks = value;
              });
              _loadChronologicalTasks();
            },
          ),
          const Text('Show All', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChronologicalTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _tasks.isEmpty
                    ? const Center(child: Text('No tasks found'))
                    : _buildGroupedTaskList(),
      ),
    );
  }

  Widget _buildGroupedTaskList() {
    // Group tasks by date
    final Map<String, List<Todo>> groupedTasks = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (final task in _tasks) {
      if (task.dueDate != null) {
        final dateKey = dateFormat.format(task.dueDate!);
        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(task);
      }
    }
    
    // Sort dates
    final sortedDates = groupedTasks.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final tasksInDay = groupedTasks[dateKey]!;
        
        // Parse date for header
        final date = DateTime.parse(dateKey);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        // Format the date header
        String dateHeader;
        if (date.year == today.year && 
            date.month == today.month && 
            date.day == today.day) {
          dateHeader = 'Today';
        } else if (date.year == tomorrow.year && 
                  date.month == tomorrow.month && 
                  date.day == tomorrow.day) {
          dateHeader = 'Tomorrow';
        } else {
          dateHeader = DateFormat('EEEE, MMMM d').format(date);
        }
        
        // Is this date in the past?
        final isPastDate = date.isBefore(today);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8, top: 16),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isPastDate ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dateHeader,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPastDate ? Colors.red : Colors.blue,
                ),
              ),
            ),
            ...tasksInDay.map((task) => _buildTaskItem(task)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTaskItem(Todo todo) {
    final timeFormat = DateFormat('h:mm a');
    
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
            color: todo.completed ? Colors.green : Colors.blue,
          ),
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              _loadChronologicalTasks();
            });
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty)
              Text(
                todo.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            if (todo.dueDate != null)
              Text(
                'Time: ${timeFormat.format(todo.dueDate!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            if (todo.category != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(int.parse(todo.category!.color.replaceAll('#', '0xFF'))).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  todo.category!.name,
                  style: TextStyle(
                    color: Color(int.parse(todo.category!.color.replaceAll('#', '0xFF'))),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id).then((_) {
              _loadChronologicalTasks();
            });
          },
        ),
      ),
    );
  }
} 