import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../pages/task_edit_page.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../l10n/app_localizations.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(Todo)? onToggle;
  final bool showTimeOnly;
  final Color defaultColor;

  const TodoItem({
    super.key,
    required this.todo,
    this.onToggle,
    this.showTimeOnly = false,
    this.defaultColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    // Format date in a human-readable way with YYYY-MM-DD HH:MM format
    String formatDateTime(DateTime dateTime) {
      final formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$formattedDate $formattedTime';
    }
    
    // Format just the time portion
    String formatTimeOnly(DateTime dateTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    
    // Parse color string to Color object safely
    Color parseColor(String colorString) {
      try {
        // Handle hex color format with # prefix
        if (colorString.startsWith('#')) {
          return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
        } 
        // Handle hex color format without # prefix
        else {
          return Color(int.parse(colorString, radix: 16));
        }
      } catch (e) {
        // Default color if parsing fails
        return Colors.grey;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskEditPage(task: todo),
              ),
            ).then((updated) {
              if (updated == true && onToggle != null) {
                onToggle!(todo);
              }
            });
          },
          child: ListTile(
            leading: InkWell(
              onTap: () {
                if (onToggle != null) {
                  onToggle!(todo);
                } else {
                  // If no onToggle callback provided, use the provider directly
                  context.read<TodoProvider>().toggleTodo(todo.id);
                }
              },
              child: Icon(
                todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: todo.completed ? Colors.green : defaultColor,
                size: 26,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description (if any)
                if (todo.description != null && todo.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _abbreviateText(todo.description!, 50),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                // Location (if any)
                if (todo.location != null && todo.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          todo.location!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                // Due date or Completion time
                if (todo.completed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Completed at ${formatDateTime(todo.updatedAt)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  )
                else if (todo.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      showTimeOnly 
                          ? 'Time: ${formatTimeOnly(todo.dueDate!)}'
                          : formatDateTime(todo.dueDate!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                
                // Tags row (if any)
                if (todo.tags != null && todo.tags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: todo.tags!.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                
                // Display all categories
                Builder(
                  builder: (context) {
                    final allCategories = todo.getAllCategories(); // Use the corrected method
                    if (allCategories.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 6.0), // Add some spacing
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allCategories.map((category) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: parseColor(category.color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.name.toLowerCase(),
                              style: TextStyle(
                                color: parseColor(category.color),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Return an empty widget if no categories
                  }
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<TodoProvider>().deleteTodo(todo.id);
                if (onToggle != null) {
                  onToggle!(todo); // Notify parent to refresh
                }
              },
            ),
          ),
        ),
      ),
    );
  }
  
  String _abbreviateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
} 