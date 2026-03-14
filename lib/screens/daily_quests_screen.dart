import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/daily_quest.dart';
import '../services/storage_service.dart';
import '../services/level_progression_service.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen> {
  late List<DailyQuest> quests;
  int completedQuestCount = 0;
  final storage = StorageService();
  final levelService = LevelProgressionService();

  @override
  void initState() {
    super.initState();
    _initializeQuests();
  }

  void _initializeQuests() {
    quests = [
      DailyQuest(
        id: '1',
        title: AppStrings.wakeUpEarly,
        description: AppStrings.wakeUpEarlyDesc,
        category: AppStrings.categoryHealth,
        icon: '🌅',
        color: '#FF6B6B',
        xpReward: 50,
        difficulty: AppStrings.difficultyEasy,
        timeWindow: AppStrings.timeWindow6to10am,
      ),
      DailyQuest(
        id: '2',
        title: AppStrings.completeWorkout,
        description: AppStrings.completeWorkoutDesc,
        category: AppStrings.categoryHealth,
        icon: '💪',
        color: '#9F7AEA',
        xpReward: 100,
        difficulty: AppStrings.difficultyHard,
        timeWindow: AppStrings.timeWindow630to9am,
      ),
      DailyQuest(
        id: '3',
        title: AppStrings.studyInterview,
        description: AppStrings.studyInterviewDesc,
        category: AppStrings.categoryLearning,
        icon: '📚',
        color: '#00D9FF',
        xpReward: 75,
        difficulty: AppStrings.difficultyMedium,
        timeWindow: AppStrings.timeWindow2to5pm,
      ),
      DailyQuest(
        id: '4',
        title: AppStrings.readBook,
        description: AppStrings.readBookDesc,
        category: AppStrings.categoryLearning,
        icon: '📖',
        color: '#FFB74D',
        xpReward: 50,
        difficulty: AppStrings.difficultyEasy,
        timeWindow: AppStrings.timeWindow8to10pm,
      ),
    ];

    _loadQuestStatus();
  }

  Future<void> _loadQuestStatus() async {
    final today = DateTime.now();
    final savedQuestsJsonData = storage.getQuestData(today);
    if (savedQuestsJsonData != null) {
      final decodedQuestList = jsonDecode(savedQuestsJsonData) as List;
      for (var i = 0; i < quests.length; i++) {
        if (i < decodedQuestList.length) {
          quests[i].isCompleted = decodedQuestList[i]['isCompleted'] ?? false;
          if (decodedQuestList[i]['completedAt'] != null) {
            quests[i].completedAt = DateTime.parse(decodedQuestList[i]['completedAt']);
          }
        }
      }
    }

    _updateCompletedQuestCount();
  }

  Future<void> _toggleQuestCompletion(int index) async {
    final wasCompleted = quests[index].isCompleted;
    final xpReward = quests[index].xpReward;

    setState(() {
      quests[index].isCompleted = !quests[index].isCompleted;
      if (quests[index].isCompleted) {
        quests[index].completedAt = DateTime.now();
      } else {
        quests[index].completedAt = null;
      }
    });

    // Handle XP reward when quest is completed
    if (quests[index].isCompleted && !wasCompleted) {
      // Getting previous level for comparison
      final previousTotalXp = storage.getTotalXpEarned();
      final newTotalXp = previousTotalXp + xpReward;

      // Save the new XP total
      await storage.addTotalXpEarned(xpReward);

      // Check for level up
      final levelUpInfo = levelService.checkLevelUp(
        previousTotalXp: previousTotalXp,
        newTotalXp: newTotalXp,
      );

      // Show notifications
      if (mounted) {
        if (levelUpInfo['leveledUp'] as bool) {
          _showLevelUpNotification(levelUpInfo['newLevel'] as int);
        } else {
          _showXpGainedNotification(xpReward);
        }
      }
    } else if (!quests[index].isCompleted && wasCompleted) {
      // Quest was uncompleted - subtract XP
      await storage.addTotalXpEarned(-xpReward);
    }

    _updateCompletedQuestCount();
    await _saveQuestStatus();
  }

  void _updateCompletedQuestCount() {
    completedQuestCount = quests.where((q) => q.isCompleted).length;
  }

  Future<void> _saveQuestStatus() async {
    final today = DateTime.now();
    final questsJson = quests.map((q) => q.toJson()).toList();
    await storage.saveQuestData(today, jsonEncode(questsJson));
  }

  int _calculateTotalEarnedXp() {
    return quests.fold(
      0,
      (sum, quest) => quest.isCompleted ? sum + quest.xpReward : sum,
    );
  }

  void _showLevelUpNotification(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('⭐ ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Level Up!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'You reached Level $newLevel',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9F7AEA),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showXpGainedNotification(int xpAmount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('✨ ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                '+$xpAmount XP Gained!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00D9FF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          AppStrings.dailyQuests,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9F7AEA),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              children: [
                // Progress Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9F7AEA).withOpacity(0.3),
                        const Color(0xFF6B46C1).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9F7AEA).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completedQuestCount/${quests.length} Completed',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9F7AEA),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF00D9FF),
                                  Color(0xFF9F7AEA),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${_calculateTotalEarnedXp()} XP',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: quests.isEmpty
                              ? 0
                              : completedQuestCount / quests.length,
                          minHeight: 12,
                          backgroundColor: Colors.grey[900],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quests List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    return _buildQuestListCard(index);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestListCard(int index) {
    final quest = quests[index];
    final questAccentColor = Color(int.parse('0xFF${quest.color.replaceFirst('#', '')}'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            questAccentColor.withOpacity(0.15),
            questAccentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: questAccentColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleQuestCompletion(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: quest.isCompleted
                        ? LinearGradient(
                            colors: [
                              questAccentColor.withOpacity(0.8),
                              questAccentColor,
                            ],
                          )
                        : null,
                    border: quest.isCompleted
                        ? null
                        : Border.all(
                            color: questAccentColor,
                            width: 2,
                          ),
                  ),
                  child: Center(
                    child: quest.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : Text(quest.icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),

                // Quest Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: quest.isCompleted
                              ? Colors.white54
                              : Colors.white,
                          decoration: quest.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: questAccentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              quest.difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                color: questAccentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            quest.timeWindow,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // XP Reward
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${quest.xpReward}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: questAccentColor,
                      ),
                    ),
                    const Text(
                      'XP',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
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
}
