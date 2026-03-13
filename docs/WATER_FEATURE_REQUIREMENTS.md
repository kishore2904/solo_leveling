# Smart Water Drinking Notification Feature - Requirements Specification

## 1. Core Functionality

### 1.1 Customizable Daily Water Goals
- **Manual Goal Setting**: Users can set daily water intake goals in:
  - Milliliters (e.g., 2000 ml, 3000 ml)
  - Liters (e.g., 2L, 3L)
  - Glasses (e.g., 8 glasses, 10 glasses)
- **Default Goal**: 2000 ml (8 glasses of 250 ml each)
- **Goal Storage**: Persistent storage in SharedPreferences/DataStore with daily goal history

### 1.2 Smart Hydration Engine
**Formula**: Daily Water Recommendation = (Weight × 35 ml) + Activity Adjustment + Temperature Adjustment

#### Base Calculation:
- **Weight-based**: User weight in kg × 35 ml
  - Example: 70 kg × 35 ml = 2450 ml base requirement

#### Activity Level Adjustment:
- **Sedentary** : No additional water (+0%)
- **Light Activity**: +200 ml daily (+10%)
- **Moderate Activity**: +400 ml daily (+20%)
- **High Activity**: +600 ml daily (+30%)
- **Very High Activity**: +800 ml daily (+40%)

#### Temperature-based Adjustment:
- **Cold (<15°C)**: -200 ml daily (-10%)
- **Cool (15-20°C)**: No adjustment (0%)
- **Warm (20-25°C)**: +200 ml daily (+10%)
- **Hot (>25°C)**: +400 ml daily (+20%)
- **Very Hot (>35°C)**: +600 ml daily (+30%)

#### Result:
- System recommends optimal daily intake
- User can accept recommendation or manually override

### 1.3 Quick Water Logging
- **Pre-defined Quick Buttons**:
  - 200 ml (1 small glass)
  - 250 ml (1 standard glass)
  - 500 ml (1 bottle)
  - 750 ml (3 glasses)
  - 1000 ml (1 large bottle)
- **Custom Amount**: Manual input field for custom amounts
- **Timestamp**: Auto-record with precise timestamp (HH:MM)
- **One-tap Logging**: Minimal friction, single button press to record

### 1.4 Reminder Frequency & Time Windows
- **Configurable Reminder Frequency**:
  - Every 1 hour
  - Every 1.5 hours
  - Every 2 hours
  - Every 2.5 hours
  - Every 3 hours
  - Custom interval (1-6 hours)

- **Awake Hours Configuration**:
  - Default: 7:00 AM - 11:00 PM (16 hours)
  - User-configurable wake time (5:00 AM - 10:00 AM)
  - User-configurable sleep time (9:00 PM - 2:00 AM)

---

## 2. Intelligent Reminder System

### 2.1 Evenly Distributed Reminders
**Example Calculation**:
- Goal: 3000 ml (6 × 500 ml servings)
- Awake: 7:00 AM - 11:00 PM (16 hours)
- Calculation: 16 hours ÷ 6 reminders = 2.67 hours ≈ 160 minutes between reminders
- Reminder times: 7:00 AM, 9:40 AM, 12:20 PM, 3:00 PM, 5:40 PM, 8:20 PM

**Algorithm**:
1. Calculate total awake minutes
2. Divide by number of required servings
3. Generate evenly-spaced timestamps
4. Add randomized jitter (±5 minutes) to avoid predictability

### 2.2 Adaptive Reminder System

#### Behavior-Based Adaptation:
- **Behind Goal** (consumed < 50% of goal at 12:00 PM):
  - Increase frequency by 20%
  - Decrease interval by 10 minutes
  - Add extra morning reminder

- **On Track** (consumed 50-75% of goal):
  - Maintain normal frequency

- **Ahead of Goal** (consumed > 75% of goal):
  - Decrease frequency by 15%
  - Increase interval by 10 minutes

#### Notification Fatigue Detection:
- Track dismiss/ignore rate of notifications
- If > 50% of reminders ignored in past 3 days:
  - Reduce frequency by 25%
  - Send only high-priority reminders
- If < 20% ignored:
  - Maintain current frequency

#### Prevention of Back-to-Back Notifications:
- Minimum gap between notifications: 45 minutes
- If user logs water close to scheduled reminder:
  - Skip the next scheduled reminder
  - Reschedule subsequent reminders

