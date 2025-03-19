import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/add_task_dialog.dart';

class TodayTasksPage extends StatefulWidget {
  const TodayTasksPage({super.key});

  @override
  State<TodayTasksPage> createState() => _TodayTasksPageState();
}

class _TodayTasksPageState extends State<TodayTasksPage> {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;
  
  // List of temporarily completed todos (for optimistic UI updates)
  Set<String> _optimisticallyCompletedIds = {};

  @override
  void initState() {
    super.initState();
    print('? TodayTasksPage: initState() - Initializing');
    _loadData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('? TodayTasksPage: didChangeDependencies() - Checking for provider changes');
    // Reload data whenever TodoProvider changes
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    // This ensures we're always showing the latest data
    todoProvider.addListener(_onProviderChanged);
  }
  
  @override
  void dispose() {
    print('? TodayTasksPage: dispose() - Cleaning up');
    // Remove listener when page is disposed
    Provider.of<TodoProvider>(context, listen: false).removeListener(_onProviderChanged);
    super.dispose();
  }
  
  void _onProviderChanged() {
    print('? TodayTasksPage: _onProviderChanged() - Provider notified changes');
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    print('? TodayTasksPage: _loadData() - Loading today todos');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todos = await context.read<TodoProvider>().getTodayTodos();
      if (mounted) {
        setState(() {
          _todos = todos;
          _isLoading = false;
        });
        print('? TodayTasksPage: Data loaded successfully - ${todos.length} todos');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        print('? TodayTasksPage: Error loading data - $e');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddTaskDialog(),
              ).then((_) => _loadData()); // Refresh after adding
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _todos.isEmpty
                  ? const Center(child: Text('No tasks for today'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos[index];
                        return _buildTaskItem(context, todo);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              initialDate: DateTime.now(),
            ),
          ).then((_) => _loadData()); // Refresh after adding
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Todo todo) {
    // Check if this task is being optimistically shown as completed
    final isOptimisticallyCompleted = _optimisticallyCompletedIds.contains(todo.id);
    final showAsCompleted = todo.completed || isOptimisticallyCompleted;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            showAsCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: showAsCompleted ? Colors.green : Colors.blue,
          ),
          onPressed: () {
            // Optimistic update: add to set of completed IDs
            setState(() {
              if (!todo.completed) {
                _optimisticallyCompletedIds.add(todo.id);
              }
            });
            
            // Perform the actual toggle in the backend
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              // After actual toggle, clear the optimistic state and reload data
              setState(() {
                _optimisticallyCompletedIds.remove(todo.id);
              });
              _loadData();
            });
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: showAsCompleted ? TextDecoration.lineThrough : null,
            color: showAsCompleted ? Colors.grey : null,
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
                  decoration: showAsCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            if (todo.dueDate != null)
              Text(
                '${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
                  decoration: showAsCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id).then((_) {
              // Reload after deletion
              _loadData();
            });
          },
        ),
      ),
    );
  }
} 