import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as models;
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/category_selector.dart';

class AddTaskDialog extends StatefulWidget {
  final String? categoryId;
  final DateTime? initialDate;

  const AddTaskDialog({
    super.key,
    this.categoryId,
    this.initialDate,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagController = TextEditingController();
  final _newCategoryController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedCategoryIds = [];
  bool _isCreatingNewCategory = false;
  String _selectedColor = '#FF0000';
  bool _isLoading = false;
  int _priority = 0;
  bool _isSubmitting = false;
  List<String> _tags = [];

  // We'll now use the predefined colors from CategoryProvider instead
  List<String> _availableColors = [];

  @override
  void initState() {
    super.initState();
    print('? AddTaskDialog: initState() called');
    
    // Set the initial categoryId if provided
    if (widget.categoryId != null) {
      _selectedCategoryIds.add(widget.categoryId!);
    }
    
    // Set the initial date if provided, otherwise use current date
    _selectedDate = widget.initialDate ?? DateTime.now();
    
    // Use current time rounded to next 15 minutes as default time
    final now = TimeOfDay.now();
    final minute = (now.minute / 15).ceil() * 15 % 60;
    final hour = now.hour + ((now.minute / 15).ceil() * 15 / 60).floor();
    _selectedTime = TimeOfDay(hour: hour % 24, minute: minute);
    
    // Load available colors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAvailableColors();
    });
  }

  void _updateAvailableColors() {
    final categoryProvider = context.read<CategoryProvider>();
    setState(() {
      _availableColors = categoryProvider.getAvailableColors();
      // If no available colors, use the first predefined color
      if (_availableColors.isEmpty) {
        _availableColors = CategoryProvider.predefinedColors.take(5).toList();
      }
      // Set the initially selected color to the first available color
      if (_availableColors.isNotEmpty) {
        _selectedColor = _availableColors.first;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createNewCategory() async {
    if (_newCategoryController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      
      print('? AddTaskDialog: Creating new category: ${_newCategoryController.text}');
      final categoryProvider = context.read<CategoryProvider>();
      
      models.Category? newCategory; // Define newCategory outside the try-catch
      try {
        newCategory = await categoryProvider.createCategory(
          name: _newCategoryController.text,
          color: _selectedColor,
        );
      } catch (e) {
        print('? AddTaskDialog: Error creating category: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating category: $e')),
          );
        }
      }
      
      // Update state regardless of success/failure, but only add ID if successful
      setState(() {
        if (newCategory != null) {
          print('? AddTaskDialog: Created new category: ${newCategory.id} - ${newCategory.name}');
          // Ensure the list is modifiable before adding
          final updatedIds = List<String>.from(_selectedCategoryIds);
          if (!updatedIds.contains(newCategory.id)) { // Avoid duplicates
             updatedIds.add(newCategory.id);
          }
          _selectedCategoryIds = updatedIds; // Update the state variable
        }
        _isCreatingNewCategory = false;
        _newCategoryController.clear();
        _isLoading = false;
        print('? AddTaskDialog: Selected categories after creation: $_selectedCategoryIds');
      });
    }
  }

  void _addTag() {
    if (_tagController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _submitForm() async {
    print('? AddTaskDialog: _submitForm() - Starting form submission');
    
    // Use form validation through the formKey
    if (!_formKey.currentState!.validate()) {
      print('? AddTaskDialog: Form validation failed');
      return;
    }
    
    // Additionally check for required date and time
      if (_selectedDate == null || _selectedTime == null) {
      print('? AddTaskDialog: Missing date or time');
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).dueDate + ' ' + 
                              AppLocalizations.of(context).dueTime + ' ' + 
                              AppLocalizations.of(context).pleaseEnterTitle)),
        );
        return;
      }

    setState(() {
      _isSubmitting = true;
    });
    
    // Combine date and time into a single DateTime
    final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

    try {
      print('? AddTaskDialog: Creating task with title: "${_titleController.text.trim()}"');
      print('? AddTaskDialog: Categories: $_selectedCategoryIds');
      print('? AddTaskDialog: Due date: $combinedDateTime');
      
      // Get provider without listening to avoid rebuild during operation
      final todoProvider = Provider.of<TodoProvider>(context, listen: false);
      
      // Use the provider to create the task
      await todoProvider.createTodo(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        categoryIds: _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
        dueDate: combinedDateTime,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        priority: _priority > 0 ? _priority : null,
        tags: _tags.isNotEmpty ? _tags : null,
      );
      
      print('? AddTaskDialog: Task created successfully, closing dialog');
      
      // Close the dialog and return success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('? AddTaskDialog: ERROR creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final localizations = AppLocalizations.of(context);
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.addNewTask,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: localizations.title,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.pleaseEnterTitle;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: localizations.descriptionOptional,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: localizations.locationOptional,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    print('? AddTaskDialog: Consumer rebuilding, found ${categoryProvider.categories.length} categories');
                    
                    if (categoryProvider.isLoading || _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (categoryProvider.error != null) {
                      return Text('Error: ${categoryProvider.error}');
                    }

                    // Sort categories for better UX
                    final sortedCategories = List<models.Category>.from(categoryProvider.categories);
                    sortedCategories.sort((a, b) => a.name.compareTo(b.name));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isCreatingNewCategory) ...[
                          CategorySelector(
                            categories: sortedCategories,
                            selectedIds: _selectedCategoryIds,
                            isLoading: _isLoading,
                            onChanged: (selectedIds) {
                              setState(() {
                                _selectedCategoryIds = selectedIds;
                                print('Selected categories: $_selectedCategoryIds');
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  categoryProvider.loadCategories();
                                },
                                child: Text(localizations.refreshCategories),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isCreatingNewCategory = true;
                                  });
                                },
                                child: Text(localizations.newCategory),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _newCategoryController,
                            decoration: InputDecoration(
                              labelText: localizations.categoryName,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedColor,
                            decoration: InputDecoration(
                              labelText: localizations.categoryColor,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            isExpanded: true,
                            items: _availableColors.map((color) {
                              return DropdownMenuItem(
                                value: color,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _parseColor(color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        color,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedColor = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isCreatingNewCategory = false;
                                    _newCategoryController.clear();
                                  });
                                },
                                child: Text(localizations.cancel),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _createNewCategory,
                                child: Text(localizations.createCategory),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  children: [
                    TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : localizations.selectDate,
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                    TextButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : localizations.selectTime,
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ),
                if (_selectedDate == null || _selectedTime == null)
                  Text(
                    localizations.dueDate + ' ' + localizations.dueTime + ' ' + localizations.pleaseEnterTitle,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(localizations.cancel),
                    ),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(localizations.addTask),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
} 