### 2.3 Quiet Hours & Smart Pause Detection
- **Do Not Disturb Integration**:
  - Detect system DND status on Android/iOS
  - Skip notifications when device is in DND mode
  - Resume notifications when DND ends

- **Sleep Hours**:
  - No notifications between sleep time and wake time
  - Queue missed notifications as morning summary

- **Manual Pause**:
  - Pause reminders for 1 hour, 2 hours, or until tomorrow
  - User-initiated, temporary pause function
  - Automatic resume after pause duration ends

- **Location-based Quiet Time**:
  - Optional: Suppress notifications in defined locations (e.g., office meeting rooms)

### 2.4 Actionable Notifications
- **Notification Buttons**:
  - "+200 ml" - Quick log
  - "+500 ml" - Quick log
  - "Skip" - Dismiss this reminder
  - "Custom" - Open app to enter custom amount
  
- **Direct Logging from Notification**:
  - No need to open app
  - Water logged immediately with notification timestamp
  - Confirmation message: "200 ml logged"

- **Deep linking**:
  - Tap notification body opens hydration dashboard
  - Tap action button logs water directly

### 2.5 Notification History & Analytics
- **Tracking Data**:
  - Notification sent timestamp
  - User action (logged, skipped, ignored, dismissed)
  - Time lag between notification and actual log (if any)
  - Notification type (scheduled, reminder, achievement, milestone)

- **Use Cases**:
  - Identify optimal reminder times
  - Detect patterns of user engagement
  - Improve timing frequency

---

## 3. Gamification Features

### 3.1 Hydration Streaks
- **Daily Streak Counter**:
  - Increment when user meets daily goal
  - Reset if goal not met by end of day (11:59 PM)
  - Display current streak on home screen

- **Milestone Notifications**:
  - 7-day streak: "🔥 7-Day Hero!"
  - 14-day streak: "💧 Two Weeks of Hydration!"
  - 30-day streak: "🏆 Month of Wellness!"
  - 100-day streak: "💪 Hydration Legend!"

- **Streak Recovery**:
  - Show motivational message when streak breaks
  - Encourage "get back on track" action

### 3.2 Hydration Achievements
**First Drop**
- Unlock: First water log
- Icon: 💧
- Reward: 10 XP

**Morning Hydrator**
- Unlock: Log water before 9:00 AM for 3 consecutive days
- Icon: 🌅
- Reward: 25 XP

**Hydration Starter**
- Unlock: Complete daily goal for the first time
- Icon: ✨
- Reward: 50 XP

**Weekly Water Warrior** (repeatable)
- Unlock: Meet daily goal for 7 consecutive days
- Icon: ⚔️
- Reward: 100 XP
- Progress: (days_completed / 7)

**Hydration Hero** (repeatable)
- Unlock: Maintain 30-day hydration streak
- Icon: 🦸
- Reward: 250 XP
- Progress: (days_completed / 30)

**Water Master**
- Unlock: Complete 100 days of hydration goals
- Icon: 👑
- Reward: 500 XP
- Unique badge

**Consistency King**
- Unlock: Never miss a day for 2 months
- Icon: 👑
- Reward: 300 XP
- Rare achievement

**Night Owl Hydrator**
- Unlock: Log water after 8:00 PM for 10 days
- Icon: 🌙
- Reward: 50 XP

**Never Ignore**
- Unlock: Respond to 95%+ of notifications in a week
- Icon: 📲
- Reward: 75 XP

**Smart Pacer**
- Unlock: Maintain perfect reminder response rate (no ignores) for 7 days
- Icon: ⏱️
- Reward: 100 XP

### 3.3 Progress Visualization
- **Daily Progress Bar**:
  - Shows percentage of daily goal completed (0-100%)
  - Color changes: Red (0-25%) → Orange (25-50%) → Light Blue (50-75%) → Blue (75-100%)
  - Displays current ml / goal ml (e.g., "1500 / 3000 ml")

- **Animation**:
  - Smooth fill animation when water is logged
  - Celebration animation when goal is reached
  - Confetti/toast notification for milestones

### 3.4 Hydration Score
**Daily Hydration Score** (0-100):
- Base: (ml_consumed / daily_goal) × 100
- Bonus: +10 points for consistent timing (within ±30 min of planned reminders)
- Bonus: +5 points for high response rate to notifications
- Deduction: -5 points for each ignore after 3 ignores
- Result: Capped at 100 points

