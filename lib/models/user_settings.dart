/// Data model representing user preferences and customization settings.
class UserSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String readingBgColor; // 'white', 'sepia', 'dark', 'cream'
  final String notificationSound; // 'default', 'subtle', 'chime'
  final int readingGoalMinutes; // daily reading goal in minutes
  final bool notificationsEnabled;
  final String reminderTime; // e.g. "20:00"

  UserSettings({
    this.themeMode = 'system',
    this.readingBgColor = 'white',
    this.notificationSound = 'default',
    this.readingGoalMinutes = 30,
    this.notificationsEnabled = true,
    this.reminderTime = '20:00',
  });

  Map<String, dynamic> toMap() {
    return {
      'theme_mode': themeMode,
      'reading_bg_color': readingBgColor,
      'notification_sound': notificationSound,
      'reading_goal_minutes': readingGoalMinutes,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'reminder_time': reminderTime,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      themeMode: map['theme_mode'] as String? ?? 'system',
      readingBgColor: map['reading_bg_color'] as String? ?? 'white',
      notificationSound: map['notification_sound'] as String? ?? 'default',
      readingGoalMinutes: map['reading_goal_minutes'] as int? ?? 30,
      notificationsEnabled: (map['notifications_enabled'] as int? ?? 1) == 1,
      reminderTime: map['reminder_time'] as String? ?? '20:00',
    );
  }

  UserSettings copyWith({
    String? themeMode,
    String? readingBgColor,
    String? notificationSound,
    int? readingGoalMinutes,
    bool? notificationsEnabled,
    String? reminderTime,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      readingBgColor: readingBgColor ?? this.readingBgColor,
      notificationSound: notificationSound ?? this.notificationSound,
      readingGoalMinutes: readingGoalMinutes ?? this.readingGoalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
