import 'package:graphql/client.dart';
import '../models/todo.dart';
import '../models/category.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class GraphQLService {
  // Default URL for backward compatibility
  // static const String _defaultUrl = 'http://10.0.2.2:8080/query'; // for android emulator
  static const String _defaultUrl = 'http://localhost:8080/query'; // for web
  
  // Variables to store dynamic URL
  String _serverUrl = _defaultUrl;
  bool _isUsingDefaultUrl = true;
  bool _allowDefaultUrl = false;
  bool _isInitialized = false;
  
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
  bool get isUsingDefaultUrl => _isUsingDefaultUrl;
  bool get allowDefaultUrl => _allowDefaultUrl;
  bool get isInitialized => _isInitialized;
  
  // Constructor now returns a Future to ensure initialization completes
  GraphQLService() {
    // Start the initialization process
    _initializeClient();
    print('? GraphQL Service: Initialized with URL: $_serverUrl (initialization in progress)');
  }
  
  // Method to change the server URL dynamically
  Future<void> setServerUrl(String newUrl) async {
    if (_serverUrl == newUrl) return;
    
    print('? GraphQL Service: Changing server URL from $_serverUrl to $newUrl');
    _serverUrl = newUrl;
    _isUsingDefaultUrl = (newUrl == _defaultUrl);
    
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
    
    print('? GraphQL Service: Server URL changed to $_serverUrl (using default: $_isUsingDefaultUrl)');
    
    // Verify the change was applied
    final savedUrl = prefs.getString('graphql_server_url');
    if (savedUrl != newUrl) {
      print('? GraphQL Service: WARNING - Saved URL ($savedUrl) doesn\'t match requested URL ($newUrl)');
    } else {
      print('? GraphQL Service: Successfully verified URL change to $newUrl');
    }
  }

  // Set whether to allow using the default URL
  Future<void> setAllowDefaultUrl(bool allow) async {
    _allowDefaultUrl = allow;
    
    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allow_default_url', allow);
    
    print('? GraphQL Service: Default URL allowed: $_allowDefaultUrl');
  }

  // Make sure client is initialized before any operations
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeClient();
    }
  }
  
  Future<void> _initializeClient() async {
    if (_isInitialized) return;
    
    try {
      print('? GraphQL Service: Starting client initialization');
      // Try to load saved URL from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('graphql_server_url');
      
      // Load saved allowDefaultUrl preference
      _allowDefaultUrl = prefs.getBool('allow_default_url') ?? false;
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        print('? GraphQL Service: Found saved server URL: $savedUrl');
        
        // Update internal variables
        _serverUrl = savedUrl;
        _isUsingDefaultUrl = (savedUrl == _defaultUrl);
        
        // Create a new client with the saved URL
        final httpLink = HttpLink(_serverUrl);
        _client = GraphQLClient(
          link: httpLink,
          cache: GraphQLCache(),
          queryRequestTimeout: const Duration(seconds: 30),
        );
        
        print('? GraphQL Service: Initialized with saved server URL: $_serverUrl');
        
        // Verify the client is using the correct URL
        if (_client.link is HttpLink) {
          final link = _client.link as HttpLink;
          final uri = link.uri.toString();
          print('? GraphQL Service: Client URI: $uri');
          
          if (uri != _serverUrl) {
            print('? GraphQL Service: WARNING - URL mismatch, recreating client');
            // Force recreation of client with correct URL
            _client = GraphQLClient(
              link: HttpLink(_serverUrl),
              cache: GraphQLCache(),
              queryRequestTimeout: const Duration(seconds: 30),
            );
          }
        }
      } else {
        print('? GraphQL Service: No saved server URL found, using default: $_defaultUrl');
        // By default, don't allow using the default URL without explicit permission
        _allowDefaultUrl = false;
        await prefs.setBool('allow_default_url', false);
      }
      
      print('? GraphQL Service: Initialized with server URL: $_serverUrl (using default: $_isUsingDefaultUrl, allow default: $_allowDefaultUrl)');
      _isInitialized = true;
    } catch (e) {
      print('? GraphQL Service: Error initializing client: $e');
      // We already have a default client initialized, so we can continue
      // But make sure we don't allow using default URL without permission
      _allowDefaultUrl = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('allow_default_url', false);
    }
  }

  // Generic method to handle retries for GraphQL operations
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int retryCount = 0;
    late dynamic lastError;
    
    // Initial delay in milliseconds
    int delayMs = 100; 
    const int maxDelayMs = 10000; // Maximum delay of 10 seconds
    
    while (retryCount < _maxRetries) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        print('? GraphQL Error (attempt ${retryCount + 1}/$_maxRetries): $e');
        
        // Wait before retry with exponential backoff
        // Start with very short delays and increase exponentially
        final waitTime = Duration(milliseconds: delayMs);
        print('? Waiting ${waitTime.inMilliseconds}ms before retry ${retryCount + 1}');
        await Future.delayed(waitTime);
        
        // Increase delay for next retry (exponential backoff with jitter)
        delayMs = (delayMs * 2).clamp(0, maxDelayMs);
        
        retryCount++;
      }
    }
    
    // If we've exhausted all retries, throw the last error
    throw lastError;
  }

  // Simple connectivity check method
  Future<bool> checkConnectivity() async {
    print('? GraphQL Service: Checking connectivity to $_serverUrl');
    
    try {
      // First try a simple HTTP request to check basic network connectivity
      try {
        final httpResponse = await http.get(
          Uri.parse(_serverUrl),
        ).timeout(const Duration(seconds: 5));
        
        print('? GraphQL Service: HTTP GET status: ${httpResponse.statusCode}');
      } catch (e) {
        print('? GraphQL Service: HTTP GET failed: $e');
        // Continue checking GraphQL even if HTTP fails
        // Some GraphQL servers don't support GET requests
      }
      
      // Use a very simple GraphQL query to check connectivity
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"query":"{__typename}"}',
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('? GraphQL Service: Connectivity check successful (200 OK)');
        try {
          // Try to parse the response to ensure it's valid JSON
          final jsonResponse = jsonDecode(response.body);
          print('? GraphQL Service: Response: $jsonResponse');
          return true;
        } catch (e) {
          print('? GraphQL Service: Invalid JSON response: $e');
          return false;
        }
      } else {
        print('? GraphQL Service: Connectivity check failed with status: ${response.statusCode}');
        print('? GraphQL Service: Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('? GraphQL Service: Connectivity check failed: $e');
      
      // Provide more details for common connection errors
      if (e.toString().contains('SocketException')) {
        print('? GraphQL Service: Network error - Server might be unreachable');
      } else if (e.toString().contains('TimeoutException')) {
        print('? GraphQL Service: Timeout - Server is too slow to respond');
      }
      
      return false;
    }
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

  Future<List<Category>> getCategories() async {
    // Ensure initialization
    await ensureInitialized();
    
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
    // Ensure initialization
    await ensureInitialized();
    
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

    try {
      print('? GraphQL: Sending todo query to server: $_serverUrl');
      
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
        
        // Provide more detailed error information based on exception type
        if (result.exception is OperationException) {
          final opException = result.exception as OperationException;
          
          if (opException.linkException != null) {
            print('? GraphQL Link Error: ${opException.linkException.toString()}');
            if (opException.linkException.toString().contains('Failed host lookup')) {
              print('? GraphQL: DNS resolution failed - check network connection and server URL');
            }
          }
          
          if (opException.graphqlErrors.isNotEmpty) {
            for (var error in opException.graphqlErrors) {
              print('? GraphQL Error: ${error.message}');
              print('? GraphQL Error Location: ${error.locations}');
              print('? GraphQL Error Extensions: ${error.extensions}');
            }
          }
        }
        
        throw Exception(result.exception.toString());
      }

      final List<dynamic> todosJson = result.data?['todos'] ?? [];
      final todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      
      print('? GraphQL Response: ${todos.length} todos received (completed: $completed)');
      todos.forEach((todo) {
        print('  ? Todo: ${todo.id} - ${todo.title} - completed: ${todo.completed}');
      });
      
      return todos;
    } catch (e) {
      print('? GraphQL getTodos ERROR: $e');
      throw e; // Rethrow to be caught by the error handlers higher up
    }
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
    // Ensure initialization
    await ensureInitialized();
    
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
    // Ensure initialization
    await ensureInitialized();
    
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
    // Ensure initialization
    await ensureInitialized();
    
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
    // Ensure initialization
    await ensureInitialized();
    
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