**Weekly Score**: Average of 7 daily scores
**Monthly Score**: Average of 30 daily scores

---

## 4. Analytics & Insights

### 4.1 Daily Analytics
- **Today's Summary**:
  - Total consumed: X ml / Y ml goal
  - Percentage completed: X%
  - Time of last drink: HH:MM
  - Achievement unlocked today (if any)

- **Hourly Distribution**:
  - Morning (6 AM - 12 PM): X ml
  - Afternoon (12 PM - 6 PM): X ml
  - Evening (6 PM - 11 PM): X ml

### 4.2 Weekly Statistics
- **Week Overview**:
  - Days goal met: X / 7
  - Average daily intake: X ml
  - Best day: X ml (Date)
  - Lowest day: X ml (Date)
  - Consistency rate: X%

- **Weekly Chart**:
  - Bar chart showing daily intake for past 7 days
  - Goal line overlay
  - Color coding for met/unmet days

### 4.3 Monthly Statistics
- **Month Overview**:
  - Days goal met: X / 30
  - Average daily intake: X ml
  - Total intake: X liters
  - Consistency rate: X%
  - Best streak this month: X days

- **Monthly Trends**:
  - Line chart of 30-day rolling average
  - Seasonal patterns (if weather data available)

### 4.4 Smart Suggestions
- **Hydration Insights**:
  - "You drink most water in the afternoon. Try adding a morning reminder for better balance."
  - "You're ignoring 30% of notifications. We've adjusted frequency to reduce fatigue."
  - "Congrats! You're 200ml above your goal. Your body is well-hydrated!"
  - "You've been missing evening hydration. Consider adding a 7 PM reminder."

- **Personalized Tips**:
  - Based on weather: "It's warmer today. Increase water intake by 20%."
  - Based on activity: "Try to drink 100ml every 30 minutes during exercise."
  - Based on patterns: "You usually drink more on weekends. Stay consistent on weekdays."

---

## 5. Technical Implementation

### 5.1 Models & Data Structures

#### HydrationGoal
```dart
class HydrationGoal {
  String id;
  double dailyGoalMl;            // 2000 ml
  double userWeight;              // kg
  String activityLevel;           // 'Sedentary', 'Light', 'Moderate', 'High', 'VeryHigh'
  TimeOfDay wakeUpTime;          // 7:00 AM
  TimeOfDay sleepTime;           // 11:00 PM
  int reminderIntervalMinutes;   // 120
  bool autoCalculateGoal;        // true = use smart engine
  DateTime createdAt;
  DateTime updatedAt;
  
  double getRecommendedIntake(double tempCelsius) { ... }
}
```

#### HydrationLog
```dart
class HydrationLog {
  String id;
  double amountMl;               // 250 ml
  DateTime timestamp;            // Auto-recorded
  String source;                 // 'manual', 'notification', 'quick_button'
  String? notes;                 // Optional user notes
  DateTime dateLogged;           // For daily grouping
}
```

#### HydrationStreak
```dart
class HydrationStreak {
  String id;
  int currentStreak;             // Days
  int longestStreak;             // Best ever
  DateTime lastCompletionDate;   // Last day goal was met
  List<DateTime> streakDates;    // Backup record of dates
}
```

