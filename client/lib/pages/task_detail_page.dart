import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/add_task_dialog.dart';
import 'task_edit_page.dart';

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
        if (widget.categoryId == 'General') {
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
                ).then((result) {
                  if (result == true) {
                    _loadData(); // Refresh data if a task was created
                  }
                });
              },
            )
          else if (widget.title != 'Completed')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(
                    categoryId: (widget.type == 'category' && widget.categoryId != 'General') ? widget.categoryId : null,
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadData(); // Refresh data if a task was created
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading tasks...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _todos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 48, color: widget.color),
                          const SizedBox(height: 16),
                          Text('No tasks in ${widget.title}'),
                        ],
                      ),
                    )
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
          ).then((result) {
            if (result == true) {
              _loadData(); // Refresh data if a task was created
            }
          });
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildTaskItem(BuildContext context, Todo todo) {
    // Check if this task is being optimistically shown as completed
    final isOptimisticallyCompleted = _optimisticallyCompletedIds.contains(todo.id);
    final showAsCompleted = todo.completed || isOptimisticallyCompleted;
    
    // Check if we're in a view that should only show time (not full date)
    final bool showTimeOnly = widget.type == 'chronological' || 
                             widget.title == 'Chronological View' ||
                             widget.title == 'Today';
    
    // Format date in a human-readable way with YYYY-MM-DD HH:MM format
    String formatDateTime(DateTime dateTime) {
      final formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$formattedDate $formattedTime';
    }
    
    // Format just the time portion
    String formatTimeOnly(DateTime dateTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    
    // Parse color string to Color object safely
    Color parseColor(String colorString) {
      try {
        // Handle hex color format with # prefix
        if (colorString.startsWith('#')) {
          return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
        } 
        // Handle hex color format without # prefix
        else {
          return Color(int.parse(colorString, radix: 16));
        }
      } catch (e) {
        // Default color if parsing fails
        return Colors.grey;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskEditPage(task: todo),
              ),
            ).then((updated) {
              if (updated == true) {
                _loadData(); // Refresh data if task was updated
              }
            });
          },
          child: ListTile(
            leading: InkWell(
              onTap: () {
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
              child: Icon(
                showAsCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: showAsCompleted ? Colors.green : widget.color,
                size: 26,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: showAsCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (if any)
                if (todo.description != null && todo.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _abbreviateText(todo.description!, 50),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                // Location (if any) - Simpler display like in Completed Tasks view
                if (todo.location != null && todo.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          todo.location!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Due date or Completion time
                if (showAsCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Completed at ${formatDateTime(todo.updatedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (todo.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      showTimeOnly 
                          ? 'Time: ${formatTimeOnly(todo.dueDate!)}'
                          : formatDateTime(todo.dueDate!),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                
                // Category tag at the bottom
                if (todo.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: parseColor(todo.category!.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      todo.category!.name.toLowerCase(),
                      style: TextStyle(
                        color: parseColor(todo.category!.color),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<TodoProvider>().deleteTodo(todo.id).then((_) {
                  _loadData();
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  String _abbreviateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
} 