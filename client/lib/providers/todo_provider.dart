import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/graphql_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoProvider with ChangeNotifier {
  final GraphQLService _graphQLService;
  bool _isLoading = false;
  String? _error;
  
  // Cache for todo lists to prevent repeated network requests
  List<Todo>? _cachedTodayTodos;
  List<Todo>? _cachedUpcomingTodos;
  List<Todo>? _cachedAllTodos;
  List<Todo>? _cachedCompletedTodayTodos;
  List<Todo>? _cachedGeneralTodos;
  List<Todo>? _cachedRecentlyUpdatedTasks;
  List<Todo>? _cachedAllCompletedTodos;
  
  // Status tracking for connectivity
  bool _hasConnectivity = true;
  int _failedAttempts = 0;
  bool _needsServerConfig = false;

  // Cache for todos by category
  final Map<String, List<Todo>> _cachedTodosByCategory = {};

  // Constructor that accepts the GraphQLService instance
  TodoProvider([GraphQLService? graphQLService]) : _graphQLService = graphQLService ?? GraphQLService() {
    print('? TodoProvider: Initialized with server URL: ${_graphQLService.serverUrl}');
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters for cached data
  List<Todo>? get getCachedTodayTodos => _cachedTodayTodos;
  List<Todo>? get getCachedUpcomingTodos => _cachedUpcomingTodos;
  List<Todo>? get getCachedAllTodos => _cachedAllTodos;
  List<Todo>? get getCachedCompletedTodayTodos => _cachedCompletedTodayTodos;
  List<Todo>? get getCachedGeneralTodos => _cachedGeneralTodos;
  List<Todo>? get getCachedRecentlyUpdatedTasks => _cachedRecentlyUpdatedTasks;
  List<Todo>? get getCachedAllCompletedTodos => _cachedAllCompletedTodos;
  
  // Connectivity status
  bool get hasConnectivity => _hasConnectivity;
  int get failedAttempts => _failedAttempts;
  bool get needsServerConfig => _needsServerConfig;
  
  // Get cached todos for a specific category
  List<Todo>? getCategoryTodos(String categoryId) {
    if (categoryId == 'General') {
      return _cachedGeneralTodos;
    }
    
    if (_cachedAllTodos != null) {
      return _cachedAllTodos!.where((todo) {
        bool isMatch = false;
        // Check if this category is in the todo's categories array
        if (todo.categories != null && todo.categories!.isNotEmpty) {
          for (final categoryInList in todo.categories!) {
            if (categoryInList.id == categoryId) {
              isMatch = true;
              break;
            }
          }
        }
        // If not found in the list, or if the list is empty, check the legacy single category field
        if (!isMatch && todo.category != null && todo.category!.id == categoryId) {
          isMatch = true;
        }
        return isMatch;
      }).toList();
    }
    
    return null;
  }

  // Get completed todos for a specific category
  List<Todo>? getCompletedCategoryTodos(String categoryId) {
    if (_cachedAllCompletedTodos != null) {
      if (categoryId == 'General') {
        return _cachedAllCompletedTodos!.where((todo) => 
          todo.category == null && (todo.categories == null || todo.categories!.isEmpty)
        ).toList();
      } else {
        return _cachedAllCompletedTodos!.where((todo) {
          bool isMatch = false;
          // Check if this category is in the todo's categories array
          if (todo.categories != null && todo.categories!.isNotEmpty) {
            for (final categoryInList in todo.categories!) {
              if (categoryInList.id == categoryId) {
                isMatch = true;
                break;
              }
            }
          }
          // If not found in the list, or if the list is empty, check the legacy single category field
          if (!isMatch && todo.category != null && todo.category!.id == categoryId) {
            isMatch = true;
          }
          return isMatch;
        }).toList();
      }
    }
    
    return null;
  }

  Future<List<Todo>> getTodayTodos() async {
    print('? TodoProvider: getTodayTodos() - Fetching non-completed tasks for today');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todos = await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
      startDate: startOfDay,
      endDate: endOfDay,
    );
    
    // Update cache
    _cachedTodayTodos = todos;
    
    return todos;
  }

  Future<List<Todo>> getUpcomingTodos() async {
    print('? TodoProvider: getUpcomingTodos() - Fetching non-completed future tasks');
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    
    final todos = await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
      startDate: startOfTomorrow,
    );
    
    // Update cache
    _cachedUpcomingTodos = todos;
    
    return todos;
  }

  Future<List<Todo>> getAllTodos() async {
    print('? TodoProvider: getAllTodos() - Fetching all non-completed tasks');
    final todos = await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
    );
    
    // Update cache
    _cachedAllTodos = todos;
    
    return todos;
  }

  Future<List<Todo>> getCompletedTodayTodos() async {
    print('? TodoProvider: getCompletedTodayTodos() - Fetching completed tasks for today');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final todos = await _graphQLService.getTodos(
      completed: true, // Explicitly request completed tasks
      updatedAfter  : startOfDay,
      updatedBefore: endOfDay,
    );
    
    // Update cache
    _cachedCompletedTodayTodos = todos;
    
    return todos;
  }

  Future<List<Todo>> getGeneralTodos() async {
    print('? TodoProvider: getGeneralTodos() - Fetching non-completed tasks with no category');
    try {
      final todos = await _graphQLService.getTodos(
        completed: false,
        categoryId: 'none', // Special value to indicate no category
      );
      print('? TodoProvider: getGeneralTodos() - Successfully fetched ${todos.length} tasks');
      
      // Update cache
      _cachedGeneralTodos = todos;
      
      return todos;
    } catch (e) {
      print('? TodoProvider: getGeneralTodos() - Error: $e');
      // Return empty list on error instead of propagating exception
      return [];
    }
  }

  Future<List<Todo>> getReminders() async {
    print('? TodoProvider: getReminders() - Fetching non-completed reminder tasks');
    return await _graphQLService.getTodos(
      completed: false,
      priority: 1, // Assuming reminders have priority 1
    );
  }

  Future<List<Todo>> getFuturePlans() async {
    print('? TodoProvider: getFuturePlans() - Fetching non-completed future plan tasks');
    return await _graphQLService.getTodos(
      completed: false,
      priority: 2, // Assuming future plans have priority 2
    );
  }

  Future<List<Todo>> getTodosByCategory(String categoryId) async {
    print('? Getting todos for category: $categoryId');
    
    try {
      final bool isGeneral = categoryId == 'General';
      
      // For General category, fetch tasks without a category
      // For specific categories, use categoryIds to find all matching tasks
      final result = await _graphQLService.getTodos(
        noCategoryOnly: isGeneral,
        categoryIds: isGeneral ? null : [categoryId],
      );
      
      print('? Successfully fetched ${result.length} todos for category: $categoryId');
      
      _cachedTodosByCategory[categoryId] = result;
      
      return result;
    } catch (e) {
      print('? Error fetching todos by category $categoryId: $e');
      return [];
    }
  }

  Future<void> createTodo({
    required String title,
    String? description,
    String? categoryId, // Keep for backward compatibility
    List<String>? categoryIds, // New parameter for multiple categories
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    print('? TodoProvider: createTodo() - START with title: "$title"');
    print('? TodoProvider: createTodo() - categoryId: $categoryId, categoryIds: $categoryIds');
    print('? TodoProvider: createTodo() - dueDate: $dueDate');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Handle categoryIds properly
      List<String>? finalCategoryIds = categoryIds;
      if (finalCategoryIds == null && categoryId != null && categoryId.isNotEmpty && categoryId != 'General') {
        // For backward compatibility - convert single categoryId to list
        finalCategoryIds = [categoryId];
        print('? TodoProvider: Converting single categoryId to list: $finalCategoryIds');
      }
      
      // Create the todo with multiple categories
      print('? TodoProvider: Calling GraphQL service with categoryIds: $finalCategoryIds');
      final todo = await _graphQLService.createTodo(
        title: title,
        description: description,
        categoryIds: finalCategoryIds,
        dueDate: dueDate,
        location: location,
        priority: priority,
        tags: tags,
      );
      
      _error = null;
      print('? TodoProvider: Task created successfully: ${todo.id}');
      print('? TodoProvider: New todo: ${todo.title}, category: ${todo.category?.name ?? "none"}');
      
      // Selectively refresh the relevant data, not everything
      if (todo.dueDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        if (todo.dueDate!.isAfter(today) && todo.dueDate!.isBefore(tomorrow)) {
          await getTodayTodos(); // Refresh today's todos
        } else if (todo.dueDate!.isAfter(tomorrow)) {
          await getUpcomingTodos(); // Refresh upcoming todos
        }
      }
      
      // If the todo has a category, refresh that category's todos
      if (todo.category != null) {
        await getTodosByCategory(todo.category!.id);
      } else {
        await getGeneralTodos(); // Refresh general todos
      }
      
      await getAllTodos(); // Always refresh the all todos list
      
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: createTodo() ERROR: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('? TodoProvider: createTodo() COMPLETE - UI update triggered');
    }
  }

  Future<void> toggleTodo(String id) async {
    print('? TodoProvider: toggleTodo(id: $id) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Perform the server call
      final todo = await _graphQLService.toggleTodo(id);
      _error = null;
      print('? TodoProvider: toggleTodo() - Task toggled successfully. Completed: ${todo.completed}');
      
      // Refresh specific data based on the toggled todo
      if (todo.completed) {
        await getCompletedTodayTodos(); // Refresh completed todos
      }
      
      // Refresh the appropriate category
      if (todo.category != null) {
        await getTodosByCategory(todo.category!.id);
      } else {
        await getGeneralTodos();
      }
      
      // Refresh today todos if due date is today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (todo.dueDate != null && 
          todo.dueDate!.isAfter(today) && 
          todo.dueDate!.isBefore(tomorrow)) {
        await getTodayTodos();
      }
      
      await getAllTodos(); // Always refresh all todos
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: toggleTodo() - Error: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    print('?? TodoProvider: deleteTodo(id: $id) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First get the todo to know which lists to refresh
      final todos = await getAllTodos();
      final todoToDelete = todos.firstWhere(
        (todo) => todo.id == id,
        orElse: () => Todo(
          id: id,
          title: '',
          completed: false,
          updatedAt: DateTime.now(),
        ),
      );
      
      await _graphQLService.deleteTodo(id);
      _error = null;
      print('? TodoProvider: deleteTodo() - Task deleted successfully');
      
      // Refresh specific data based on the deleted todo
      if (todoToDelete.category != null) {
        await getTodosByCategory(todoToDelete.category!.id);
      } else {
        await getGeneralTodos();
      }
      
      // Refresh today todos if due date was today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      if (todoToDelete.dueDate != null && 
          todoToDelete.dueDate!.isAfter(today) && 
          todoToDelete.dueDate!.isBefore(tomorrow)) {
        await getTodayTodos();
      } else if (todoToDelete.dueDate != null && 
                todoToDelete.dueDate!.isAfter(tomorrow)) {
        await getUpcomingTodos();
      }
      
      await getAllTodos(); // Always refresh all todos
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: deleteTodo() - Error: $_error');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncWithCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('lastSync') ?? 0;
    
    await prefs.setInt('lastSync', DateTime.now().millisecondsSinceEpoch);
  }

  // Helper method to determine if the app has server configuration ready
  bool get hasValidServerConfiguration {
    // Valid configurations:
    // 1. Using a non-default server
    // 2. Using the default server with explicit permission
    return !_graphQLService.isUsingDefaultUrl || _graphQLService.allowDefaultUrl;
  }

  Future<void> loadTodos({bool forceDefaultConnection = false}) async {
    print('? TodoProvider: loadTodos(forceDefault: $forceDefaultConnection) - Started refreshing all todo lists');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // If forceDefaultConnection is true, remember this preference for future refreshes
      if (forceDefaultConnection) {
        await _graphQLService.setAllowDefaultUrl(true);
        print('? TodoProvider: Remembered preference to use default URL for future refreshes');
      }
      
      print('? TodoProvider: Using server URL: ${_graphQLService.serverUrl}');
      
      // Check if we need to show configuration screen
      if (!hasValidServerConfiguration && !forceDefaultConnection) {
        _needsServerConfig = true;
        _error = 'Server URL not configured';
        print('? TodoProvider: loadTodos() - No valid server configuration, configuration needed');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Reset server config flag
      _needsServerConfig = false;
      
      // Check connectivity first
      try {
        final hasConnectivity = await _graphQLService.checkConnectivity();
        print('? TodoProvider: Connectivity check: ${hasConnectivity ? 'SUCCESS' : 'FAILED'}');
        
        if (!hasConnectivity) {
          _failedAttempts++;
          _hasConnectivity = false;
          
          // Provide a more detailed error message
          String serverType = _graphQLService.isUsingDefaultUrl ? "default" : "configured";
          String serverUrl = _graphQLService.serverUrl;
          _error = 'Cannot connect to $serverType server at $serverUrl. Server might be offline or unreachable.';
          
          print('? TodoProvider: loadTodos() - Connectivity check failed ($_failedAttempts attempts)');
          
          // If we have cached data, we can still show it
          if (_cachedAllTodos != null && _cachedAllTodos!.isNotEmpty) {
            print('? TodoProvider: Using cached data due to connectivity issues');
            _isLoading = false;
            notifyListeners();
            return;
          }
          
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        // Detailed error for connectivity failures
        _failedAttempts++;
        _hasConnectivity = false;
        
        // Extract useful parts from the exception message
        String errorMsg = e.toString();
        String serverUrl = _graphQLService.serverUrl;
        
        if (errorMsg.contains('SocketException')) {
          _error = 'Network error connecting to $serverUrl: Host unreachable or connection refused';
        } else if (errorMsg.contains('TimeoutException')) {
          _error = 'Connection timed out when connecting to $serverUrl. Server might be running but responding slowly.';
        } else if (errorMsg.contains('HandshakeException')) {
          _error = 'SSL/TLS handshake failed with $serverUrl. Server might have invalid certificates.';
        } else {
          _error = 'Connection error with server $serverUrl: $errorMsg';
        }
        
        print('? TodoProvider: loadTodos() - Connection error: $_error');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Reset connectivity status on successful connection
      _hasConnectivity = true;
      _failedAttempts = 0;
      
      // Load all data in parallel for maximum efficiency
      print('? TodoProvider: Starting parallel data load...');
      try {
        final futures = await Future.wait([
          getTodayTodos().catchError((e) {
            print('? TodoProvider: Error loading today todos: $e');
            return <Todo>[];
          }),
          getUpcomingTodos().catchError((e) {
            print('? TodoProvider: Error loading upcoming todos: $e');
            return <Todo>[];
          }),
          getAllTodos().catchError((e) {
            print('? TodoProvider: Error loading all todos: $e');
            return <Todo>[];
          }),
          getCompletedTodayTodos().catchError((e) {
            print('? TodoProvider: Error loading completed todos: $e');
            return <Todo>[];
          }),
          getGeneralTodos().catchError((e) {
            print('? TodoProvider: Error loading general todos: $e');
            return <Todo>[];
          }),
          getRecentlyUpdatedTasks().catchError((e) {
            print('? TodoProvider: Error loading recently updated tasks: $e');
            return <Todo>[];
          }),
          getAllCompletedTodos().catchError((e) {
            print('? TodoProvider: Error loading all completed todos: $e');
            return <Todo>[];
          }),
        ], eagerError: false);
        
        print('? TodoProvider: Parallel data load completed with ${futures.length} results');
        _error = null;
      } catch (e) {
        print('? TodoProvider: Error in parallel data load: $e');
        
        // Try to provide more helpful error messages for GraphQL errors
        String errorMsg = e.toString();
        if (errorMsg.contains('GraphQLError')) {
          _error = 'GraphQL server error: ${errorMsg.replaceAll('Exception: ', '')}';
        } else {
          _error = 'Error loading todos: ${errorMsg.replaceAll('Exception: ', '')}';
        }
      }
      
      // If we got here without errors, consider it a success even if some individual queries failed
      if (_error == null) {
        print('? TodoProvider: loadTodos() - All or some todo lists refreshed successfully');
      }
    } catch (e) {
      // Catch-all handler for any other errors
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      _error = 'Unexpected error: $errorMsg';
      print('? TodoProvider: loadTodos() - Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('? TodoProvider: notifyListeners() - UI update triggered');
    }
  }
  
  // Retry loading data with exponential backoff
  Future<void> retryLoadTodos() async {
    if (_isLoading) return; // Prevent multiple retries at once
    
    print('? TodoProvider: retryLoadTodos() - Retrying data load');
    await loadTodos();
  }

  Future<List<Todo>> getTasksUpdatedBetween(DateTime start, DateTime end) async {
    print('? TodoProvider: getTasksUpdatedBetween(start: $start, end: $end) - Fetching tasks updated in date range');
    try {
      final todos = await _graphQLService.getTodos(
        updatedAfter: start,
        updatedBefore: end, 
      );
      print('? TodoProvider: getTasksUpdatedBetween() - Successfully fetched ${todos.length} tasks');
      return todos;
    } catch (e) {
      print('? TodoProvider: getTasksUpdatedBetween() - Error: $e');
      return [];
    }
  }

  Future<List<Todo>> getRecentlyUpdatedTasks() async {
    print('? TodoProvider: getRecentlyUpdatedTasks() - Fetching recently updated tasks');
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    try {
      final todos = await _graphQLService.getTodos(
        updatedAfter: oneDayAgo,
      );
      print('? TodoProvider: getRecentlyUpdatedTasks() - Successfully fetched ${todos.length} tasks');
      
      // Update cache
      _cachedRecentlyUpdatedTasks = todos;
      
      return todos;
    } catch (e) {
      print('? TodoProvider: getRecentlyUpdatedTasks() - Error: $e');
      return [];
    }
  }

  Future<List<Todo>> getAllCompletedTodos() async {
    print('? TodoProvider: getAllCompletedTodos() - Fetching all completed tasks');
    final todos = await _graphQLService.getTodos(
      completed: true, // Explicitly request completed tasks
    );
    
    // Update cache
    _cachedAllCompletedTodos = todos;
    
    return todos;
  }

  Future<List<Todo>> getCompletedTodosByDateRange(DateTime start, DateTime end) async {
    print('? TodoProvider: getCompletedTodosByDateRange() - Fetching completed tasks between $start and $end');
    return await _graphQLService.getTodos(
      completed: true,
      startDate: start,
      endDate: end,
    );
  }

  Future<List<Todo>> getUncompletedTodosByDateRange(DateTime start, DateTime end) async {
    print('? TodoProvider: getUncompletedTodosByDateRange() - Fetching uncompleted tasks between $start and $end');
    return await _graphQLService.getTodos(
      completed: false,
      startDate: start,
      endDate: end,
    );
  }

  Future<List<Todo>> getChronologicalTodos({bool? completed}) async {
    print('? TodoProvider: getChronologicalTodos(completed: $completed) - Fetching tasks in chronological order');
    
    final todos = await _graphQLService.getTodos(
      completed: completed,
    );
    
    // Sort by due date (chronological order)
    todos.sort((a, b) => a.dueDate != null && b.dueDate != null 
        ? a.dueDate!.compareTo(b.dueDate!) 
        : 0);
        
    return todos;
  }

  Future<Todo> updateTodo({
    required String id,
    required String title,
    String? description,
    List<String>? categoryIds,
    required DateTime dueDate,
    String? location,
    int? priority,
    List<String>? tags,
    bool? completed,
  }) async {
    print('? TodoProvider: updateTodo(id: $id, title: $title, categoryIds: $categoryIds)');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use categoryIds directly instead of just the first one
      print('? TodoProvider: Using categoryIds: $categoryIds for update');
      
      final todo = await _graphQLService.updateTodo(
        id: id,
        title: title,
        description: description,
        categoryIds: categoryIds,
        dueDate: dueDate,
        location: location,
        priority: priority,
        tags: tags,
        completed: completed,
      );
      
      // Reset error and loading state
      _error = null;
      _isLoading = false;
      
      // Refresh all lists to ensure UI consistency
      await loadTodos();
      
      notifyListeners();
      
      return todo;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e; // Rethrow to allow handling in UI
    }
  }

  // Clear any error state
  void clearError() {
    _error = null;
    _needsServerConfig = false;
    notifyListeners();
    print('? TodoProvider: clearError() - Error state has been reset');
  }
}