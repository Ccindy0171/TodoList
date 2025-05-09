import 'package:graphql/client.dart';
import '../models/todo.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class GraphQLService {
  // Default URL for backward compatibility
  static const String _defaultUrl = 'http://10.0.2.2:8080/query'; // for android emulator
  // static const String _defaultUrl = 'http://localhost:8080/query'; // for web
  
  // Variables to store dynamic URL
  String _serverUrl = _defaultUrl;
  
  // Initialize _client with the default URL to avoid LateInitializationError
  GraphQLClient _client = GraphQLClient(
    link: HttpLink(_defaultUrl),
    cache: GraphQLCache(),
    // Increase timeout for network operations
    queryRequestTimeout: const Duration(seconds: 30),
  );
  
  // Maximum number of retries for failed requests
  static const int _maxRetries = 3;

  String get serverUrl => _serverUrl;

  // Method to change the server URL dynamically
  Future<void> setServerUrl(String newUrl) async {
    if (_serverUrl == newUrl) return;
    
    _serverUrl = newUrl;
    
    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('graphql_server_url', newUrl);
    
    // Recreate the client with the new URL and increased timeout
    final httpLink = HttpLink(_serverUrl);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
      // Increase timeout for network operations
      queryRequestTimeout: const Duration(seconds: 30),
    );
    
    print('? GraphQL Service: Server URL changed to $_serverUrl');
  }

  // Generic method to handle retries for GraphQL operations
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    late dynamic lastError;
    
    while (retryCount < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        print('? GraphQL Error (attempt ${retryCount + 1}/$_maxRetries): $e');
        
        // Wait before retry with exponential backoff: 1s, 2s, 4s...
        final waitTime = Duration(seconds: 1 << retryCount);
        await Future.delayed(waitTime);
        
        retryCount++;
      }
    }
    
    // If we've exhausted all retries, throw the last error
    throw lastError;
  }

  String _formatDateTime(DateTime dateTime) {
    // Format as ISO 8601 with timezone offset
    // Create the date part: YYYY-MM-DD
    final String datePart = "${dateTime.year}-"
      "${dateTime.month.toString().padLeft(2, '0')}-"
      "${dateTime.day.toString().padLeft(2, '0')}";
    
    // Create the time part: HH:MM:SS
    final String timePart = "${dateTime.hour.toString().padLeft(2, '0')}:"
      "${dateTime.minute.toString().padLeft(2, '0')}:"
      "${dateTime.second.toString().padLeft(2, '0')}";
    
    // Add timezone offset
    final offset = dateTime.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    final offsetString = "$sign$hours:$minutes";
    
    // Combine all parts into a standard ISO 8601 format with timezone
    return "${datePart}T${timePart}${offsetString}";
  }

  GraphQLService() {
    // Initialize with saved URL or default
    _initializeClient();
  }
  
  Future<void> _initializeClient() async {
    try {
      // Try to load saved URL from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('graphql_server_url');
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _serverUrl = savedUrl;
        
        final httpLink = HttpLink(_serverUrl);
        _client = GraphQLClient(
          link: httpLink,
          cache: GraphQLCache(),
        );
      }
      
      print('? GraphQL Service: Initialized with server URL: $_serverUrl');
    } catch (e) {
      print('? GraphQL Service: Error initializing client: $e');
      // We already have a default client initialized, so we can continue
    }
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

    // Use the retry mechanism for the query operation
    final result = await _withRetry(() => _client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly, // Always fetch from server, not cache
      ),
    ));

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
    required String title,
    String? description,
    String? categoryId,
    required DateTime dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    print('? GraphQL Request: updateTodo(id: $id, title: $title, categoryId: $categoryId)');
    
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
      print('? Updating task with no category');
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
      'id': id,
      'input': inputMap
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    const String mutation = '''
      mutation UpdateTodo(\$id: ID!, \$input: TodoInput!) {
        updateTodo(id: \$id, input: \$input) {
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
      print('? GraphQL Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

    return Todo.fromJson(result.data?['updateTodo']);
  }
} 