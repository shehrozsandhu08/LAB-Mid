import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';

class ThemeProvider extends ChangeNotifier {
  UserSettings _settings = UserSettings();
  bool _isLoading = true;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Color get readingBackgroundColor {
    switch (_settings.readingBgColor) {
      case 'sepia':
        return const Color(0xFFFBF0D9);
      case 'dark':
        return const Color(0xFF1E1E1E);
      case 'cream':
        return const Color(0xFFFAF8F0);
      case 'white':
      default:
        return Colors.white;
    }
  }

  Color get readingTextColor {
    if (_settings.readingBgColor == 'dark') {
      return const Color(0xFFE0E0E0);
    }
    return const Color(0xFF212121);
  }

  ThemeProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await DatabaseHelper.instance.getSettings();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);
  }

  Future<void> setReadingBgColor(String colorKey) async {
    _settings = _settings.copyWith(readingBgColor: colorKey);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);
  }

  Future<void> setNotificationSound(String sound) async {
    _settings = _settings.copyWith(notificationSound: sound);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);
  }

  Future<void> setReadingGoalMinutes(int minutes) async {
    _settings = _settings.copyWith(readingGoalMinutes: minutes);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);

    if (!enabled) {
      await NotificationService().cancelAll();
    }
  }

  Future<void> setReminderTime(String time) async {
    _settings = _settings.copyWith(reminderTime: time);
    notifyListeners();
    await DatabaseHelper.instance.updateSettings(_settings);
  }
}
