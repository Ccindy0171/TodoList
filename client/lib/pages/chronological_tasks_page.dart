import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';
import 'task_edit_page.dart';
import '../l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(localizations.timeline),
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChronologicalTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('${localizations.error}: $_error'))
                : _tasks.isEmpty
                    ? Center(child: Text(localizations.noTodos, style: theme.textTheme.bodyLarge))
                    : _buildGroupedTaskList(),
      ),
    );
  }

  Widget _buildGroupedTaskList() {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
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
          dateHeader = localizations.today;
        } else if (date.year == tomorrow.year && 
                  date.month == tomorrow.month && 
                  date.day == tomorrow.day) {
          dateHeader = localizations.upcoming;
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
                color: isPastDate 
                  ? theme.colorScheme.errorContainer.withOpacity(0.3)
                  : theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dateHeader,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPastDate 
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
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
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    // Color parsing helper
    Color parseColor(String colorString) {
      try {
        if (colorString.startsWith('#')) {
          return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
        } else {
          return Color(int.parse(colorString, radix: 16));
        }
      } catch (e) {
        print('Error parsing color: $colorString, Error: $e');
        return Colors.grey;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskEditPage(task: todo),
            ),
          ).then((updated) {
            if (updated == true) {
              _loadChronologicalTasks();
            }
          });
        },
        leading: IconButton(
          icon: Icon(
            todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.completed ? theme.colorScheme.primary : theme.colorScheme.secondary,
          ),
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              _loadChronologicalTasks();
            });
          },
        ),
        title: Text(
          todo.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed
              ? theme.textTheme.titleMedium?.color?.withOpacity(0.7)
              : theme.textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _abbreviateText(todo.description!, 50),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            if (todo.location != null && todo.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: theme.iconTheme.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        todo.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (todo.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                child: Text(
                  'Time: ${timeFormat.format(todo.dueDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            // Display all categories using getAllCategories()
            Builder(
              builder: (context) {
                final allCategories = todo.getAllCategories();
                if (allCategories.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: allCategories.map((cat) {
                        final categoryColor = parseColor(cat.color);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cat.name.toLowerCase(),
                            style: TextStyle(
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
                return const SizedBox.shrink();
              }
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: theme.iconTheme.color?.withOpacity(0.7),
          tooltip: localizations.delete,
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id).then((_) {
              _loadChronologicalTasks();
            });
          },
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