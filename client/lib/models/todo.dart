class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final String? category;
  final DateTime? dueDate;
  final String? location;
  final int? priority;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      completed: json['completed'],
      category: json['category'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      location: json['location'],
      priority: json['priority'],
      tags: json['tags']?.cast<String>(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'location': location,
      'priority': priority,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    String? category,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 