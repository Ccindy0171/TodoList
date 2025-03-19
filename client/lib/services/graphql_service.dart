import 'package:graphql/client.dart';
import '../models/todo.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';

class GraphQLService {
  static const String _baseUrl = 'http://10.0.2.2:8080/query'; // for android emulator
  // static const String _baseUrl = 'http://localhost:8080/query'; // for web
  late GraphQLClient _client;

  String _formatDateTime(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.toIso8601String(); // This will format as "2024-03-18T15:04:05.000Z"
  }

  GraphQLService() {
    final HttpLink httpLink = HttpLink(_baseUrl);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  Future<List<Category>> getCategories() async {
    const String query = '''
      query GetCategories {
        categories {
          id
          name
          color
          createdAt
          updatedAt
        }
      }
    ''';

    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly, // Always fetch from server, not cache
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> categoriesJson = result.data?['categories'] ?? [];
    return categoriesJson.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory({
    required String name,
    required String color,
  }) async {
    const String mutation = '''
      mutation CreateCategory(\$input: CategoryInput!) {
        createCategory(input: \$input) {
          id
          name
          color
          createdAt
          updatedAt
        }
      }
    ''';

    final variables = {
      'input': {
        'name': name,
        'color': color,
      }
    };

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Category.fromJson(result.data?['createCategory']);
  }

  Future<List<Todo>> getTodos({
    bool? completed,
    String? categoryId,
    bool? noCategoryOnly,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? updatedBefore,
    DateTime? updatedAfter,
    int? priority,
    List<String>? tags,
  }) async {
    print('? GraphQL Request: getTodos(completed: $completed, categoryId: $categoryId, noCategoryOnly: $noCategoryOnly)');
    
    Map<String, dynamic> filterMap = {};
    
    if (completed != null) filterMap['completed'] = completed;
    
    // Handle categoryId and noCategoryOnly
    if (categoryId == 'none' || noCategoryOnly == true) {
      filterMap['noCategoryOnly'] = true;
      print('? Setting noCategoryOnly=true for filter');
    } else if (categoryId != null && categoryId.isNotEmpty && categoryId != 'General') {
      filterMap['categoryId'] = categoryId;
      print('? Setting categoryId=$categoryId for filter');
    }
    
    if (startDate != null) filterMap['startDate'] = _formatDateTime(startDate);
    if (endDate != null) filterMap['endDate'] = _formatDateTime(endDate);
    
    // Add new filter parameters
    if (updatedBefore != null) filterMap['updatedBefore'] = _formatDateTime(updatedBefore);
    if (updatedAfter != null) filterMap['updatedAfter'] = _formatDateTime(updatedAfter);
    
    if (priority != null) filterMap['priority'] = priority;
    if (tags != null && tags.isNotEmpty) filterMap['tags'] = tags;
    
    final variables = {
      'filter': filterMap
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    const String query = '''
      query GetTodos(\$filter: TodoFilter) {
        todos(filter: \$filter) {
          id
          title
          description
          completed
          category {
            id
            name
            color
          }
          dueDate
          location
          priority
          tags
          updatedAt
        }
      }
    ''';

    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly, // Always fetch from server, not cache
      ),
    );

    if (result.hasException) {
      print('? GraphQL Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

    final List<dynamic> todosJson = result.data?['todos'] ?? [];
    final todos = todosJson.map((json) => Todo.fromJson(json)).toList();
    
    print('? GraphQL Response: ${todos.length} todos received (completed: $completed)');
    todos.forEach((todo) {
      print('  ? Todo: ${todo.id} - ${todo.title} - completed: ${todo.completed}');
    });
    
    return todos;
  }

  Future<Todo> createTodo({
    required String title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    print('? GraphQL Request: createTodo(title: $title, categoryId: $categoryId)');
    
    final Map<String, dynamic> inputMap = {
      'title': title,
    };
    
    if (description != null && description.isNotEmpty) {
      inputMap['description'] = description;
    }
    
    // Only add categoryId if it has a valid value
    if (categoryId != null && categoryId.isNotEmpty && 
        categoryId != 'none' && categoryId != 'General') {
      inputMap['categoryId'] = categoryId;
      print('? Setting categoryId: $categoryId');
    } else {
      print('? Creating task with no category');
    }
    
    if (dueDate != null) {
      inputMap['dueDate'] = _formatDateTime(dueDate);
    }
    
    if (location != null && location.isNotEmpty) {
      inputMap['location'] = location;
    }
    
    if (priority != null) {
      inputMap['priority'] = priority;
    }
    
    if (tags != null && tags.isNotEmpty) {
      inputMap['tags'] = tags;
    }
    
    final variables = {
      'input': inputMap
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    // Mutation WITHOUT createdAt field in category
    const String mutation = '''
      mutation CreateTodo(\$input: TodoInput!) {
        createTodo(input: \$input) {
          id
          title
          description
          completed
          category {
            id
            name
            color
          }
          dueDate
          location
          priority
          tags
          updatedAt
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      print('? GraphQL Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

    final todo = Todo.fromJson(result.data?['createTodo']);
    print('? GraphQL Response: Todo created successfully with ID: ${todo.id}');
    return todo;
  }

  Future<Todo> toggleTodo(String id) async {
    print('? GraphQL Request: toggleTodo(id: $id)');
    
    const String mutation = '''
      mutation ToggleTodo(\$id: ID!) {
        toggleTodo(id: \$id) {
          id
          title
          description
          completed
          category {
            id
            name
            color
          }
          dueDate
          location
          priority
          tags
          updatedAt
        }
      }
    ''';

    final variables = {
      'id': id
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (result.hasException) {
      print('? GraphQL Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

    final todo = Todo.fromJson(result.data?['toggleTodo']);
    print('? GraphQL Response: Todo toggled successfully, completed: ${todo.completed}');
    return todo;
  }

  Future<bool> deleteTodo(String id) async {
    print('? GraphQL Request: deleteTodo(id: $id)');
    
    const String mutation = '''
      mutation DeleteTodo(\$id: ID!) {
        deleteTodo(id: \$id)
      }
    ''';

    // Use the ID as-is without modification
    final variables = {
      'id': id
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
      ),
    );

    if (result.hasException) {
      print('? GraphQL Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

    final success = result.data?['deleteTodo'] ?? false;
    print('? GraphQL Response: Todo deleted successfully: $success');
    return success;
  }

  Future<Todo> updateTodo({
    required String id,
    String? title,
    String? description,
    bool? completed,
    String? categoryId,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    print('? GraphQL Request: updateTodo(id: $id, title: $title, completed: $completed, categoryId: $categoryId)');
    
    // Handle 'none' category specifically
    if (categoryId == 'none') {
      categoryId = null;
      print('? Converting "none" category to null for updateTodo request');
    }
    
    final Map<String, dynamic> inputMap = {
      'id': id,
    };
    
    if (title != null) inputMap['title'] = title;
    if (description != null) inputMap['description'] = description;
    if (completed != null) inputMap['completed'] = completed;
    if (categoryId != null) inputMap['categoryId'] = categoryId;
    if (dueDate != null) inputMap['dueDate'] = _formatDateTime(dueDate);
    if (location != null) inputMap['location'] = location;
    if (priority != null) inputMap['priority'] = priority;
    if (tags != null) inputMap['tags'] = tags;
    
    final variables = {
      'input': inputMap
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    // Mutation WITHOUT createdAt field in category
    const String mutation = '''
      mutation UpdateTodo(\$input: TodoInput!) {
        updateTodo(input: \$input) {
          id
          title
          description
          completed
          category {
            id
            name
            color
          }
          dueDate
          location
          priority
          tags
          updatedAt
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: variables,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Todo.fromJson(result.data?['updateTodo']);
  }
} 