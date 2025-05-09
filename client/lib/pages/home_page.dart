// this is the home page of the app
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_grid.dart';
import '../widgets/todo_lists.dart';
import '../widgets/add_task_dialog.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../services/graphql_service.dart';
import 'server_settings_page.dart';

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
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      context.read<TodoProvider>().loadTodos(),
      context.read<CategoryProvider>().loadCategories(),
    ]);
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
    final GraphQLService graphQLService = Provider.of<GraphQLService>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ServerSettingsPage(),
                ),
              );
            },
            tooltip: 'Server Settings',
          ),
        ],
      ),
      body: Consumer2<TodoProvider, CategoryProvider>(
        builder: (context, todoProvider, categoryProvider, child) {
          if (todoProvider.isLoading || categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (todoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${todoProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ServerSettingsPage(),
                        ),
                      );
                    },
                    child: const Text('Configure Server'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Connected to: ${graphQLService.serverUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const StatsGrid(),
                const SizedBox(height: 24),
                const TodoLists(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTaskDialog(),
          ).then((result) {
            if (result == true) {
              _refreshData(); // Refresh data if a task was created
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 