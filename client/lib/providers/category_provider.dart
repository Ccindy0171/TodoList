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
    print('? CategoryProvider: loadCategories() - Started loading categories');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedCategories = await _graphQLService.getCategories();
      print('? CategoryProvider: Loaded ${fetchedCategories.length} categories');
      
      // Log each category for debugging
      for (final category in fetchedCategories) {
        print('? Category: id=${category.id}, name=${category.name}, color=${category.color}');
      }
      
      _categories = fetchedCategories;
    } catch (e) {
      _error = e.toString();
      print('? CategoryProvider: Error loading categories - $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('? CategoryProvider: notifyListeners() - UI update triggered after loading categories');
    }
  }

  Future<void> createCategory({
    required String name,
    required String color,
  }) async {
    print('? CategoryProvider: createCategory(name: $name, color: $color) - Started');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newCategory = await _graphQLService.createCategory(
        name: name,
        color: color,
      );
      
      print('? CategoryProvider: Created new category - id=${newCategory.id}, name=${newCategory.name}');
      
      // Instead of just reloading, update local list immediately for better UX
      _categories.add(newCategory);
      
      // Then reload all categories from server to ensure we have the latest data
      await loadCategories();
      
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('? CategoryProvider: Error creating category - $_error');
      notifyListeners();
    }
  }
} 