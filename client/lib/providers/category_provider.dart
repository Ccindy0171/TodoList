import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/graphql_service.dart';

class CategoryProvider with ChangeNotifier {
  final GraphQLService _graphQLService = GraphQLService();
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _graphQLService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory({
    required String name,
    required String color,
  }) async {
    try {
      final category = await _graphQLService.createCategory(
        name: name,
        color: color,
      );
      _categories.add(category);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 