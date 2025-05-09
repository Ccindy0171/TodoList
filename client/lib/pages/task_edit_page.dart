import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart' as models;
import 'package:intl/intl.dart';

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
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _locationController = TextEditingController(text: widget.task.location ?? '');
    
    if (widget.task.dueDate != null) {
      _selectedDate = DateTime(
        widget.task.dueDate!.year,
        widget.task.dueDate!.month,
        widget.task.dueDate!.day,
      );
      _selectedTime = TimeOfDay(
        hour: widget.task.dueDate!.hour,
        minute: widget.task.dueDate!.minute,
      );
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
    
    _selectedCategoryId = widget.task.category?.id;
    
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

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        // Combine date and time into a single DateTime
        final DateTime dueDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        // Call the update method in TodoProvider
        await context.read<TodoProvider>().updateTodo(
          id: widget.task.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          categoryId: _selectedCategoryId,
          dueDate: dueDate,
          location: _locationController.text.isEmpty ? null : _locationController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate task was updated
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
            onPressed: _saveTask,
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

                      return DropdownButtonFormField<String?>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
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
                                      color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
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