import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/graphql_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CategoryProvider with ChangeNotifier {
  final GraphQLService _graphQLService;
  List<models.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Constructor that accepts the GraphQLService instance
  CategoryProvider([GraphQLService? graphQLService]) : _graphQLService = graphQLService ?? GraphQLService() {
    print('? CategoryProvider: Initialized with server URL: ${_graphQLService.serverUrl}');
  }

  // Predefined colors that can be used for categories
  static final List<String> predefinedColors = [
    '#FF0000', // Red
    '#00FF00', // Green
    '#0000FF', // Blue
    '#FFFF00', // Yellow
    '#FF00FF', // Magenta
    '#00FFFF', // Cyan
    '#FFA500', // Orange
    '#800080', // Purple
    '#008000', // Dark Green
    '#000080', // Navy Blue
    '#FF4500', // OrangeRed
    '#8B4513', // SaddleBrown
    '#4682B4', // SteelBlue
    '#2E8B57', // SeaGreen
    '#9932CC', // DarkOrchid
    '#FF6347', // Tomato
    '#808000', // Olive
    '#4169E1', // RoyalBlue
    '#32CD32', // LimeGreen
    '#8A2BE2', // BlueViolet
  ];

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Returns a list of colors that are not currently used by any category
  List<String> getAvailableColors() {
    final usedColors = _categories.map((c) => c.color.toLowerCase()).toSet();
    return predefinedColors.where((color) => !usedColors.contains(color.toLowerCase())).toList();
  }

  // Check if a color is already used by any category
  bool isColorUnique(String color, {String? excludeCategoryId}) {
    return !_categories.any((cat) => 
      cat.color.toLowerCase() == color.toLowerCase() && 
      cat.id != excludeCategoryId
    );
  }

  // Get a unique color from the predefined list
  String getUniqueColor() {
    final availableColors = getAvailableColors();
    if (availableColors.isNotEmpty) {
      return availableColors.first;
    }
    
    // If all predefined colors are used, generate a random color
    final Random random = Random();
    final int r = random.nextInt(256);
    final int g = random.nextInt(256);
    final int b = random.nextInt(256);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

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

  Future<models.Category> createCategory({
    required String name,
    required String color,
  }) async {
    print('? CategoryProvider: createCategory(name: $name, color: $color)');
    
    // Ensure the color is unique
    String finalColor = color;
    if (!isColorUnique(finalColor)) {
      finalColor = getUniqueColor();
      print('? CategoryProvider: Color was not unique, assigned new color: $finalColor');
    }
    
    final category = await _graphQLService.createCategory(
      name: name,
      color: finalColor,
    );
    
    _categories.add(category);
    notifyListeners();
    
    return category;
  }
  
  Future<bool> deleteCategory(String id) async {
    print('? CategoryProvider: deleteCategory(id: $id)');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _graphQLService.deleteCategory(id);
      
      if (success) {
        // Remove the category from the local list
        _categories.removeWhere((category) => category.id == id);
        print('? CategoryProvider: Category deleted successfully');
      } else {
        print('? CategoryProvider: Failed to delete category');
        _error = 'Failed to delete category';
      }
      
      return success;
    } catch (e) {
      _error = e.toString();
      print('? CategoryProvider: Error deleting category - $_error');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 