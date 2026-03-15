import 'package:flutter/material.dart';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import 'dart:convert';
import 'dart:math';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'Work';
  String _selectedPriority = 'Medium';
  String _selectedIcon = '📋';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  final List<String> _categories = ['Work', 'Personal', 'Health', 'Other'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  final Map<String, String> _categoryIcons = {
    'Work': '💼',
    'Personal': '👤',
    'Health': '🏥',
    'Other': '📌',
  };

  final Map<String, String> _priorityIcons = {
    'Low': '🟢',
    'Medium': '🟡',
    'High': '🔴',
  };

  final List<String> _allIcons = [
    '📞', '💼', '📧', '📝', '🎯', '💡', '⏰', '🔔',
    '👤', '🏢', '✉️', '📋', '🗂️', '📌', '🎁', '⚡'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedIcon = _categoryIcons[_selectedCategory] ?? '📋';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppColors.neonBlue,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.darkBgSecondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              primaryColor: AppColors.neonBlue,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.neonBlue,
                surface: AppColors.darkBgSecondary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Create a numeric ID for notifications
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          Random().nextInt(100000);

      final newReminder = ReminderTask(
        id: notificationId.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        scheduledTime: _selectedDateTime,
        category: _selectedCategory,
        icon: _selectedIcon,
      );

      // Load existing reminders
      final storage = StorageService();
      final savedRemindersJson = storage.getReminderData();

      List<dynamic> remindersList = [];
      if (savedRemindersJson != null) {
        remindersList = jsonDecode(savedRemindersJson);
      }

      // Add new reminder
      remindersList.add(newReminder.toJson());

      // Save to storage
      await storage.saveReminderData(jsonEncode(remindersList));

      // Schedule notification for the reminder time
      final notificationService = NotificationService();
      final timeUntilReminder =
          newReminder.scheduledTime.difference(DateTime.now());

      if (timeUntilReminder.isNegative) {
        // If the time is in the past, show immediately
        await notificationService.sendHydrationReminder(
          title: '⏰ Reminder: ${newReminder.title}',
          body: newReminder.description,
          notificationId: notificationId,
          payload: 'reminder:${newReminder.id}',
        );
      } else {
        // Schedule for future time
        await notificationService.scheduleNotificationWithExactAlarm(
          id: notificationId,
          title: '⏰ Reminder: ${newReminder.title}',
          body: newReminder.description,
          scheduledTime: newReminder.scheduledTime,
          channelId: 'custom_tasks',
          payload: 'reminder:${newReminder.id}',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Reminder "${newReminder.title}" set for ${_formatDateTime(newReminder.scheduledTime)}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'Work';
          _selectedPriority = 'Medium';
          _selectedIcon = _categoryIcons[_selectedCategory] ?? '📋';
          _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
        });

        // Close after brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day;
    final month = dateTime.month;
    final year = dateTime.year;

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgSecondary,
        title: const Text(
          '🔔 Create Reminder',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neonBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title
              _buildSectionLabel('🎯 What do you need to do?'),
              _buildTextFormField(
                controller: _titleController,
                hintText: 'e.g., "Call manager", "Buy groceries"',
                icon: Icons.task_alt,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task title';
                  }
                  if (value.length > 100) {
                    return 'Title must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Task Description
              _buildSectionLabel('📝 Details (Optional)'),
              _buildTextFormField(
                controller: _descriptionController,
                hintText: 'Add more details about this task...',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Icon Selection
              _buildSectionLabel('🎨 Icon'),
              _buildIconSelector(),
              const SizedBox(height: 20),

              // Category Selection
              _buildSectionLabel('🏷️ Category'),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Priority Selection
              _buildSectionLabel('⚡ Priority'),
              _buildPrioritySelector(),
              const SizedBox(height: 20),

              // Date & Time Selection
              _buildSectionLabel('⏰ When do you need this reminder?'),
              _buildDateTimeSelector(),
              const SizedBox(height: 30),

              // Reminder Preview
              _buildReminderPreview(),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    shadowColor: AppColors.neonBlue.withOpacity(0.5),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '✅ Set Reminder',
                    style: TextStyle(
                      color: AppColors.darkBg,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.neonBlue,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.neonBlue),
        filled: true,
        fillColor: AppColors.darkBgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonBlue, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonBlue, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonCyan, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonBlue, width: 1),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: _allIcons.length,
        itemBuilder: (context, index) {
          final icon = _allIcons[index];
          final isSelected = _selectedIcon == icon;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedIcon = icon);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.neonBlue.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        final icon = _categoryIcons[category] ?? '📌';

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
              _selectedIcon = icon;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.neonBlue.withOpacity(0.2) : AppColors.darkBgSecondary,
              border: Border.all(
                color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _priorities.map((priority) {
        final isSelected = _selectedPriority == priority;
        final priorityIcon = _priorityIcons[priority] ?? '⭕';
        final priorityColor = priority == 'High'
            ? Colors.red
            : priority == 'Medium'
                ? Colors.orange
                : Colors.green;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedPriority = priority);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? priorityColor.withOpacity(0.2) : AppColors.darkBgSecondary,
              border: Border.all(
                color: isSelected ? priorityColor : AppColors.textSecondary,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priorityIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  priority,
                  style: TextStyle(
                    color: isSelected ? priorityColor : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSelector() {
    final timeRemaining = _selectedDateTime.difference(DateTime.now());
    String timeText;

    if (timeRemaining.isNegative) {
      timeText = 'In the past';
    } else if (timeRemaining.inHours < 1) {
      timeText = '${timeRemaining.inMinutes} minutes from now';
    } else if (timeRemaining.inHours < 24) {
      timeText = '${timeRemaining.inHours} hours from now';
    } else {
      timeText = '${timeRemaining.inDays} days from now';
    }

    return GestureDetector(
      onTap: _selectDateTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkBgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonBlue, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.neonBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateTime(_selectedDateTime),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: AppColors.neonBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPreview() {
    final priorityColor = _selectedPriority == 'High'
        ? Colors.red
        : _selectedPriority == 'Medium'
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonBlue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _selectedIcon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isEmpty
                          ? 'Reminder Title'
                          : _titleController.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedCategory,
                            style: const TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedPriority,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_descriptionController.text.isNotEmpty)
            Text(
              _descriptionController.text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (_descriptionController.text.isNotEmpty)
            const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '⏰ ${_formatDateTime(_selectedDateTime)}',
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
