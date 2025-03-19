// this is the home page of the app
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_grid.dart';
import '../widgets/todo_lists.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    print('? HomePage: initState() - Initializing');
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('? HomePage: addPostFrameCallback - Loading initial data');
      context.read<TodoProvider>().loadTodos();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _refreshData() async {
    print('? HomePage: _refreshData - Manual refresh triggered');
    await Future.wait([
      context.read<TodoProvider>().loadTodos(),
      context.read<CategoryProvider>().loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    print('? HomePage: build() - Rebuilding UI');
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              children: const [
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
      ),
    );
  }
} 