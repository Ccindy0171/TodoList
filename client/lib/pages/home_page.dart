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
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatsGrid(),
              SizedBox(height: 24),
              Text(
                'My Lists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TodoLists(),
            ],
          ),
        ),
      ),
    );
  }
} 