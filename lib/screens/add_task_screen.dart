import 'package:flutter/material.dart';
import '../models/daily_quest.dart';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../constants/colors.dart';
import 'dart:convert';
import 'dart:math';

class AddTaskScreen extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;
  final String? taskDescription;
  final DateTime? reminderDateTime;

  const AddTaskScreen({
    super.key,
    this.taskId,
    this.taskTitle,
    this.taskDescription,
    this.reminderDateTime,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  bool _reminderEnabled = false;
  DateTime? _selectedReminderDateTime;
  bool _isEditMode = false;
  
  // New for recurring reminders
  String _recurrenceOption = 'none'; // 'none', 'daily', 'weekly', 'monthly'
  bool _showRecurringOptions = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.taskId != null;
    _titleController = TextEditingController(text: widget.taskTitle ?? '');
    _descriptionController = TextEditingController(text: widget.taskDescription ?? '');
    _selectedReminderDateTime = widget.reminderDateTime;
    _reminderEnabled = _selectedReminderDateTime != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.darkBgSecondary,
              onPrimary: AppColors.darkBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final currentTime = _selectedReminderDateTime ?? DateTime.now();
        _selectedReminderDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          currentTime.hour,
          currentTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _selectedReminderDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.darkBgSecondary,
              onPrimary: AppColors.darkBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final currentDate = _selectedReminderDateTime ?? DateTime.now();
        _selectedReminderDateTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final taskId = _isEditMode ? widget.taskId! : (DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString());
      
      // Create task with minimal fields (defaults for removed fields)
      final newTask = DailyQuest(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: 'Personal', // Default category
        icon: '✏️', // Default icon
        color: '#FFB74D', // Default color
        xpReward: 50, // Default XP
        difficulty: 'Medium', // Default difficulty
        timeWindow: _selectedReminderDateTime != null
            ? _formatTimeWindow(_selectedReminderDateTime!)
            : 'Anytime', // Use reminder time or default
      );

      // Load existing quests for today
      final storage = StorageService();
      final today = DateTime.now();
      final savedQuestsJsonData = storage.getQuestData(today);
      
      List<dynamic> questsList = [];
      if (savedQuestsJsonData != null) {
        questsList = jsonDecode(savedQuestsJsonData);
      }

      if (_isEditMode) {
        // In edit mode, find and update the existing task
        final existingIndex = questsList.indexWhere((q) {
          final quest = q as Map<String, dynamic>;
          return quest['id'] == taskId;
        });
        if (existingIndex != -1) {
          questsList[existingIndex] = newTask.toJson();
        }
      } else {
        // In create mode, add new quest
        questsList.add(newTask.toJson());
      }

      // Save to daily quests
      await storage.saveQuestData(today, jsonEncode(questsList));

      // Handle reminders
      final savedRemindersJson = storage.getReminderData();
      List<dynamic> remindersList = [];
      if (savedRemindersJson != null) {
        remindersList = jsonDecode(savedRemindersJson);
      }

      // If reminder is enabled, create or update reminder(s)
      if (_reminderEnabled && _selectedReminderDateTime != null) {
        if (_isEditMode) {
          // In edit mode, remove all old reminders for this task
          remindersList.removeWhere((r) {
            final reminder = r as Map<String, dynamic>;
            return reminder['id'] == taskId || reminder['parentReminderId'] == taskId;
          });
        }

        // Create a single reminder with recurrence type
        final reminderToCreate = ReminderTask(
          id: taskId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: 'Medium',
          scheduledTime: _selectedReminderDateTime!,
          category: 'Personal',
          icon: '✏️',
          recurrence: _recurrenceOption,
          parentReminderId: null,
        );
        
        remindersList.add(reminderToCreate.toJson());
      } else if (_isEditMode) {
        // In edit mode, if reminder is disabled, remove the existing reminders
        remindersList.removeWhere((r) {
          final reminder = r as Map<String, dynamic>;
          return reminder['id'] == taskId || reminder['parentReminderId'] == taskId;
        });
      }

      // Save reminders
      await storage.saveReminderData(jsonEncode(remindersList));

        // Show success message
        if (mounted) {
          String recurrenceText = _recurrenceOption != 'none' 
              ? ' (Repeats ${_recurrenceOption})'
              : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Task "${newTask.title}" ${_isEditMode ? 'updated' : 'added'} successfully!$recurrenceText'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );

        // Close screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving task: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTimeWindow(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} - ${(dateTime.hour + 1).toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get most active time based on past completions
  int _getMostActiveHour() {
    final storage = StorageService();
    
    // Check last 7 days for completion times
    final hourCounts = <int, int>{};
    
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final questsJson = storage.getQuestData(date);
      if (questsJson != null) {
        final quests = jsonDecode(questsJson) as List;
        for (var quest in quests) {
          if (quest['isCompleted'] == true && quest['completedAt'] != null) {
            final completedAt = DateTime.parse(quest['completedAt']);
            final hour = completedAt.hour;
            hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
          }
        }
      }
    }
    
    // Return the hour with most completions, default to 9 AM
    if (hourCounts.isEmpty) return 9;
    
    int maxHour = 9;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        maxHour = hour;
      }
    });
    
    return maxHour;
  }

  void _selectQuickTime(int hour) {
    setState(() {
      final now = DateTime.now();
      _selectedReminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );
      
      // If selected time is in the past, move to next day
      if (_selectedReminderDateTime!.isBefore(DateTime.now())) {
        _selectedReminderDateTime = _selectedReminderDateTime!.add(const Duration(days: 1));
      }
    });
  }

  Widget _buildTimeSuggestionButton(String label, int hour) {
    final isSelected = _selectedReminderDateTime?.hour == hour;
    
    return GestureDetector(
      onTap: () => _selectQuickTime(hour),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonBlue.withOpacity(0.2)
              : AppColors.darkBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceOption(String label, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _recurrenceOption = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _recurrenceOption == value
              ? AppColors.neonBlue.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _recurrenceOption == value
                ? AppColors.neonBlue
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _recurrenceOption == value
                      ? AppColors.neonBlue
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: _recurrenceOption == value
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: _recurrenceOption == value
                    ? AppColors.neonBlue
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: _recurrenceOption == value
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgSecondary,
        title: Text(
          _isEditMode ? '✏️ Edit Task' : '⚔️ Create New Task',
          style: const TextStyle(
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Task Title Section
              Text(
                'Task Name',
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                maxLines: 1,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Enter task name',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  if (value.length > 100) {
                    return 'Task name must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Task Description Section
              Text(
                'Task Description',
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe your task...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.darkBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
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
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Reminder Toggle Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Reminder',
                    style: const TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                        if (value && _selectedReminderDateTime == null) {
                          _selectedReminderDateTime = DateTime.now().add(const Duration(hours: 1));
                        }
                      });
                    },
                    activeColor: AppColors.neonBlue,
                    activeTrackColor: AppColors.neonBlue.withOpacity(0.3),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.darkBgSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and Time Pickers (visible only when reminder is enabled)
              if (_reminderEnabled) ...[
                // Date Picker
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.neonBlue,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedReminderDateTime != null
                                  ? _formatDate(_selectedReminderDateTime!)
                                  : 'Select date',
                              style: const TextStyle(
                                color: AppColors.neonBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.neonBlue,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                // Time Picker
                GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.neonCyan,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _selectedReminderDateTime != null
                                  ? _formatTime(_selectedReminderDateTime!)
                                  : 'Select time',
                              style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.access_time,
                          color: AppColors.neonCyan,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                // Reminder Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: AppColors.darkBgSecondary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.neonBlue.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.neonBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedReminderDateTime != null
                              ? 'Reminder: ${_formatDate(_selectedReminderDateTime!)} at ${_formatTime(_selectedReminderDateTime!)}'
                              : 'Select date and time',
                          style: const TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Time Suggestions
                const SizedBox(height: 16),
                Text(
                  '⏰ Suggested Times',
                  style: const TextStyle(
                    color: AppColors.neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTimeSuggestionButton('Most Active', _getMostActiveHour()),
                    _buildTimeSuggestionButton('9 AM', 9),
                    _buildTimeSuggestionButton('12 PM', 12),
                    _buildTimeSuggestionButton('5 PM', 17),
                    _buildTimeSuggestionButton('8 PM', 20),
                  ],
                ),

                // Recurrence Section
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repeat Reminder?',
                          style: const TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recurrenceOption != 'none' 
                              ? 'Enabled: ${_recurrenceOption}'
                              : 'One-time reminder',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _recurrenceOption != 'none',
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _recurrenceOption = 'daily';
                            _showRecurringOptions = true;
                          } else {
                            _recurrenceOption = 'none';
                            _showRecurringOptions = false;
                          }
                        });
                      },
                      activeColor: AppColors.neonBlue,
                      activeTrackColor: AppColors.neonBlue.withOpacity(0.3),
                      inactiveThumbColor: AppColors.textSecondary,
                      inactiveTrackColor: AppColors.darkBgSecondary,
                    ),
                  ],
                ),

                // Recurrence Options
                if (_showRecurringOptions) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkBgSecondary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.neonBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildRecurrenceOption('Daily', 'daily'),
                        const SizedBox(height: 8),
                        _buildRecurrenceOption('Weekly', 'weekly'),
                        const SizedBox(height: 8),
                        _buildRecurrenceOption('Monthly', 'monthly'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.neonBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.neonBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recurring reminders will be created for the next 3 months',
                            style: TextStyle(
                              color: AppColors.neonBlue.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ]
              else
                const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    shadowColor: AppColors.neonBlue.withOpacity(0.5),
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditMode ? 'Update Task' : 'Save Task',
                    style: const TextStyle(
                      color: AppColors.darkBg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
}
