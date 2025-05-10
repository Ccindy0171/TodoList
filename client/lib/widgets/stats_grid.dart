import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/task_detail_page.dart';
import '../pages/completed_tasks_page.dart';
import '../providers/todo_provider.dart';
import '../pages/date_range_filter_page.dart';
import '../pages/chronological_tasks_page.dart';
import '../models/todo.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final isLoading = todoProvider.isLoading;
        final error = todoProvider.error;
        final hasConnectivity = todoProvider.hasConnectivity;
        
        // Show error state with retry button if we have connectivity issues
        if (!hasConnectivity || error != null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      error ?? 'Cannot connect to server',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => todoProvider.retryLoadTodos(),
                      icon: Icon(Icons.refresh),
                      label: Text('Retry Connection'),
                    ),
                    if (todoProvider.getCachedAllTodos != null && 
                        todoProvider.getCachedAllTodos!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Showing cached data',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Still show grid with cached data if available
              if (todoProvider.getCachedAllTodos != null && 
                  todoProvider.getCachedAllTodos!.isNotEmpty) ...[
                _buildStatsGridWithCachedData(todoProvider),
              ],
            ],
          );
        }
        
        // Get counts from cached data
        final todayCount = todoProvider.getCachedTodayTodos?.length ?? 0;
        final plannedCount = todoProvider.getCachedUpcomingTodos?.length ?? 0;
        final allCount = todoProvider.getCachedAllTodos?.length ?? 0;
        final completedCount = todoProvider.getCachedAllCompletedTodos?.length ?? 0;
        
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
                    count: todayCount,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Planned',
                    Icons.calendar_month,
                    Colors.orange,
                    count: plannedCount,
                    isLoading: isLoading,
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
                    count: allCount,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Completed',
                    Icons.check_circle,
                    Colors.purple,
                    count: completedCount,
                    isLoading: isLoading,
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
    bool isCached = false,
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
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasCounter) ...[
              const SizedBox(height: 8),
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  count != null ? '$count ${count == 1 ? 'task' : 'tasks'}' : '0 tasks',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Build stats grid with cached data (for offline mode)
  Widget _buildStatsGridWithCachedData(TodoProvider todoProvider) {
    // Get counts from cached data
    final todayCount = todoProvider.getCachedTodayTodos?.length ?? 0;
    final plannedCount = todoProvider.getCachedUpcomingTodos?.length ?? 0;
    final allCount = todoProvider.getCachedAllTodos?.length ?? 0;
    final completedCount = todoProvider.getCachedAllCompletedTodos?.length ?? 0;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCardCached(
                'Today',
                Icons.today,
                Colors.blue,
                count: todayCount,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCardCached(
                'Planned',
                Icons.calendar_month,
                Colors.orange,
                count: plannedCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCardCached(
                'All',
                Icons.list_alt,
                Colors.green,
                count: allCount,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCardCached(
                'Completed',
                Icons.check_circle,
                Colors.purple,
                count: completedCount,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // A simplified version of stat card for cached/offline mode
  Widget _buildStatCardCached(
    String title,
    IconData icon,
    Color color, {
    int? count,
    bool hasCounter = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                '(Cached)',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasCounter) ...[
            const SizedBox(height: 8),
            Text(
              count != null ? '$count ${count == 1 ? 'task' : 'tasks'}' : '0 tasks',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 