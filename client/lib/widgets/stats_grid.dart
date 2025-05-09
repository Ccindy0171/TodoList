import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../pages/completed_tasks_page.dart';
import '../providers/todo_provider.dart';
import '../pages/date_range_filter_page.dart';
import '../pages/chronological_tasks_page.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

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
                futureBuilder: (context) => context.read<TodoProvider>().getTodayTodos(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Planned',
                Icons.calendar_month,
                Colors.orange,
                futureBuilder: (context) => context.read<TodoProvider>().getUpcomingTodos(),
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
                futureBuilder: (context) => context.read<TodoProvider>().getAllTodos(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Completed',
                Icons.check_circle,
                Colors.purple,
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
    Function(BuildContext)? futureBuilder,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (futureBuilder != null) {
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
          );
        }
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
            if (futureBuilder != null)
              FutureBuilder<List<dynamic>>(
                future: futureBuilder(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
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
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return const Text(
                      'Error',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  
                  final count = snapshot.data?.length ?? 0;
                  return Text(
                    '$count tasks',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
} 