import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'task_edit_page.dart';
import '../l10n/app_localizations.dart';

class CompletedTasksPage extends StatefulWidget {
  const CompletedTasksPage({super.key});

  @override
  State<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  List<Todo> _completedTasks = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Update the TodoProvider to add a method for fetching all completed tasks
      final completedTasks = await context.read<TodoProvider>().getAllCompletedTodos();
      
      if (mounted) {
        setState(() {
          _completedTasks = completedTasks;
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
        title: Text(localizations.completed),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompletedTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('${localizations.error}: $_error'))
                : _completedTasks.isEmpty
                    ? Center(child: Text(localizations.noTodos))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _completedTasks.length,
                        itemBuilder: (context, index) {
                          final todo = _completedTasks[index];
                          return _buildTaskItem(context, todo);
                        },
                      ),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Todo todo) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
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
              _loadCompletedTasks(); // Refresh data if task was updated
            }
          });
        },
        leading: Icon(
          Icons.check_circle,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          todo.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.textTheme.titleMedium?.color?.withOpacity(0.7),
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Text(
                'Completed at ${todo.updatedAt.hour.toString().padLeft(2, '0')}:${todo.updatedAt.minute.toString().padLeft(2, '0')} on ${todo.updatedAt.day.toString().padLeft(2, '0')}/${todo.updatedAt.month.toString().padLeft(2, '0')}/${todo.updatedAt.year}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ),
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
          icon: const Icon(Icons.undo),
          color: theme.iconTheme.color?.withOpacity(0.8),
          tooltip: localizations.edit,
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              _loadCompletedTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task marked as incomplete')),
              );
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

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Filter by date range'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeFilter(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort by most recent'),
                onTap: () {
                  Navigator.pop(context);
                  _sortByMostRecent();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort by oldest'),
                onTap: () {
                  Navigator.pop(context);
                  _sortByOldest();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sortByMostRecent() {
    setState(() {
      _completedTasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  void _sortByOldest() {
    setState(() {
      _completedTasks.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    });
  }

  Future<void> _showDateRangeFilter(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    
    if (picked != null) {
      _filterByDateRange(picked.start, picked.end);
    }
  }

  Future<void> _filterByDateRange(DateTime start, DateTime end) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final completedTasks = await context.read<TodoProvider>().getCompletedTodosByDateRange(
        start, 
        end.add(const Duration(days: 1)),  // Include end date by adding 1 day
      );
      
      setState(() {
        _completedTasks = completedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
} 