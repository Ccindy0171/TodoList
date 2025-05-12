import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/todo_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  void initState() {
    super.initState();
    // Set the search mode to true when entering the search page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).setSearchMode(true);
    });
  }

  @override
  void dispose() {
    // Clear search when leaving the page
    Provider.of<SearchProvider>(context, listen: false).clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.search),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Search results take remaining space
          Expanded(
            child: const SearchResultsWidget(),
          ),
        ],
      ),
    );
  }
} 