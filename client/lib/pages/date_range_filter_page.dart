import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';
import 'task_edit_page.dart';
import '../l10n/app_localizations.dart';

class DateRangeFilterPage extends StatefulWidget {
  const DateRangeFilterPage({super.key});

  @override
  State<DateRangeFilterPage> createState() => _DateRangeFilterPageState();
}

class _DateRangeFilterPageState extends State<DateRangeFilterPage> {
  List<Todo> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _showCompletedTasks = false;

  @override
  void initState() {
    super.initState();
    _loadTasksByDateRange();
  }

  Future<void> _loadTasksByDateRange() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final todoProvider = context.read<TodoProvider>();
      List<Todo> tasks;
      
      if (_showCompletedTasks) {
        tasks = await todoProvider.getCompletedTodosByDateRange(
          _selectedDateRange.start,
          _selectedDateRange.end.add(const Duration(days: 1)), // Include end date
        );
      } else {
        tasks = await todoProvider.getUncompletedTodosByDateRange(
          _selectedDateRange.start,
          _selectedDateRange.end.add(const Duration(days: 1)), // Include end date
        );
      }
      
      // Sort tasks by due date (chronological order)
      tasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      
      setState(() {
        _filteredTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadTasksByDateRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(localizations.dueDate),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(localizations.edit),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Text(localizations.completed, style: theme.textTheme.bodyMedium),
                const SizedBox(width: 8),
                Switch(
                  value: _showCompletedTasks,
                  onChanged: (value) {
                    setState(() {
                      _showCompletedTasks = value;
                    });
                    _loadTasksByDateRange();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('${localizations.error}: $_error'))
                    : _filteredTasks.isEmpty
                        ? Center(
                            child: Text(
                              _showCompletedTasks
                                  ? 'No completed tasks in this date range'
                                  : 'No pending tasks in this date range',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskItem(_filteredTasks[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Todo todo) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
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
              _loadTasksByDateRange();
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
              _loadTasksByDateRange();
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
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Text(
                'Due: ${todo.dueDate != null ? dateFormat.format(todo.dueDate!) : "No date"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: todo.dueDate != null && todo.dueDate!.isBefore(DateTime.now()) && !todo.completed
                      ? theme.colorScheme.error
                      : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
          icon: const Icon(Icons.delete_outline),
          color: theme.iconTheme.color?.withOpacity(0.7),
          tooltip: localizations.delete,
          onPressed: () {
            context.read<TodoProvider>().deleteTodo(todo.id).then((_) {
              _loadTasksByDateRange();
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Today'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    _selectedDateRange = DateTimeRange(
                      start: today,
                      end: today,
                    );
                  });
                  _loadTasksByDateRange();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('This week'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
                    final lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
                    _selectedDateRange = DateTimeRange(
                      start: firstDayOfWeek,
                      end: lastDayOfWeek,
                    );
                  });
                  _loadTasksByDateRange();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_month),
                title: const Text('This month'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    final now = DateTime.now();
                    final firstDayOfMonth = DateTime(now.year, now.month, 1);
                    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
                    _selectedDateRange = DateTimeRange(
                      start: firstDayOfMonth,
                      end: lastDayOfMonth,
                    );
                  });
                  _loadTasksByDateRange();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort by date (ascending)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredTasks.sort((a, b) => a.dueDate != null && b.dueDate != null 
                        ? a.dueDate!.compareTo(b.dueDate!) 
                        : 0);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort by date (descending)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filteredTasks.sort((a, b) => a.dueDate != null && b.dueDate != null 
                        ? b.dueDate!.compareTo(a.dueDate!) 
                        : 0);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
} 