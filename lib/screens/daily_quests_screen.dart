import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/colors.dart';
import '../models/daily_quest.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({super.key});

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen> {
  late List<DailyQuest> quests;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeQuests();
  }

  void _initializeQuests() {
    quests = [
      DailyQuest(
        id: '1',
        title: 'Wake Up at 6 AM',
        description: 'Start your day early and energized',
        category: 'Health',
        icon: '🌅',
        color: '#FF6B6B',
        xpReward: 50,
        difficulty: 'Easy',
        timeWindow: '6:00 AM - 10:00 AM',
      ),
      DailyQuest(
        id: '2',
        title: 'Complete Workout',
        description: 'Do 30-45 minutes of exercise',
        category: 'Health',
        icon: '💪',
        color: '#9F7AEA',
        xpReward: 100,
        difficulty: 'Hard',
        timeWindow: '6:30 AM - 9:00 AM',
      ),
      DailyQuest(
        id: '3',
        title: 'Study for Interview',
        description: 'Prepare for upcoming interviews',
        category: 'Learning',
        icon: '📚',
        color: '#00D9FF',
        xpReward: 75,
        difficulty: 'Medium',
        timeWindow: '2:00 PM - 5:00 PM',
      ),
      DailyQuest(
        id: '4',
        title: 'Read Book',
        description: 'Read for 30 minutes',
        category: 'Learning',
        icon: '📖',
        color: '#FFB74D',
        xpReward: 50,
        difficulty: 'Easy',
        timeWindow: '8:00 PM - 10:00 PM',
      ),
    ];

    _loadQuestStatus();
  }

  Future<void> _loadQuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = 'quests_${today.year}_${today.month}_${today.day}';

    final savedQuestsJson = prefs.getString(dateKey);
    if (savedQuestsJson != null) {
      final savedQuests = jsonDecode(savedQuestsJson) as List;
      for (var i = 0; i < quests.length; i++) {
        if (i < savedQuests.length) {
          quests[i].isCompleted = savedQuests[i]['isCompleted'] ?? false;
          if (savedQuests[i]['completedAt'] != null) {
            quests[i].completedAt = DateTime.parse(savedQuests[i]['completedAt']);
          }
        }
      }
    }

    _updateCompletedCount();
  }

  Future<void> _toggleQuestComplete(int index) async {
    setState(() {
      quests[index].isCompleted = !quests[index].isCompleted;
      if (quests[index].isCompleted) {
        quests[index].completedAt = DateTime.now();
      } else {
        quests[index].completedAt = null;
      }
    });

    _updateCompletedCount();
    await _saveQuestStatus();
  }

  void _updateCompletedCount() {
    completedCount = quests.where((q) => q.isCompleted).length;
  }

  Future<void> _saveQuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = 'quests_${today.year}_${today.month}_${today.day}';

    final questsJson = quests.map((q) => q.toJson()).toList();
    await prefs.setString(dateKey, jsonEncode(questsJson));
  }

  int _getTotalXP() {
    return quests.fold(
      0,
      (sum, quest) => quest.isCompleted ? sum + quest.xpReward : sum,
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
          'Daily Quests',
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
                            '$completedCount/${quests.length} Completed',
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
                              '+${_getTotalXP()} XP',
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
                              : completedCount / quests.length,
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
                    return _buildQuestCard(index);
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

  Widget _buildQuestCard(int index) {
    final quest = quests[index];
    final color = Color(int.parse('0xFF${quest.color.replaceFirst('#', '')}'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleQuestComplete(index),
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
                              color.withOpacity(0.8),
                              color,
                            ],
                          )
                        : null,
                    border: quest.isCompleted
                        ? null
                        : Border.all(
                            color: color,
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
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              quest.difficulty,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
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
                        color: color,
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
