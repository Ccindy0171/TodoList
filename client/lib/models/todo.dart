import 'category.dart';
import '../utils/encoding_helper.dart';

class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final Category? category; // Keep for backward compatibility
  final List<Category>? categories; // New field for multiple categories
  final DateTime? dueDate;
  final String? location;
  final int? priority;
  final List<String>? tags;
  final DateTime updatedAt;
  
  // This field is deprecated as it's not included in TodoOutput from the server
  // Use updatedAt for sorting or display purposes instead
  @deprecated
  final DateTime? createdAt;

  Todo({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    this.category,
    this.categories,
    this.dueDate,
    this.location,
    this.priority,
    this.tags,
    required this.updatedAt,
    this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    List<String>? tags;
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = (json['tags'] as List).map((item) => item.toString()).toList();
      }
    }

    // Parse dates while preserving the local time
    DateTime? parseDueDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Parse the date but preserve the local time intention
        // This ensures times like 23:59 don't become 15:59
        final DateTime parsed = DateTime.parse(dateStr);
        // Apply the timezone offset to get back to local time
        return parsed.toLocal();
      } catch (e) {
        print('Error parsing dueDate: $e');
        return null;
      }
    }

    // Handle single category (for backward compatibility)
    Category? singleCategory;
    if (json['category'] != null) {
      singleCategory = Category.fromJson(json['category'] as Map<String, dynamic>);
    }
    
    // Handle multiple categories
    List<Category>? multipleCategories;
    if (json['categories'] != null && json['categories'] is List) {
      multipleCategories = (json['categories'] as List)
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Handle potentially missing or null fields
    return Todo(
      id: json['id'] as String,
      title: EncodingHelper.ensureUtf8(json['title'] as String),
      description: json['description'] != null ? 
        EncodingHelper.ensureUtf8(json['description'] as String) : null,
      completed: json['completed'] as bool? ?? false,
      category: singleCategory,
      categories: multipleCategories,
      dueDate: json['dueDate'] != null ? parseDueDate(json['dueDate'] as String) : null,
      location: json['location'] != null ? 
        EncodingHelper.ensureUtf8(json['location'] as String) : null,
      priority: json['priority'] as int?,
      tags: tags,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String).toLocal() : DateTime.now(),
      createdAt: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'category': category?.toJson(),
      'categories': categories?.map((c) => c.toJson()).toList(),
      'dueDate': dueDate?.toIso8601String(),
      'location': location,
      'priority': priority,
      'tags': tags,
      'updatedAt': updatedAt.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    Category? category,
    List<Category>? categories,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      dueDate: dueDate ?? this.dueDate,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Helper method to get all categories (from both category and categories fields)
  // Since the server only supports 'category' field (not 'categories'),
  // this is simplified to just return the single category if it exists
  List<Category> getAllCategories() {
    // Prioritize the new 'categories' list if available and not empty
    if (categories != null && categories!.isNotEmpty) {
      return List<Category>.from(categories!); // Return a copy
    }
    // Fallback to the legacy single 'category'
    if (category != null) {
      return [category!];
    }
    // If neither is present, return an empty list
    return [];
  }
} 