import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import 'todo_provider.dart';

class SearchProvider with ChangeNotifier {
  String _query = '';
  List<Todo> _searchResults = [];
  bool _isSearching = false;
  
  String get query => _query;
  List<Todo> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  
  void setSearchMode(bool isSearching) {
    _isSearching = isSearching;
    if (!isSearching) {
      _query = '';
      _searchResults = [];
    }
    notifyListeners();
  }
  
  void search(String query, TodoProvider todoProvider) {
    _query = query;
    
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    // Get all available todos from the provider
    final allTodos = todoProvider.getCachedAllTodos ?? [];
    final completedTodos = todoProvider.getCachedAllCompletedTodos ?? [];
    
    // Combine both lists for searching
    final combinedTodos = [...allTodos, ...completedTodos];
    
    // Filter todos based on query
    _searchResults = combinedTodos.where((todo) {
      final lowerQuery = query.toLowerCase();
      final titleMatch = todo.title.toLowerCase().contains(lowerQuery);
      final descMatch = todo.description?.toLowerCase().contains(lowerQuery) ?? false;
      final locationMatch = todo.location?.toLowerCase().contains(lowerQuery) ?? false;
      final categoryMatch = todo.category?.name.toLowerCase().contains(lowerQuery) ?? false;
      final tagMatch = todo.tags?.any((tag) => tag.toLowerCase().contains(lowerQuery)) ?? false;
      
      return titleMatch || descMatch || locationMatch || categoryMatch || tagMatch;
    }).toList();
    
    notifyListeners();
  }
  
  void clearSearch() {
    _query = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
} 