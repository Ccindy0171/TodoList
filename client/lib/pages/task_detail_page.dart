import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../widgets/add_task_dialog.dart';
import 'task_edit_page.dart';
import '../l10n/app_localizations.dart';

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
  bool _isFirstLoad = true;
  
  // List of temporarily completed todos (for optimistic UI updates)
  Set<String> _optimisticallyCompletedIds = {};

  @override
  void initState() {
    super.initState();
    print('ℹ️ TaskDetailPage: initState() - Initializing for "${widget.title}"');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data here, where context (and localizations) are available
    // Use a flag to ensure it only runs once initially
    if (_isFirstLoad) {
      print('ℹ️ TaskDetailPage: didChangeDependencies() - First load for "${widget.title}"');
      _loadData();
      _isFirstLoad = false;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    print('ℹ️ TaskDetailPage: _loadData() - Loading data for "${widget.title}"');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final localizations = AppLocalizations.of(context);
      List<Todo> todos;
      
      if (widget.type == 'stat') {
        if (widget.title == localizations.today) {
          todos = await context.read<TodoProvider>().getTodayTodos();
        } else if (widget.title == localizations.upcoming) {
          todos = await context.read<TodoProvider>().getUpcomingTodos();
        } else if (widget.title == localizations.completed) {
          todos = await context.read<TodoProvider>().getCompletedTodayTodos();
        } else if (widget.title == localizations.all) {
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
        if (widget.categoryId == localizations.general) {
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
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context); // Get theme
    
    return Scaffold(
      // Remove hardcoded background color, let theme handle it
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // Make AppBar background consistent with theme's scaffold background
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface, // Ensure icons/text are visible
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.title),
        actions: [
          if (widget.title == localizations.today)
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
          else if (widget.title != localizations.completed)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(
                    categoryId: (widget.type == 'category' && widget.categoryId != localizations.general) ? widget.categoryId : null,
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
                        child: Text(localizations.tryAgain),
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
                          Text('${localizations.noPrefix} ${localizations.tasks} ${localizations.inConnector} ${widget.title}'),
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
      floatingActionButton: widget.title != localizations.completed ? FloatingActionButton(
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
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context); // Get theme data
    
    // Check if this task is being optimistically shown as completed
    final isOptimisticallyCompleted = _optimisticallyCompletedIds.contains(todo.id);
    final showAsCompleted = todo.completed || isOptimisticallyCompleted;
    
    // Check if we're in a view that should only show time (not full date)
    final bool showTimeOnly = widget.type == 'chronological' || 
                             widget.title == localizations.timeline ||
                             widget.title == localizations.today;
    
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
        print('Error parsing color: $colorString, Error: $e'); // Log error
        return Colors.grey;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor, // Use theme card color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05), // Use theme shadow color
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
                // Use theme's primary color when completed, otherwise widget's color
                color: showAsCompleted ? theme.colorScheme.primary : widget.color,
                size: 26,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                todo.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: showAsCompleted ? TextDecoration.lineThrough : null,
                  // Ensure text color adapts
                  color: showAsCompleted 
                    ? theme.textTheme.bodySmall?.color 
                    : theme.textTheme.titleMedium?.color,
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Use a slightly less prominent color for description
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
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
                          // Use a secondary icon color
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          todo.location!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            // Use a slightly less prominent color
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Display all categories (Moved Up)
                Builder(
                  builder: (context) {
                    final allCategories = todo.getAllCategories();
                    if (allCategories.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 6.0), // Adjusted padding
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allCategories.map((category) {
                            final categoryColor = parseColor(category.color);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                category.name.toLowerCase(),
                                style: TextStyle(
                                  // Use category color for text, ensure sufficient contrast later if needed
                                  color: categoryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Return empty widget if no categories
                  }
                ),
                  
                // Due date or Completion time (Moved Down)
                if (showAsCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 6.0), // Adjusted padding
                    child: Text(
                      'Completed at ${formatDateTime(todo.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        // Use a subtle color
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  )
                else if (todo.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 6.0), // Adjusted padding
                    child: Text(
                      showTimeOnly 
                          ? 'Time: ${formatTimeOnly(todo.dueDate!)}'
                          : formatDateTime(todo.dueDate!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Use a slightly less prominent color for date/time
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              // Use theme icon color
              color: theme.iconTheme.color?.withOpacity(0.7),
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