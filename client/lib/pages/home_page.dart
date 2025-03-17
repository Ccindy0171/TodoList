// this is the home page of the app
import 'package:flutter/material.dart';
import '../widgets/stats_grid.dart';
import '../widgets/todo_lists.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatsGrid(),
              const SizedBox(height: 24),
              const Text(
                '我的列表',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const TodoLists(),
            ],
          ),
        ),
      ),
    );
  }
} 