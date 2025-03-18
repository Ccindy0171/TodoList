import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../pages/today_tasks_page.dart';
import '../providers/todo_provider.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final todayTodos = todoProvider.getTodayTodos();
        final upcomingTodos = todoProvider.getUpcomingTodos();
        final completedTodos = todoProvider.getCompletedTodayTodos();
        final allTodos = todoProvider.getAllTodos();

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Today',
              count: todayTodos.length.toString(),
              icon: Icons.calendar_today,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Planned',
              count: upcomingTodos.length.toString(),
              icon: Icons.list_alt,
              color: Colors.red,
            ),
            StatCard(
              title: 'All',
              count: allTodos.length.toString(),
              icon: Icons.folder,
              color: Colors.black87,
            ),
            StatCard(
              title: 'Completed',
              count: completedTodos.length.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => title == 'Today'
                ? const TodayTasksPage()
                : TaskDetailPage(
                    title: title,
                    icon: icon,
                    color: color,
                    type: 'stat',
                  ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (count.isNotEmpty)
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 