import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';
import 'add_task_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => RemindersScreenState();
}

class RemindersScreenState extends State<RemindersScreen> with WidgetsBindingObserver {
  List<ReminderTask> _reminders = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedDescriptions = {}; // Track which descriptions are expanded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReminders();
    }
  }

  Future<void> _loadReminders() async {
    try {
      final storage = StorageService();
      final savedRemindersJson = storage.getReminderData();

      if (savedRemindersJson != null) {
        final List<dynamic> remindersList = jsonDecode(savedRemindersJson);
        setState(() {
          _reminders = remindersList
              .map((r) => ReminderTask.fromJson(r as Map<String, dynamic>))
              .toList();
          // Sort by scheduled time (upcoming first)
          _reminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error loading reminders: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Public method for external access (e.g., from GlobalKey)
  Future<void> refreshReminders() async {
    await _loadReminders();
  }

  int getOverdueCount() {
    return _reminders.where((r) => r.isOverdue() && !r.isCompleted).length;
  }

  Future<void> _deleteReminder(ReminderTask reminder) async {
    try {
      final storage = StorageService();
      _reminders.removeWhere((r) => r.id == reminder.id);

      await storage.saveReminderData(jsonEncode(
        _reminders.map((r) => r.toJson()).toList(),
      ));

      // Cancel the notification
      await NotificationService()
          .cancelNotification(reminder.id.hashCode);

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reminder "${reminder.title}" deleted'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeReminder(ReminderTask reminder) async {
    try {
      final reminderIndex =
          _reminders.indexWhere((r) => r.id == reminder.id);

      if (reminderIndex != -1) {
        _reminders[reminderIndex].isCompleted = true;
        _reminders[reminderIndex].completedAt = DateTime.now();

        final storage = StorageService();
        await storage.saveReminderData(jsonEncode(
          _reminders.map((r) => r.toJson()).toList(),
        ));

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Reminder "${reminder.title}" marked complete'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Handler for overflow menu actions
  Future<void> _handleRemindersMenuAction(
      String action, ReminderTask reminder) async {
    _triggerHapticFeedback();
    
    switch (action) {
      case 'complete':
        await _completeReminder(reminder);
        break;
      case 'edit':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(
              taskId: reminder.id,
              taskTitle: reminder.title,
              taskDescription: reminder.description,
              reminderDateTime: reminder.scheduledTime,
            ),
          ),
        );
        if (result == true) {
          _loadReminders();
        }
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.darkBgSecondary,
            title: const Text(
              'Delete Reminder?',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              'Are you sure you want to delete "${reminder.title}"?',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.neonBlue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteReminder(reminder);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
        break;
    }
  }

  // Haptic feedback for interactions
  Future<void> _triggerHapticFeedback() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Haptic feedback not available on some devices
      print('Haptic feedback not available: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgSecondary,
        title: const Text(
          '🔔 Reminders',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          if (_reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonBlue, width: 1),
                  ),
                  child: Text(
                    '${_reminders.length} reminders',
                    style: const TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            )
          : _reminders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  color: AppColors.neonBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final isOverdue = reminder.isOverdue();
                      final isCompleted = reminder.isCompleted;
                      final isToday = reminder.scheduledTime.year == DateTime.now().year &&
                          reminder.scheduledTime.month == DateTime.now().month &&
                          reminder.scheduledTime.day == DateTime.now().day;

                      return Dismissible(
                        key: Key(reminder.id),
                        direction: DismissDirection.horizontal,
                        // Swipe right to mark as complete
                        onDismissed: (direction) async {
                          final reminderIndex = _reminders.indexOf(reminder);
                          // Remove immediately to dismiss the widget
                          _reminders.removeAt(reminderIndex);
                          setState(() {});
                          
                          if (direction == DismissDirection.startToEnd) {
                            await _completeReminderSilent(reminder);
                          } else if (direction == DismissDirection.endToStart) {
                            await _deleteReminderWithUndo(reminder, reminderIndex);
                          }
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                          ),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.delete, color: Colors.white, size: 28),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.darkBgSecondary
                                : isOverdue
                                    ? AppColors.error.withOpacity(0.15)
                                    : isToday
                                        ? const Color(0xFFFFB74D).withOpacity(0.1)
                                        : AppColors.darkBgSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.textSecondary
                                  : isOverdue
                                      ? AppColors.error
                                      : isToday
                                          ? const Color(0xFFFFB74D)
                                          : AppColors.neonBlue,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Compact Header Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status indicator (left edge)
                                    Container(
                                      width: 4,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? AppColors.success
                                            : isOverdue
                                                ? AppColors.error
                                                : isToday
                                                    ? const Color(0xFFFFB74D)
                                                    : AppColors.neonBlue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Title and time
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title with icon
                                          Row(
                                            children: [
                                              Text(
                                                reminder.icon,
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  reminder.title,
                                                  style: TextStyle(
                                                    color: isCompleted
                                                        ? AppColors.textSecondary
                                                        : AppColors.textPrimary,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Time and status
                                          Row(
                                            children: [
                                              Text(
                                                '⏰ ${_formatDateTime(reminder.scheduledTime)}',
                                                style: TextStyle(
                                                  color: isOverdue && !isCompleted
                                                      ? AppColors.error
                                                      : isToday
                                                          ? const Color(0xFFFFB74D)
                                                          : AppColors.neonBlue,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              if (isCompleted)
                                                const Icon(Icons.check_circle,
                                                    color: AppColors.success, size: 14),
                                              if (isOverdue && !isCompleted)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error,
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                  child: const Text(
                                                    '⚠',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Overflow menu
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        _handleRemindersMenuAction(value, reminder);
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          if (!isCompleted)
                                            const PopupMenuItem<String>(
                                              value: 'complete',
                                              child: Row(
                                                children: [
                                                  Text('✅ Mark Done',
                                                      style: TextStyle(fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Text('✏️ Edit',
                                                    style: TextStyle(fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Text('🗑️ Delete',
                                                    style: TextStyle(
                                                        fontSize: 13, color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                      offset: const Offset(0, 40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      tooltip: 'More options',
                                    ),
                                  ],
                                ),
                                // Collapsible Description
                                if (reminder.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, left: 0, right: 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _triggerHapticFeedback();
                                            setState(() {
                                              _expandedDescriptions[reminder.id] =
                                                  !(_expandedDescriptions[reminder.id] ??
                                                      false);
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                _expandedDescriptions[reminder.id] ??
                                                        false
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                color: AppColors.textSecondary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Details',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_expandedDescriptions[reminder.id] ??
                                            false)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.darkBg
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                reminder.description,
                                                style: TextStyle(
                                                  color: isCompleted
                                                      ? AppColors.textSecondary
                                                      : AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                // Compact tags row
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(
                                                  reminder.priority)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          reminder.priority,
                                          style: TextStyle(
                                            color: _getPriorityColor(
                                                reminder.priority),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.neonBlue
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          reminder.category,
                                          style: const TextStyle(
                                            color: AppColors.neonBlue,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      if (reminder.recurrence != 'none' &&
                                          reminder.recurrence != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB74D)
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'Repeats ${reminder.recurrence}',
                                            style: const TextStyle(
                                              color: Color(0xFFFFB74D),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🔔',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 64,
                ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reminders Yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first reminder using the + button',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day;
    final month = dateTime.month;
    final year = dateTime.year;

    return '$day/$month/$year $hour:$minute';
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDueDateLabel(ReminderTask reminder) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDate = DateTime(
      reminder.scheduledTime.year,
      reminder.scheduledTime.month,
      reminder.scheduledTime.day,
    );

    if (scheduledDate == today) {
      return '🟡 Due today';
    } else if (scheduledDate == tomorrow) {
      return '🟢 Tomorrow';
    } else if (scheduledDate.isBefore(today)) {
      return '🔴 Overdue';
    } else {
      return '🟢 Upcoming';
    }
  }

  Future<void> _deleteReminderWithUndo(ReminderTask reminder, int originalIndex) async {
    try {
      final storage = StorageService();

      await storage.saveReminderData(jsonEncode(
        _reminders.map((r) => r.toJson()).toList(),
      ));

      // Cancel the notification
      await NotificationService()
          .cancelNotification(reminder.id.hashCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reminder "${reminder.title}" deleted'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                // Restore the reminder
                _reminders.insert(originalIndex, reminder);
                await storage.saveReminderData(jsonEncode(
                  _reminders.map((r) => r.toJson()).toList(),
                ));
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Reminder restored'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeReminderSilent(ReminderTask reminder) async {
    try {
      reminder.isCompleted = true;
      reminder.completedAt = DateTime.now();

      final storage = StorageService();
      await storage.saveReminderData(jsonEncode(
        _reminders.map((r) => r.toJson()).toList(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reminder "${reminder.title}" marked complete'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating reminder: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
