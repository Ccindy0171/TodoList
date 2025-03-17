import 'package:flutter/material.dart';
import '../pages/task_detail_page.dart';

class TodoLists extends StatelessWidget {
  const TodoLists({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_none, color: Colors.blue),
          title: const Text('提醒事项'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '4',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskDetailPage(
                  title: '提醒事项',
                  icon: Icons.notifications_none,
                  color: Colors.blue,
                  type: 'list',
                ),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_month, color: Colors.red),
          title: const Text('未来计划'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '2',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskDetailPage(
                  title: '未来计划',
                  icon: Icons.calendar_month,
                  color: Colors.red,
                  type: 'list',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 