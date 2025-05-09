import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Completed Tasks'),
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
                ? Center(child: Text('Error: $_error'))
                : _completedTasks.isEmpty
                    ? const Center(child: Text('No completed tasks yet'))
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          Icons.check_circle,
          color: Colors.green,
        ),
        title: Text(
          todo.title,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
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
            Text(
              'Completed at ${todo.updatedAt.hour.toString().padLeft(2, '0')}:${todo.updatedAt.minute.toString().padLeft(2, '0')} on ${todo.updatedAt.day.toString().padLeft(2, '0')}/${todo.updatedAt.month.toString().padLeft(2, '0')}/${todo.updatedAt.year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
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
          icon: const Icon(Icons.undo),
          onPressed: () {
            context.read<TodoProvider>().toggleTodo(todo.id).then((_) {
              _loadCompletedTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task marked as incomplete')),
              );
            });
          },
        ),
      ),
    );
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