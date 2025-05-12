import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/todo_provider.dart';
import '../l10n/app_localizations.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    
    // Update controller if the search provider's query changes externally
    if (_searchController.text != searchProvider.query) {
      _searchController.text = searchProvider.query;
    }
    
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: localizations.searchTodos,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  searchProvider.search('', todoProvider);
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      onChanged: (value) {
        searchProvider.search(value, todoProvider);
      },
    );
  }
} 