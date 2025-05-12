// this is the home page of the app
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/stats_grid.dart';
import '../widgets/todo_lists.dart';
import '../widgets/add_task_dialog.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../services/graphql_service.dart';
import '../l10n/app_localizations.dart';
import 'server_settings_page.dart';
import 'search_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    print('? HomePage: initState() - Initializing');
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('? HomePage: addPostFrameCallback - Loading initial data');
      
      // Check if we need server configuration first
      final todoProvider = context.read<TodoProvider>();
      final graphQLService = Provider.of<GraphQLService>(context, listen: false);
      
      // If we don't have a valid server configuration, show settings page immediately
      if (!todoProvider.hasValidServerConfiguration) {
        print('? HomePage: No valid server configuration, showing server settings page');
        // Reset the allowDefaultUrl preference when manually configuring server
        graphQLService.setAllowDefaultUrl(false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ServerSettingsPage(),
          ),
        ).then((_) {
          // After returning from settings page, try loading data again
          _loadInitialData();
        });
      } else {
        // If we have a valid configuration, proceed with loading data
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _initialLoading = true;
    });
    
    final todoProvider = context.read<TodoProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final graphQLService = Provider.of<GraphQLService>(context, listen: false);
    
    print('? HomePage: _loadInitialData() - Using server URL: ${graphQLService.serverUrl}');
    
    // First check connectivity
    final hasConnectivity = await graphQLService.checkConnectivity();
    if (!hasConnectivity) {
      print('? HomePage: _loadInitialData() - Connectivity check failed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).cannotConnectToServer),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _initialLoading = false;
        });
      }
      return;
    }
    
    print('? HomePage: _loadInitialData() - Connectivity check succeeded');
    
    try {
      // Use separate try-catch blocks to allow partial success
      try {
        await categoryProvider.loadCategories();
        print('? HomePage: Categories loaded successfully');
      } catch (e) {
        print('? HomePage: Error loading categories: $e');
      }
      
      try {
        await todoProvider.loadTodos();
        print('? HomePage: Todos loaded successfully');
      } catch (e) {
        print('? HomePage: Error loading todos: $e');
      }
    } catch (e) {
      print('? HomePage: Unexpected error in _loadInitialData: $e');
    } finally {
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData({bool forceDefaultConnection = false}) async {
    print('? HomePage: _refreshData(forceDefault: $forceDefaultConnection) - Manual refresh triggered');
    await Future.wait([
      context.read<TodoProvider>().loadTodos(forceDefaultConnection: forceDefaultConnection),
      context.read<CategoryProvider>().loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final GraphQLService graphQLService = Provider.of<GraphQLService>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    
    // Show a full-screen loader during initial loading
    if (_initialLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                localizations.loading,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
            tooltip: localizations.search,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            tooltip: localizations.settings,
          ),
          IconButton(
            icon: const Icon(Icons.dns),
            onPressed: () {
              // Reset the allowDefaultUrl preference when manually configuring server
              Provider.of<GraphQLService>(context, listen: false).setAllowDefaultUrl(false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ServerSettingsPage(),
                ),
              ).then((_) {
                // After returning from settings page, force a full refresh with the new server settings
                setState(() {
                  _initialLoading = true;
                });
                
                // Clear error state in providers to ensure fresh start
                final todoProvider = Provider.of<TodoProvider>(context, listen: false);
                todoProvider.clearError();
                
                // Force reload data with fresh server connection
                _loadInitialData();
                
                // Print current server status for debugging
                final graphQLService = Provider.of<GraphQLService>(context, listen: false);
                print('? HomePage: Returned from settings, using server: ${graphQLService.serverUrl}');
              });
            },
            tooltip: localizations.serverSettings,
          ),
        ],
      ),
      body: Consumer2<TodoProvider, CategoryProvider>(
        builder: (context, todoProvider, categoryProvider, child) {
          // Check if server configuration is needed
          if (todoProvider.needsServerConfig) {
            return _buildServerConfigNeededView(context);
          }
          
          if (todoProvider.isLoading || categoryProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(localizations.refreshingData),
                ],
              ),
            );
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
                    '${localizations.error}: ${todoProvider.error}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      localizations.connectionError,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(localizations.tryAgain),
                        onPressed: () {
                          // Show a loading indicator to give feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(localizations.attemptingReconnect),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          
                          // Reset state to show loading indicator
                          setState(() {
                            _initialLoading = true;
                          });
                          
                          // Try loading data again
                          _loadInitialData();
                        },
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: Text(localizations.serverSettings),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ServerSettingsPage(),
                            ),
                          ).then((_) {
                            // Reload data
                            _loadInitialData();
                          });
                        },
                      ),
                    ],
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
                  '${localizations.connectedTo} ${graphQLService.serverUrl}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (graphQLService.isUsingDefaultUrl && graphQLService.allowDefaultUrl)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      localizations.usingDefaultConnection,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                if (!graphQLService.isUsingDefaultUrl)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      localizations.usingConfiguredServer,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
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
          print('? HomePage: Add task button pressed');
          showDialog(
            context: context,
            builder: (context) => const AddTaskDialog(),
          ).then((result) {
            print('? HomePage: AddTaskDialog closed with result: $result');
            if (result == true) {
              print('? HomePage: Refreshing data after successful task creation');
              // Do a full refresh after task creation
              _refreshData(); 
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Widget to show when server configuration is needed
  Widget _buildServerConfigNeededView(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.settings,
              color: Colors.blue,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              localizations.serverConfigNeeded,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.serverConfigInfo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: Text(localizations.serverConfigScan),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: Text(localizations.serverConfigManual),
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.phonelink, color: Colors.blue),
              title: Text(localizations.serverConfigDev),
              dense: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: Text(localizations.configureServer),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                // Reset the allowDefaultUrl preference when manually configuring server
                Provider.of<GraphQLService>(context, listen: false).setAllowDefaultUrl(false);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ServerSettingsPage(),
                  ),
                ).then((_) {
                  // After configuration, try loading data again
                  _loadInitialData();
                });
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.developer_mode),
              label: Text(localizations.tryDefaultConnection),
              onPressed: () {
                // Use the default connection
                _refreshData(forceDefaultConnection: true);
              },
            ),
          ],
        ),
      ),
    );
  }
} 