import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../pages/completed_tasks_page.dart';
import '../providers/todo_provider.dart';
import '../pages/date_range_filter_page.dart';
import '../pages/chronological_tasks_page.dart';
import '../models/todo.dart';

class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  Map<String, Future<List<Todo>>> _todoFutures = {};
  Map<String, int> _todoCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodoCounts();
  }

  Future<void> _loadTodoCounts() async {
    setState(() {
      _isLoading = true;
    });

    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    
    try {
      // Load all todo counts in parallel
      final todayTodos = await todoProvider.getTodayTodos();
      final upcomingTodos = await todoProvider.getUpcomingTodos();
      final allTodos = await todoProvider.getAllTodos();
      
      if (mounted) {
        setState(() {
          _todoCounts = {
            'Today': todayTodos.length,
            'Planned': upcomingTodos.length,
            'All': allTodos.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading todo counts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Today',
                Icons.today,
                Colors.blue,
                count: _todoCounts['Today'] ?? 0,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Planned',
                Icons.calendar_month,
                Colors.orange,
                count: _todoCounts['Planned'] ?? 0,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'All',
                Icons.list_alt,
                Colors.green,
                count: _todoCounts['All'] ?? 0,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Completed',
                Icons.check_circle,
                Colors.purple,
                hasCounter: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompletedTasksPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Date Range',
                Icons.date_range,
                Colors.deepOrange,
                hasCounter: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DateRangeFilterPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Timeline',
                Icons.timeline,
                Colors.teal,
                hasCounter: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChronologicalTasksPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    int? count,
    bool isLoading = false,
    bool hasCounter = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(
              title: title,
              icon: icon,
              color: color,
              type: 'stat',
            ),
          ),
        ).then((_) {
          // Refresh counts when returning
          _loadTodoCounts();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasCounter)
              isLoading
                ? const SizedBox(
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '${count ?? 0} tasks',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
} 