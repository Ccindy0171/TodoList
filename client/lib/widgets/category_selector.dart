import 'package:flutter/material.dart';
import '../models/category.dart' as models;
import '../l10n/app_localizations.dart';

class CategorySelector extends StatefulWidget {
  final List<models.Category> categories;
  final List<String> selectedIds;
  final Function(List<String>) onChanged;
  final bool isLoading;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  void didUpdateWidget(CategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIds != widget.selectedIds) {
      _selectedIds = List.from(widget.selectedIds);
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedIds.contains(categoryId)) {
        _selectedIds.remove(categoryId);
      } else {
        _selectedIds.add(categoryId);
      }
      widget.onChanged(_selectedIds);
    });
  }

  // Helper function to safely parse color
  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } else {
        return Color(int.parse(colorString, radix: 16));
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort categories for better UX
    final sortedCategories = List<models.Category>.from(widget.categories);
    sortedCategories.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.categories,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        if (sortedCategories.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              localizations.noCategories,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          )
        else 
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedCategories.map((category) {
                  final isSelected = _selectedIds.contains(category.id);
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    selectedColor: _parseColor(category.color).withOpacity(0.3),
                    checkmarkColor: _parseColor(category.color),
                    avatar: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(category.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onSelected: (_) => _toggleCategory(category.id),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
} 