import 'category.dart';

class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final Category? category;
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
    this.dueDate,
    this.location,
    this.priority,
    this.tags,
    required this.updatedAt,
    this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool,
      category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      location: json['location'] as String?,
      priority: json['priority'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'location': location,
      'priority': priority,
      'tags': tags,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    Category? category,
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
      dueDate: dueDate ?? this.dueDate,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 