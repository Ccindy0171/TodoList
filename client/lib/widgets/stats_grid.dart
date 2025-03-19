import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../pages/today_tasks_page.dart';
import '../providers/todo_provider.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    print('? StatsGrid: build() - Building widget');
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        print('? StatsGrid: Consumer rebuilding with provider hashCode: ${todoProvider.hashCode}');
        
        // Cache the futures to avoid unnecessary rebuilds
        final todayTodosFuture = todoProvider.getTodayTodos();
        final upcomingTodosFuture = todoProvider.getUpcomingTodos();
        final allTodosFuture = todoProvider.getAllTodos();
        final completedTodosFuture = todoProvider.getCompletedTodayTodos();
        
        return FutureBuilder(
          // Use a stable key that won't change with every provider update
          key: const ValueKey('stats_grid'),
          future: Future.wait([
            todayTodosFuture,
            upcomingTodosFuture,
            allTodosFuture,
            completedTodosFuture,
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('? StatsGrid: Waiting for data...');
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('? StatsGrid: Error loading data - ${snapshot.error}');
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final todayTodos = snapshot.data![0];
            final upcomingTodos = snapshot.data![1];
            final allTodos = snapshot.data![2];
            final completedTodos = snapshot.data![3];
            
            print('? StatsGrid: Data loaded - Today: ${todayTodos.length}, Planned: ${upcomingTodos.length}, All: ${allTodos.length}, Completed: ${completedTodos.length}');

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
                  type: 'stat',
                ),
                StatCard(
                  title: 'Planned',
                  count: upcomingTodos.length.toString(),
                  icon: Icons.calendar_month,
                  color: Colors.red,
                  type: 'stat',
                ),
                StatCard(
                  title: 'All',
                  count: allTodos.length.toString(),
                  icon: Icons.folder,
                  color: Colors.black87,
                  type: 'stat',
                ),
                StatCard(
                  title: 'Completed',
                  count: completedTodos.length.toString(),
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  type: 'stat',
                ),
              ],
            );
          },
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
  final String type;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.type,
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
                    type: type,
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