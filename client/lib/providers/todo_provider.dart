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
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  Future<List<Todo>> getGeneralTodos() async {
    print('? TodoProvider: getGeneralTodos() - Fetching non-completed tasks with no category');
    return await _graphQLService.getTodos(
      completed: false,
      categoryId: 'none', // Special value to indicate no category
    );
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
    print('? TodoProvider: getTodosByCategory(categoryId: $categoryId) - Fetching non-completed tasks');
    return await _graphQLService.getTodos(
      completed: false,
      categoryId: categoryId,
    );
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
    print('+ TodoProvider: createTodo(title: $title) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _graphQLService.createTodo(
        title: title,
        description: description,
        categoryId: categoryId,
        dueDate: dueDate,
        location: location,
        priority: priority,
        tags: tags,
      );
      _error = null;
      print('? TodoProvider: createTodo() - Task created successfully');
      
      // Reload data after creating a new todo
      print('? TodoProvider: createTodo() - Reloading data after task creation');
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      print('? TodoProvider: createTodo() - Error: $_error');
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
      // Optimistically update UI before server response
      notifyListeners();
      
      await _graphQLService.toggleTodo(id);
      _error = null;
      print('? TodoProvider: toggleTodo() - Task toggled successfully');
      
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
} 