import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import 'package:intl/intl.dart';
import 'task_edit_page.dart';

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
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Date Range Filter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${dateFormat.format(_selectedDateRange.start)} - ${dateFormat.format(_selectedDateRange.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Status filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Show completed tasks:'),
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
          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _filteredTasks.isEmpty
                        ? Center(
                            child: Text(
                              _showCompletedTasks
                                  ? 'No completed tasks in this date range'
                                  : 'No pending tasks in this date range',
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
              _loadTasksByDateRange(); // Refresh data if task was updated
            }
          });
        },
        leading: IconButton(
          icon: Icon(
            todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: todo.completed ? Colors.green : Colors.blue,
          ),
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              _loadTasksByDateRange();
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
                _abbreviateText(todo.description!, 50),
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            if (todo.location != null && todo.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        todo.location!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Due: ${todo.dueDate != null ? dateFormat.format(todo.dueDate!) : "No date"}',
              style: TextStyle(
                color: todo.dueDate != null && todo.dueDate!.isBefore(DateTime.now()) && !todo.completed
                    ? Colors.red
                    : Colors.grey[600],
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