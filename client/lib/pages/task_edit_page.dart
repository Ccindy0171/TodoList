import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as models;
import 'package:intl/intl.dart';
import '../widgets/category_selector.dart';
import '../l10n/app_localizations.dart';
import '../utils/encoding_helper.dart';

class TaskEditPage extends StatefulWidget {
  final Todo task;

  const TaskEditPage({
    super.key,
    required this.task,
  });

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedCategoryIds = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    if (widget.task.description != null) {
      _descriptionController.text = widget.task.description!;
    }
    if (widget.task.location != null) {
      _locationController.text = widget.task.location!;
    }
    
    if (widget.task.dueDate != null) {
      _selectedDate = widget.task.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task.dueDate!);
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
    
    _selectedCategoryIds = [];
    
    if (widget.task.category != null) {
      _selectedCategoryIds.add(widget.task.category!.id);
    }
    
    if (widget.task.categories != null) {
      for (final category in widget.task.categories!) {
        if (!_selectedCategoryIds.contains(category.id)) {
          _selectedCategoryIds.add(category.id);
        }
      }
    }
    
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;
    
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
      DateTime dueDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

      final todoProvider = context.read<TodoProvider>();
      await todoProvider.updateTodo(
          id: widget.task.id,
        title: EncodingHelper.ensureUtf8(_titleController.text),
        description: _descriptionController.text.isEmpty ? null : 
            EncodingHelper.ensureUtf8(_descriptionController.text),
        categoryIds: _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds,
          dueDate: dueDate,
        location: _locationController.text.isEmpty ? null : 
            EncodingHelper.ensureUtf8(_locationController.text),
        completed: widget.task.completed,
        );

        if (mounted) {
        Navigator.of(context).pop(true); // return true to indicate success
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateTask,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
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
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      hintText: 'Add a detailed description (optional)',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      hintText: 'Add a location (optional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and Time
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedDate != null 
                                  ? dateFormat.format(_selectedDate!) 
                                  : 'Select a date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedTime != null 
                                  ? _selectedTime!.format(context) 
                                  : 'Select a time',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Category
                  Consumer<CategoryProvider>(
                    builder: (context, categoryProvider, child) {
                      if (categoryProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sortedCategories = List<models.Category>.from(categoryProvider.categories);
                      sortedCategories.sort((a, b) => a.name.compareTo(b.name));

                      return CategorySelector(
                        categories: sortedCategories,
                        selectedIds: _selectedCategoryIds,
                        isLoading: categoryProvider.isLoading,
                        onChanged: (selectedIds) {
                          setState(() {
                            _selectedCategoryIds = selectedIds;
                          });
                        },
                      );
                    },
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Completion status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        widget.task.completed 
                            ? Icons.check_circle 
                            : Icons.radio_button_unchecked,
                        color: widget.task.completed ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        widget.task.completed ? 'Completed' : 'Not completed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.task.completed ? Colors.green : Colors.grey,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          context.read<TodoProvider>().toggleTodo(widget.task.id).then((_) {
                            Navigator.pop(context, true); // Return to previous screen and refresh
                          });
                        },
                        child: Text(
                          widget.task.completed ? 'Mark as incomplete' : 'Mark as complete',
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Delete button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text('Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<TodoProvider>().deleteTodo(widget.task.id).then((_) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(context, true); // Return to previous screen and refresh
                                });
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Task'),
                  ),
                ],
              ),
            ),
    );
  }
} 