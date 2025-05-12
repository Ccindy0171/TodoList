import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/todo_provider.dart';
import '../models/todo.dart';
import '../l10n/app_localizations.dart';
import '../widgets/todo_item.dart';

class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    
    if (!searchProvider.isSearching) {
      return const SizedBox.shrink();
    }
    
    if (searchProvider.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.searchTodos,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    final results = searchProvider.searchResults;
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return TodoItem(
          todo: results[index],
          onToggle: (Todo todo) {
            // Toggle the todo and refresh search results after the operation completes
            todoProvider.toggleTodo(todo.id).then((_) {
              // Re-run the search with current query to refresh results
              searchProvider.search(searchProvider.query, todoProvider);
            });
          },
          defaultColor: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
} 