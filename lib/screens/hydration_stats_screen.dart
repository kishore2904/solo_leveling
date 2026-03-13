import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hydration_log.dart';
import '../models/hydration_goal.dart';
import '../models/hydration_score.dart';

class HydrationStatsScreen extends StatefulWidget {
  const HydrationStatsScreen({super.key});

  @override
  State<HydrationStatsScreen> createState() => _HydrationStatsScreenState();
}

class _HydrationStatsScreenState extends State<HydrationStatsScreen> {
  late SharedPreferences prefs;
  HydrationGoal? goal;
  List<HydrationLog> allLogs = [];
  
  String selectedPeriod = 'Week'; // Week, Month

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    final goalJson = prefs.getString('hydration_goal');
    
    // Load all logs (if implemented)
    if (goalJson != null) {
      setState(() {
        goal = HydrationGoal.fromJson(jsonDecode(goalJson));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E27),
        elevation: 0,
        title: const Text(
          '📊 Hydration Stats',
          style: TextStyle(
            color: Color(0xFF00D9FF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Period Selector
            _buildPeriodSelector(),
            const SizedBox(height: 24),

            // Overview Cards
            _buildOverviewCards(),
            const SizedBox(height: 24),

            // Weekly Chart
            _buildWeeklyChart(),
            const SizedBox(height: 24),

            // Insights
            _buildInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildPeriodButton('Week'),
          _buildPeriodButton('Month'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label) {
    final isSelected = selectedPeriod == label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedPeriod = label),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF00D9FF), width: 1)
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00D9FF)
                    : const Color(0xFFB0B0B0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Days Goal Met',
                '6/7',
                '🎯',
                const Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Daily Intake',
                '2.4L',
                '💧',
                const Color(0xFF00F0FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Consistency',
                '86%',
                '🔥',
                const Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Score',
                '82',
                '⭐',
                const Color(0xFF00F0FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
              Text(icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [85, 92, 100, 78, 100, 95, 88]; // Percentage
    final maxValue = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Progress',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                days.length,
                (index) => Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getBarColor(values[index]),
                                _getBarColor(values[index])
                                    .withOpacity(0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              if (values[index] >= 90)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${values[index]}%',
                                    style: const TextStyle(
                                      color: Color(0xFF0A0E27),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Goal line indicator
          Row(
            children: [
              Container(
                width: 12,
                height: 2,
                color: const Color(0xFF00D9FF),
              ),
              const SizedBox(width: 8),
              const Text(
                'Goal Met',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121B3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Smart Insights',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Best Time to Drink',
            'You drink most water in the afternoon (2 PM - 4 PM). Keep this up! ☀️',
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Hydration Pattern',
            'Your intake is well-distributed. Maintain consistency on weekdays. 📊',
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Upcoming Milestone',
            'You\'re 4 days away from a 30-day hydration streak! 🔥',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00D9FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00D9FF),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(int percentage) {
    if (percentage < 50) return const Color(0xFFFF6B6B);
    if (percentage < 75) return const Color(0xFFFFA500);
    if (percentage < 100) return const Color(0xFF64E7FF);
    return const Color(0xFF00D9FF);
  }
}