#### ReminderSchedule
```dart
class ReminderSchedule {
  String id;
  List<TimeOfDay> scheduledTimes;
  DateTime lastSentTime;
  int ignoreCount;               // Consecutive ignores
  bool isPaused;
  DateTime? pauseUntil;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### NotificationEvent
```dart
class NotificationEvent {
  String id;
  DateTime sentTime;
  String action;                 // 'sent', 'completed', 'skipped', 'ignored'
  DateTime? actionTime;
  int? amountLogged;             // If completed
}
```

#### HydrationScore
```dart
class HydrationScore {
  String id;
  int score;                     // 0-100
  double intakePercentage;       // (consumed / goal) * 100
  int timelinessBonus;           // +10 for consistent timing
  int responseBonus;             // +5 for notification responsiveness
  int ignoreDeduction;           // -5 per ignore (capped)
  DateTime dateRecorded;
}
```

### 5.2 Storage Strategy
- **SharedPreferences**: Simple settings (goals, wake/sleep times, intervals)
- **Local Database (Room/Hive)**: 
  - Daily hydration logs with timestamps
  - Notification history
  - Achievement progress
  - Historical data for analytics
  - Streak tracking

### 5.3 Background Scheduling

#### Android
- **WorkManager**: For persistent scheduled reminders
  - Start background task for hydration reminders
  - Use PeriodicWorkRequest for recurring tasks
  - Handle DND mode detection via BroadcastReceiver

- **AlarmManager**: For precise time-based notifications
  - Set alarms for calculated reminder times
  - Handle device restart using BOOT_COMPLETED broadcast

#### iOS
- **UNUserNotificationCenter**: 
  - Request notification permissions
  - Schedule UNCalendarNotificationTrigger for timed notifications
  - Handle notification responses when app in foreground

#### Flutter Packages
- `flutter_local_notifications`: Cross-platform notification delivery
- `workmanager`: For Android background tasks
- `app_settings`: To link to app notification settings

### 5.4 Daily Reset Logic
```dart
void resetDailyWaterCount() {
  // Runs at 12:00 AM (midnight)
  // If tomorrow's log doesn't exist, create it
  // Check if today's goal was met -> update streak
  // Send "Morning Hydration Reminder" notification
  // Reset hydration score for new day
}
```

### 5.5 Notification Payload Structure
```json
{
  "type": "hydration_reminder",
  "goalMl": 3000,
  "consumedMl": 1500,
  "reminderId": "rem_123",
  "timestamp": "2026-03-13T14:30:00Z",
  "action": "log_water"
}
```

---

## 6. Additional Features

### 6.1 Morning Hydration Reminder
- **Daily Trigger**: 7:00 AM (or user's wake time)
- **Message**: "Good morning! Start your day hydrated 💧"
- **Action**: "+500 ml" button to quick-log a glass
- **Importance**: High priority, not affected by pause function

### 6.2 Milestone Celebrations
- **50% Goal**: "Halfway there! 🎯"
- **75% Goal**: "Almost done! Keep going! 💪"
- **100% Goal**: "Goal achieved! 🎉 Celebration notification with confetti animation
- **110% Goal**: "You've exceeded your goal! Extra hydration, extra health! 🏆"

### 6.3 Deep Link Integration
- Water feature deep link: `solo_leveling://hydration`
- Hydration dashboard deep link: `solo_leveling://hydration/dashboard`
- Stats deep link: `solo_leveling://hydration/stats`
- Achievement deep link: `solo_leveling://achievement/hydration_hero`

### 6.4 Integration with Existing XP/Leveling System
- Water goal achievement: +50 XP
- Weekly streak: +100 XP
- Monthly hydration hero: +250 XP
- Achievements unlock → same as current daily quest system

### 6.5 Export & Sharing
- **Export Data**: Monthly hydration report as PDF
- **Share Stats**: "I've completed 30 days of hydration! 💧 #HydrationHero"
- **Weekly Recap**: Email/in-app summary every Sunday

---

## 7. User Experience Flows

### 7.1 Onboarding
1. **Welcome Screen**: Introduce water feature benefits
2. **Goal Setup**: Weight input → Activity level → Temperature → Recommended goal
3. **Schedule Setup**: Wake time → Sleep time → Reminder frequency
4. **Permission**: Request notification permissions
5. **First Log**: Guide user to log first glass
6. **Confirmation**: "Profile complete! Your hydration journey begins 🌊"

### 7.2 Daily Usage
1. User receives calculated reminder at scheduled time
2. Tap notification → 3 quick options (+200ml, +500ml, +1000ml)
3. Or tap "Custom" → Enter amount → Save
4. Progress bar updates in real-time
5. Celebrations when milestones reached
6. Evening summary of daily intake

### 7.3 Weekly Review
- Sunday evening: "Weekly Recap" notification
- Show 7-day chart and consistency percentage
- Unlock weekly achievement if goal met X days

---

## 8. Localization & Timing Considerations
- All timestamps stored in UTC
- Display times in user's local timezone
- Support multiple languages (initially English)
- Weather data source (optional): OpenWeatherMap API

---

## 9. Privacy & Security
- All hydration data stored locally (not transmitted)
- Optional: Local backup in encrypted SharedPreferences
- User can delete all hydration history
- No analytics tracking of personal health data

---

## 10. Success Metrics (Post-Launch)
- **Adoption**: % of users completing onboarding
- **Engagement**: Daily active users logging water
- **Goal Completion**: % of users meeting daily goal
- **Streak Length**: Average streak duration
- **Retention**: % of users returning after 7/30/60 days
- **Feature Usage**: % of quick-log button usage vs. manual entry
