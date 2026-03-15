import 'package:flutter/material.dart';
import '../models/daily_quest.dart';
import '../services/storage_service.dart';
import '../constants/colors.dart';
import 'dart:convert';
import 'dart:math';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  String _selectedCategory = 'Health';
  String _selectedDifficulty = 'Easy';
  String _selectedTimeWindow = '6:00 AM - 10:00 AM';
  int _xpReward = 50;
  String _selectedIcon = '⭐';

  final List<String> _categories = ['Health', 'Learning', 'Wellness', 'Personal'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _timeWindows = [
    '6:00 AM - 10:00 AM',
    '6:30 AM - 9:00 AM',
    '2:00 PM - 5:00 PM',
    '8:00 PM - 10:00 PM',
    'Anytime',
  ];
  
  final List<String> _iconOptions = [
    '⭐', '💪', '📚', '📖', '🎯', '💼', '🎨', '🏃', 
    '🧘', '📝', '🎵', '⚽', '🎮', '🍎', '💡', '🌟'
  ];

  final Map<String, String> _categoryColors = {
    'Health': '#FF6B6B',
    'Learning': '#00D9FF',
    'Wellness': '#9F7AEA',
    'Personal': '#FFB74D',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final newTask = DailyQuest(
        id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(10000).toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        icon: _selectedIcon,
        color: _categoryColors[_selectedCategory] ?? '#00D9FF',
        xpReward: _xpReward,
        difficulty: _selectedDifficulty,
        timeWindow: _selectedTimeWindow,
      );

      // Load existing quests for today
      final storage = StorageService();
      final today = DateTime.now();
      final savedQuestsJsonData = storage.getQuestData(today);
      
      List<dynamic> questsList = [];
      if (savedQuestsJsonData != null) {
        questsList = jsonDecode(savedQuestsJsonData);
      }

      // Add new quest as JSON
      questsList.add(newTask.toJson());

      // Save back to storage
      await storage.saveQuestData(today, jsonEncode(questsList));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Task "${newTask.title}" added successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'Health';
          _selectedDifficulty = 'Easy';
          _selectedTimeWindow = '6:00 AM - 10:00 AM';
          _xpReward = 50;
          _selectedIcon = '⭐';
        });

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
            content: Text('❌ Error adding task: $e'),
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
          '⚔️ Create New Task',
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
              _buildSectionLabel('📛 Task Title'),
              _buildTextFormField(
                controller: _titleController,
                hintText: 'Enter task title (e.g., "Go for a run")',
                icon: Icons.title,
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
              _buildSectionLabel('📝 Description'),
              _buildTextFormField(
                controller: _descriptionController,
                hintText: 'Describe your task...',
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
              _buildSectionLabel('🎨 Select Icon'),
              _buildIconSelector(),
              const SizedBox(height: 20),

              // Category Selection
              _buildSectionLabel('🏷️ Category'),
              _buildDropdown(
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 20),

              // Difficulty Selection
              _buildSectionLabel('⚔️ Difficulty'),
              _buildDifficultySelector(),
              const SizedBox(height: 20),

              // Time Window Selection
              _buildSectionLabel('⏰ Time Window'),
              _buildDropdown(
                value: _selectedTimeWindow,
                items: _timeWindows,
                onChanged: (value) {
                  setState(() => _selectedTimeWindow = value);
                },
              ),
              const SizedBox(height: 20),

              // XP Reward
              _buildSectionLabel('⭐ XP Reward: $_xpReward XP'),
              _buildXPSlider(),
              const SizedBox(height: 30),

              // Task Preview
              _buildTaskPreview(),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    shadowColor: AppColors.neonBlue.withOpacity(0.5),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '✅ Save Task',
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonBlue, width: 1),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.darkBgSecondary,
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _difficulties.map((difficulty) {
        final isSelected = _selectedDifficulty == difficulty;
        final color = difficulty == 'Easy'
            ? Colors.green
            : difficulty == 'Medium'
                ? Colors.orange
                : Colors.red;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedDifficulty = difficulty);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.3) : AppColors.darkBgSecondary,
              border: Border.all(
                color: isSelected ? color : AppColors.neonBlue,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              difficulty,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
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
        itemCount: _iconOptions.length,
        itemBuilder: (context, index) {
          final icon = _iconOptions[index];
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

  Widget _buildXPSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
          ),
          child: Slider(
            value: _xpReward.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: AppColors.neonBlue,
            inactiveColor: AppColors.textSecondary.withOpacity(0.3),
            onChanged: (value) {
              setState(() => _xpReward = value.round());
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '10 XP',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
            ),
            Text(
              '500 XP',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskPreview() {
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
                      _titleController.text.isEmpty ? 'Task Title' : _titleController.text,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_selectedDifficulty == 'Easy'
                                    ? Colors.green
                                    : _selectedDifficulty == 'Medium'
                                        ? Colors.orange
                                        : Colors.red)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _selectedDifficulty,
                            style: TextStyle(
                              color: _selectedDifficulty == 'Easy'
                                  ? Colors.green
                                  : _selectedDifficulty == 'Medium'
                                      ? Colors.orange
                                      : Colors.red,
                              fontSize: 12,
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
          Text(
            _descriptionController.text.isEmpty
                ? 'Task description will appear here'
                : _descriptionController.text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTimeWindow,
                style: const TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '⭐ $_xpReward XP',
                  style: const TextStyle(
                    color: AppColors.neonBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
