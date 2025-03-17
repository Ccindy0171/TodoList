import 'package:graphql/client.dart';
import '../models/todo.dart';

class GraphQLService {
  static const String _baseUrl = 'http://localhost:8080/query';
  late GraphQLClient _client;

  GraphQLService() {
    final HttpLink httpLink = HttpLink(_baseUrl);
    _client = GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
    );
  }

  Future<List<Todo>> getTodos({
    bool? completed,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    List<String>? tags,
  }) async {
    const String query = r'''
      query GetTodos($filter: TodoFilter) {
        todos(filter: $filter) {
          id
          title
          description
          completed
          category
          dueDate
          location
          priority
          tags
          createdAt
          updatedAt
        }
      }
    ''';

    final variables = {
      'filter': {
        if (completed != null) 'completed': completed,
        if (category != null) 'category': category,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (priority != null) 'priority': priority,
        if (tags != null) 'tags': tags,
      }
    };

    final result = await _client.query(
      QueryOptions(
        document: gql(query),
        variables: variables,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final List<dynamic> todosJson = result.data?['todos'] ?? [];
    return todosJson.map((json) => Todo.fromJson(json)).toList();
  }

  Future<Todo> createTodo({
    required String title,
    String? description,
    String? category,
    DateTime? dueDate,
    String? location,
    int? priority,
    List<String>? tags,
  }) async {
    const String mutation = r'''
      mutation CreateTodo($input: TodoInput!) {
        createTodo(input: $input) {
          id
          title
          description
          completed
          category
          dueDate
          location
          priority
          tags
          createdAt
          updatedAt
        }
      }
    ''';

    final variables = {
      'input': {
        'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
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
    const String mutation = r'''
      mutation ToggleTodo($id: ID!) {
        toggleTodo(id: $id) {
          id
          title
          description
          completed
          category
          dueDate
          location
          priority
          tags
          createdAt
          updatedAt
        }
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return Todo.fromJson(result.data?['toggleTodo']);
  }

  Future<bool> deleteTodo(String id) async {
    const String mutation = r'''
      mutation DeleteTodo($id: ID!) {
        deleteTodo(id: $id)
      }
    ''';

    final result = await _client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data?['deleteTodo'] ?? false;
  }
} 