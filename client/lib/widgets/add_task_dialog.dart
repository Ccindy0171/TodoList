import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as models;
import 'package:intl/intl.dart';

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
  final _newCategoryController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategoryId;
  bool _isCreatingNewCategory = false;
  String _selectedColor = '#FF0000';
  bool _isLoading = false;

  final List<String> _predefinedColors = [
    '#FF0000', // Red
    '#00FF00', // Green
    '#0000FF', // Blue
    '#FFFF00', // Yellow
    '#FF00FF', // Magenta
    '#00FFFF', // Cyan
    '#FFA500', // Orange
    '#800080', // Purple
    '#008000', // Dark Green
    '#000080', // Navy Blue
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = const TimeOfDay(hour: 23, minute: 59);
    
    // Handle General category as null for the dropdown
    if (widget.categoryId == 'General') {
      _selectedCategoryId = null;
      print('? AddTaskDialog: Converting General category to null in initialization');
    } else {
      _selectedCategoryId = widget.categoryId;
    }
    
    // Force refresh categories when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('? AddTaskDialog: Refreshing categories on initialization');
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      await context.read<CategoryProvider>().createCategory(
        name: _newCategoryController.text,
        color: _selectedColor,
      );
      
      // Force refresh categories
      final categoryProvider = context.read<CategoryProvider>();
      
      // Select the newly created category
      final newCategory = categoryProvider.categories
          .where((cat) => cat.name == _newCategoryController.text)
          .firstOrNull;
      
      if (newCategory != null) {
        print('? AddTaskDialog: Found newly created category: ${newCategory.id} - ${newCategory.name}');
        setState(() {
          _selectedCategoryId = newCategory.id;
          _isCreatingNewCategory = false;
          _newCategoryController.clear();
          _isLoading = false;
        });
      } else {
        print('?? AddTaskDialog: Could not find newly created category');
        setState(() {
          _isCreatingNewCategory = false;
          _newCategoryController.clear();
          _isLoading = false;
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a due date and time')),
        );
        return;
      }

      DateTime dueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      print('? AddTaskDialog: Creating task with title: ${_titleController.text}, categoryId: $_selectedCategoryId');
      
      // CategoryId handling - pass explicit null for no category
      // This ensures we don't pass 'General' string as a categoryId
      String? categoryId = _selectedCategoryId;
      if (categoryId == 'General') {
        categoryId = null;
        print('? AddTaskDialog: Converting General category to null');
      }

      context.read<TodoProvider>().createTodo(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        categoryId: categoryId,
        dueDate: dueDate,
      ).then((_) {
        Navigator.of(context).pop(true); // Return true to indicate a task was created
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                    children: [
                      if (!_isCreatingNewCategory) ...[
                        DropdownButtonFormField<String?>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category (optional)',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...sortedCategories.map((category) {
                              return DropdownMenuItem<String?>(
                                value: category.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            category.color.replaceAll('#', '0xFF'),
                                          ),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                              print('Selected category: $_selectedCategoryId');
                            });
                          },
                          hint: const Text('Select a category (optional)'),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                categoryProvider.loadCategories();
                              },
                              child: const Text('Refresh Categories'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isCreatingNewCategory = true;
                                });
                              },
                              child: const Text('New Category'),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _newCategoryController,
                          decoration: const InputDecoration(
                            labelText: 'New Category Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedColor,
                          decoration: const InputDecoration(
                            labelText: 'Category Color',
                            border: OutlineInputBorder(),
                          ),
                          items: _predefinedColors.map((color) {
                            return DropdownMenuItem(
                              value: color,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(color.replaceAll('#', '0xFF')),
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(color),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedColor = value;
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
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _createNewCategory,
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                            : 'Select Date',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedDate == null || _selectedTime == null)
                const Text(
                  'Due date is required',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Add Task'),
        ),
      ],
    );
  }
} 