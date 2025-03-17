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
          title: const Text('��������'),
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
                  title: '��������',
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
          title: const Text('δ���ƻ�'),
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
                  title: 'δ���ƻ�',
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