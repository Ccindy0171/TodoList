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
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    String id = json['id'];
    // Remove 'todo:' prefix if it exists
    if (id.startsWith('todo:')) {
      id = id.substring(5);
    }
    
    return Todo(
      id: id,
      title: json['title'],
      description: json['description'],
      completed: json['completed'],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      location: json['location'],
      priority: json['priority'],
      tags: json['tags']?.cast<String>(),
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
    );
  }
} 