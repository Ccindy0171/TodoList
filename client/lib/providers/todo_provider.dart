import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/graphql_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoProvider with ChangeNotifier {
  final GraphQLService _graphQLService = GraphQLService();
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;

  TodoProvider() {
    loadTodos();
  }

  List<Todo> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTodos({
    bool? completed,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final loadedTodos = await _graphQLService.getTodos(
        completed: completed,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        priority: priority,
        tags: tags,
      );
      
      _todos = loadedTodos;
      _todos.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
    try {
      final todo = await _graphQLService.createTodo(
        title: title,
        description: description,
        categoryId: categoryId,
        dueDate: dueDate,
        location: location,
        priority: priority,
        tags: tags,
      );
      
      _todos.add(todo);
      _todos.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTodo(String id) async {
    try {
      final updatedTodo = await _graphQLService.toggleTodo(id);
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = updatedTodo;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      final success = await _graphQLService.deleteTodo(id);
      if (success) {
        _todos.removeWhere((todo) => todo.id == id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<Todo> getTodayTodos() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _todos.where((todo) {
      if (todo.dueDate == null || todo.completed) return false;
      return todo.dueDate!.isAfter(startOfDay) && 
             todo.dueDate!.isBefore(endOfDay);
    }).toList();
  }

  List<Todo> getUpcomingTodos() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _todos.where((todo) {
      if (todo.dueDate == null || todo.completed) return false;
      return todo.dueDate!.isAfter(endOfDay);
    }).toList();
  }

  List<Todo> getAllTodos() {
    return _todos.where((todo) => !todo.completed).toList();
  }

  List<Todo> getCompletedTodayTodos() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _todos.where((todo) {
      if (!todo.completed) return false;
      return todo.updatedAt.isAfter(startOfDay) && 
             todo.updatedAt.isBefore(endOfDay);
    }).toList();
  }

  List<Todo> getReminders() {
    return _todos.where((todo) => 
      !todo.completed &&
      todo.dueDate != null && 
      (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0)
    ).toList();
  }

  List<Todo> getFuturePlans() {
    return _todos.where((todo) => 
      !todo.completed &&
      todo.dueDate != null && 
      todo.dueDate!.hour == 0 && 
      todo.dueDate!.minute == 0
    ).toList();
  }

  Future<void> syncWithCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt('lastSync') ?? 0;
    
    await loadTodos();
    await prefs.setInt('lastSync', DateTime.now().millisecondsSinceEpoch);
  }
} 