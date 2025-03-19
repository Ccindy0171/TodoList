import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/graphql_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoProvider with ChangeNotifier {
  final GraphQLService _graphQLService = GraphQLService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Todo>> getTodayTodos() async {
    print('? TodoProvider: getTodayTodos() - Fetching non-completed tasks for today');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  Future<List<Todo>> getUpcomingTodos() async {
    print('? TodoProvider: getUpcomingTodos() - Fetching non-completed future tasks');
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    
    return await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
      startDate: startOfTomorrow,
    );
  }

  Future<List<Todo>> getAllTodos() async {
    print('? TodoProvider: getAllTodos() - Fetching all non-completed tasks');
    return await _graphQLService.getTodos(
      completed: false, // Explicitly request non-completed tasks
    );
  }

  Future<List<Todo>> getCompletedTodayTodos() async {
    print('? TodoProvider: getCompletedTodayTodos() - Fetching completed tasks for today');
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await _graphQLService.getTodos(
      completed: true, // Explicitly request completed tasks
      updatedAfter  : startOfDay,
      updatedBefore: endOfDay,
    );
  }

  Future<List<Todo>> getGeneralTodos() async {
    print('? TodoProvider: getGeneralTodos() - Fetching non-completed tasks with no category');
    try {
      final todos = await _graphQLService.getTodos(
        completed: false,
        categoryId: 'none', // Special value to indicate no category
      );
      print('? TodoProvider: getGeneralTodos() - Successfully fetched ${todos.length} tasks');
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
      
      // For General category, we want todos with no category
      final result = await _graphQLService.getTodos(
        completed: false,
        categoryId: isGeneral ? 'none' : categoryId,
        noCategoryOnly: isGeneral ? true : null,
      );
      
      print('? Successfully fetched ${result.length} todos for category: $categoryId');
      // Log each todo for debugging
      for (final todo in result) {
        print('? Todo: id=${todo.id}, title=${todo.title}, category=${todo.category?.name ?? 'none'}');
      }
      
      return result;
    } catch (e) {
      print('? Error fetching todos by category $categoryId: $e');
      return [];
    }
  }

  Future<void> createTodo({
    required String title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    print('? TodoProvider: createTodo(title: $title, categoryId: $categoryId) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Handle categoryId correctly - no need to transform it here, 
      // GraphQLService will handle it properly
      final todo = await _graphQLService.createTodo(
        title: title,
        description: description,
        categoryId: categoryId,
        dueDate: dueDate,
        location: location,
        priority: priority,
        tags: tags,
      );
      
      _error = null;
      print('? TodoProvider: Task created successfully: ${todo.id}');
      
      // Reload data after creating a new todo
      print('? TodoProvider: Reloading data after task creation');
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: createTodo() Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('? TodoProvider: notifyListeners() - UI update triggered after task creation');
    }
  }

  Future<void> toggleTodo(String id) async {
    print('? TodoProvider: toggleTodo(id: $id) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Perform the server call first
      final todo = await _graphQLService.toggleTodo(id);
      _error = null;
      print('? TodoProvider: toggleTodo() - Task toggled successfully. Completed: ${todo.completed}');
      
      // Reload data after toggling a todo
      print('? TodoProvider: toggleTodo() - Reloading data after task toggle');
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: toggleTodo() - Error: $_error');
      
      // Even on error, reload data to ensure UI consistency
      await loadTodos();
    } finally {
      _isLoading = false;
      // Make sure UI gets updated
      notifyListeners();
      print('? TodoProvider: notifyListeners() - UI update triggered after task toggle');
    }
  }

  Future<void> deleteTodo(String id) async {
    print('?? TodoProvider: deleteTodo(id: $id) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Optimistically update UI before server response
      notifyListeners();
      
      await _graphQLService.deleteTodo(id);
      _error = null;
      print('? TodoProvider: deleteTodo() - Task deleted successfully');
      
      // Reload data after deleting a todo
      print('? TodoProvider: deleteTodo() - Reloading data after task deletion');
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: deleteTodo() - Error: $_error');
      
      // Even on error, reload data to ensure UI consistency
      await loadTodos();
    } finally {
      _isLoading = false;
      // Make sure UI gets updated
      notifyListeners();
      print('? TodoProvider: notifyListeners() - UI update triggered after task deletion');
    }
  }

  Future<void> syncWithCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('lastSync') ?? 0;
    
    await prefs.setInt('lastSync', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> loadTodos() async {
    print('? TodoProvider: loadTodos() - Started refreshing all todo lists');
    _isLoading = true;
    notifyListeners();
    try {
      await getTodayTodos();
      await getUpcomingTodos();
      await getAllTodos();
      await getCompletedTodayTodos();
      await getGeneralTodos();
      await getReminders();
      await getFuturePlans();
      await getRecentlyUpdatedTasks();
      print('? TodoProvider: loadTodos() - All todo lists refreshed successfully');
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: loadTodos() - Error: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('? TodoProvider: notifyListeners() - UI update triggered');
    }
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
      return todos;
    } catch (e) {
      print('? TodoProvider: getRecentlyUpdatedTasks() - Error: $e');
      return [];
    }
  }
} 