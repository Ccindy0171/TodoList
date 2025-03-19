import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/add_task_dialog.dart';

class TaskDetailPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String type;
  final String? categoryId;

  const TaskDetailPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    this.categoryId,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;
  
  // List of temporarily completed todos (for optimistic UI updates)
  Set<String> _optimisticallyCompletedIds = {};

  @override
  void initState() {
    super.initState();
    print('? TaskDetailPage: initState() - Initializing for "${widget.title}"');
    _loadData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('? TaskDetailPage: didChangeDependencies() - Checking for provider changes');
    // Reload data whenever TodoProvider changes
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    // This ensures we're always showing the latest data
    todoProvider.addListener(_onProviderChanged);
  }
  
  @override
  void dispose() {
    print('? TaskDetailPage: dispose() - Cleaning up');
    // Remove listener when page is disposed
    Provider.of<TodoProvider>(context, listen: false).removeListener(_onProviderChanged);
    super.dispose();
  }
  
  void _onProviderChanged() {
    print('? TaskDetailPage: _onProviderChanged() - Provider notified changes for "${widget.title}"');
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    print('? TaskDetailPage: _loadData() - Loading data for "${widget.title}"');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Todo> todos;
      if (widget.type == 'stat') {
        if (widget.title == 'Today') {
          todos = await context.read<TodoProvider>().getTodayTodos();
        } else if (widget.title == 'Planned') {
          todos = await context.read<TodoProvider>().getUpcomingTodos();
        } else if (widget.title == 'Completed') {
          todos = await context.read<TodoProvider>().getCompletedTodayTodos();
        } else if (widget.title == 'All') {
          todos = await context.read<TodoProvider>().getAllTodos();
        } else {
          todos = [];
        }
      } else if (widget.type == 'list') {
        if (widget.title == 'Reminders') {
          todos = await context.read<TodoProvider>().getReminders();
        } else if (widget.title == 'Future Plans') {
          todos = await context.read<TodoProvider>().getFuturePlans();
        } else {
          todos = await context.read<TodoProvider>().getTodosByCategory(widget.title);
        }
      } else if (widget.type == 'category') {
        if (widget.categoryId == 'none') {
          todos = await context.read<TodoProvider>().getGeneralTodos();
        } else if (widget.categoryId != null) {
          todos = await context.read<TodoProvider>().getTodosByCategory(widget.categoryId!);
        } else {
          todos = [];
        }
      } else {
        todos = [];
      }
      
      if (mounted) {
        setState(() {
          _todos = todos;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.title),
        actions: [
          if (widget.title == 'Today')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddTaskDialog(),
                ).then((_) => _loadData()); // Refresh after adding
              },
            )
          else if (widget.title != 'Completed')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(
                    categoryId: widget.type == 'category' ? widget.categoryId : null,
                  ),
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
                  ? Center(child: Text('No tasks in ${widget.title}'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos[index];
                        return _buildTaskItem(context, todo);
                      },
                    ),
      floatingActionButton: widget.title != 'Completed' ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              categoryId: widget.type == 'category' ? widget.categoryId : null,
            ),
          ).then((_) => _loadData()); // Refresh after adding
        },
        child: const Icon(Icons.add),
      ) : null,
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
            color: showAsCompleted ? Colors.green : widget.color,
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
            if (widget.title == 'Completed')
              Text(
                'Completed at ${todo.updatedAt.hour.toString().padLeft(2, '0')}:${todo.updatedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (todo.dueDate != null)
              Text(
                '${todo.dueDate!.year}-${todo.dueDate!.month.toString().padLeft(2, '0')}-${todo.dueDate!.day.toString().padLeft(2, '0')} ${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
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