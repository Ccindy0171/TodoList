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
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    List<String>? tags,
  }) async {
    print('? GraphQL Request: getTodos(completed: $completed, startDate: $startDate, endDate: $endDate, priority: $priority, categoryId: $categoryId)');
    
    final Map<String, dynamic> variables = {
      'filter': {
        if (completed != null) 'completed': completed,
        if (categoryId != null && categoryId != 'none') 'categoryId': categoryId,
        if (categoryId == 'none') 'noCategoryOnly': true, // Special case: fetch only tasks with no category
        if (startDate != null) 'startDate': _formatDateTime(startDate),
        if (endDate != null) 'endDate': _formatDateTime(endDate),
        if (priority != null) 'priority': priority,
        if (tags != null) 'tags': tags,
      }
    };
    
    print('? GraphQL Variables: ${variables.toString()}');

    // Query WITHOUT createdAt field 
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

    final variables = {
      'input': {
        'title': title,
        if (description != null) 'description': description,
        if (categoryId != null) 'categoryId': categoryId,
        if (dueDate != null) 'dueDate': _formatDateTime(dueDate),
        if (location != null) 'location': location,
        if (priority != null) 'priority': priority,
        if (tags != null) 'tags': tags,
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

    return Todo.fromJson(result.data?['createTodo']);
  }

  Future<Todo> toggleTodo(String id) async {
    // Mutation WITHOUT createdAt field in category
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

    // Add 'todo:' prefix if it's not already there
    final formattedId = id.startsWith('todo:') ? id : 'todo:$id';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': formattedId},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Todo.fromJson(result.data?['toggleTodo']);
  }

  Future<bool> deleteTodo(String id) async {
    const String mutation = '''
      mutation DeleteTodo(\$id: ID!) {
        deleteTodo(id: \$id)
      }
    ''';

    // Add 'todo:' prefix if it's not already there
    final formattedId = id.startsWith('todo:') ? id : 'todo:$id';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': formattedId},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data?['deleteTodo'] ?? false;
  }
} 