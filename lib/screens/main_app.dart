import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/reminder_task.dart';
import '../services/storage_service.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import 'daily_quests_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'hydration_dashboard_screen.dart';
import 'add_task_screen.dart';
import 'reminders_screen.dart';

class MainApp extends StatefulWidget {
  final String playerName;

  const MainApp({super.key, required this.playerName});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();
  final GlobalKey<RemindersScreenState> _remindersScreenKey = GlobalKey<RemindersScreenState>();
  int _overdueRemindersCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      HomeScreen(key: _homeScreenKey, playerName: widget.playerName),
      const DailyQuestsScreen(),
      HydrationDashboardScreen(playerName: widget.playerName),
      RemindersScreen(key: _remindersScreenKey),
      ProfileScreen(playerName: widget.playerName),
      const StatsScreen(),
    ];
    _loadOverdueCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOverdueCount();
    }
  }

  Future<void> _loadOverdueCount() async {
    try {
      final storage = StorageService();
      final savedRemindersJson = storage.getReminderData();
      int overdueCount = 0;

      if (savedRemindersJson != null) {
        final remindersList = jsonDecode(savedRemindersJson) as List;
        for (var reminderJson in remindersList) {
          final reminder = ReminderTask.fromJson(reminderJson);
          if (reminder.isOverdue() && !reminder.isCompleted) {
            overdueCount++;
          }
        }
      }

      setState(() {
        _overdueRemindersCount = overdueCount;
      });
    } catch (e) {
      print('Error loading overdue count: $e');
    }
  }

  void _onNavBarTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    
    // Refresh screen data when switching to it
    if (index == 0) {
      _homeScreenKey.currentState?.refreshPlayerLevel();
    } else if (index == 3) {
      // Refresh reminders when switching to reminders tab
      _remindersScreenKey.currentState?.refreshReminders();
    }
  }

  void _showQuickAddModal() {
    final titleController = TextEditingController();
    DateTime? selectedDateTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Text(
                    '⚡ Quick Add Task',
                    style: TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Task title input
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'What do you need to do?',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.darkBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.neonBlue),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick time buttons
                  const Text(
                    'When do you want to do it?',
                    style: TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Later Today
                      _buildQuickTimeButton(
                        label: 'Later Today',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          final now = DateTime.now();
                          selectedDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            now.hour + 2,
                          );
                          setModalState(() {});
                        },
                        isSelected: selectedDateTime != null &&
                            DateTime(
                              selectedDateTime!.year,
                              selectedDateTime!.month,
                              selectedDateTime!.day,
                            ) == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                      ),

                      // Tomorrow
                      _buildQuickTimeButton(
                        label: 'Tomorrow',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          final tomorrow = DateTime.now().add(const Duration(days: 1));
                          selectedDateTime = DateTime(
                            tomorrow.year,
                            tomorrow.month,
                            tomorrow.day,
                            9,
                          );
                          setModalState(() {});
                        },
                        isSelected: selectedDateTime != null &&
                            DateTime(
                              selectedDateTime!.year,
                              selectedDateTime!.month,
                              selectedDateTime!.day,
                            ) == DateTime(DateTime.now().add(const Duration(days: 1)).year, DateTime.now().add(const Duration(days: 1)).month, DateTime.now().add(const Duration(days: 1)).day),
                      ),

                      // This Week
                      _buildQuickTimeButton(
                        label: 'This Week',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          selectedDateTime = DateTime.now().add(const Duration(days: 3));
                          setModalState(() {});
                        },
                        isSelected: selectedDateTime != null &&
                            selectedDateTime!.isAfter(DateTime.now().add(const Duration(days: 2))) &&
                            selectedDateTime!.isBefore(DateTime.now().add(const Duration(days: 8))),
                      ),

                      // Custom
                      _buildQuickTimeButton(
                        label: 'Custom',
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTaskScreen(
                                taskTitle: titleController.text.isNotEmpty
                                    ? titleController.text
                                    : null,
                              ),
                            ),
                          );
                          return;
                        },
                        isSelected: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button (only if time selected and title entered)
                  if (selectedDateTime != null && titleController.text.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.heavyImpact();
                          await _saveQuickTask(titleController.text, selectedDateTime!);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            color: AppColors.darkBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickTimeButton({
    required String label,
    required Function() onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonBlue.withOpacity(0.3)
              : AppColors.darkBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.neonBlue : AppColors.textSecondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neonBlue : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuickTask(String title, DateTime reminderTime) async {
    try {
      final taskId = DateTime.now().millisecondsSinceEpoch.toString() +
          DateTime.now().microsecond.toString();

      final reminderTask = ReminderTask(
        id: taskId,
        title: title.trim(),
        description: '',
        priority: 'Medium',
        scheduledTime: reminderTime,
        category: 'Personal',
        icon: '✏️',
        isCompleted: false,
        completedAt: null,
        reminderSent: false,
      );

      final storage = StorageService();
      final savedRemindersJson = storage.getReminderData();
      List<dynamic> remindersList = [];
      if (savedRemindersJson != null) {
        remindersList = jsonDecode(savedRemindersJson);
      }

      remindersList.add(reminderTask.toJson());
      await storage.saveReminderData(jsonEncode(remindersList));

      // Update overdue count
      await _loadOverdueCount();

      // Immediately refresh the reminders screen data before navigating
      await _remindersScreenKey.currentState?.refreshReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task "$title" added!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to Reminders tab after data is loaded
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _onNavBarTap(3); // Navigate to Reminders tab (index 3)
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickAddModal();
        },
        backgroundColor: AppColors.neonBlue,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.darkBg,
          size: 28,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1a1a2e),
        selectedItemColor: const Color(0xFF00D9FF),
        unselectedItemColor: Colors.white54,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Quests',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (_overdueRemindersCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _overdueRemindersCount > 9 ? '9+' : '$_overdueRemindersCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Reminders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
