import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../constants/colors.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<ReminderTask> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.darkBgSecondary
                              : isOverdue
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.darkBgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.textSecondary
                                : isOverdue
                                    ? AppColors.error
                                    : AppColors.neonBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Priority
                              Row(
                                children: [
                                  Text(
                                    reminder.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.title,
                                          style: TextStyle(
                                            color: isCompleted
                                                ? AppColors.textSecondary
                                                : AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getPriorityColor(
                                                        reminder.priority)
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                reminder.priority,
                                                style: TextStyle(
                                                  color: _getPriorityColor(
                                                      reminder.priority),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.neonBlue
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                reminder.category,
                                                style: const TextStyle(
                                                  color: AppColors.neonBlue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 24,
                                      ),
                                    ),
                                  if (isOverdue && !isCompleted)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.warning,
                                        color: AppColors.error,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),

                              // Description
                              if (reminder.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    reminder.description,
                                    style: TextStyle(
                                      color: isCompleted
                                          ? AppColors.textSecondary
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              // Time info
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '⏰ ${_formatDateTime(reminder.scheduledTime)}',
                                      style: TextStyle(
                                        color: isOverdue && !isCompleted
                                            ? AppColors.error
                                            : AppColors.neonBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      reminder.getScheduledTimeDisplay(),
                                      style: TextStyle(
                                        color: isOverdue && !isCompleted
                                            ? AppColors.error
                                            : AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action buttons
                              if (!isCompleted)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            _completeReminder(reminder),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.success.withOpacity(
                                                  0.2),
                                          side: const BorderSide(
                                            color: AppColors.success,
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          '✅ Mark Done',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor:
                                                  AppColors.darkBgSecondary,
                                              title: const Text(
                                                'Delete Reminder?',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete "${reminder.title}"?',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.neonBlue,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteReminder(reminder);
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error
                                              .withOpacity(0.2),
                                          side: const BorderSide(
                                            color: AppColors.error,
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          '🗑️ Delete',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
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
}
