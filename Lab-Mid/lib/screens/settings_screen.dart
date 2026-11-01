import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = themeProvider.settings;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section: Appearance & Themes
          _buildSectionHeader('Appearance & Theme', Icons.palette_outlined, theme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('App Theme Mode'),
                  subtitle: Text('Current: ${settings.themeMode.toUpperCase()}'),
                  trailing: DropdownButton<String>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (val) {
                      if (val != null) themeProvider.setThemeMode(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Default Reading Background'),
                  subtitle: Text('Selected: ${settings.readingBgColor.toUpperCase()}'),
                  trailing: DropdownButton<String>(
                    value: settings.readingBgColor,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'white', child: Text('Pure White')),
                      DropdownMenuItem(value: 'sepia', child: Text('Warm Sepia')),
                      DropdownMenuItem(value: 'dark', child: Text('Night Dark')),
                      DropdownMenuItem(value: 'cream', child: Text('Soft Cream')),
                    ],
                    onChanged: (val) {
                      if (val != null) themeProvider.setReadingBgColor(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Reading Goals & Notifications
          _buildSectionHeader('Reading Goals & Notifications', Icons.notifications_active_outlined, theme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Reading Reminders'),
                  subtitle: const Text('Receive notifications for scheduled sessions and goals'),
                  value: settings.notificationsEnabled,
                  onChanged: (val) => themeProvider.setNotificationsEnabled(val),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Daily Reading Target'),
                  subtitle: Text('${settings.readingGoalMinutes} minutes per day'),
                  trailing: DropdownButton<int>(
                    value: settings.readingGoalMinutes,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 mins')),
                      DropdownMenuItem(value: 30, child: Text('30 mins')),
                      DropdownMenuItem(value: 45, child: Text('45 mins')),
                      DropdownMenuItem(value: 60, child: Text('60 mins')),
                    ],
                    onChanged: (val) {
                      if (val != null) themeProvider.setReadingGoalMinutes(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Notification Sound Style'),
                  subtitle: Text(settings.notificationSound.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: settings.notificationSound,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'default', child: Text('Default Alert')),
                      DropdownMenuItem(value: 'subtle', child: Text('Subtle Chime')),
                      DropdownMenuItem(value: 'gentle', child: Text('Gentle Bell')),
                    ],
                    onChanged: (val) {
                      if (val != null) themeProvider.setNotificationSound(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_none),
                      label: const Text('Test Local Notification Now'),
                      onPressed: () async {
                        await NotificationService().notifyReadingGoalReminder(settings.readingGoalMinutes);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test notification dispatched!')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Academic Information & About
          _buildSectionHeader('Project & Course Information', Icons.school_outlined, theme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('Course'),
                  subtitle: Text('Mobile Application Development'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Instructor'),
                  subtitle: Text('Muhammad Abrar Saddique'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.assignment),
                  title: Text('Assignment Task'),
                  subtitle: Text('Lab – Mid Task: Comprehensive PDF Reader & Utility Application'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Stack'),
                  subtitle: Text('Flutter, Dart, SQLite (sqflite), Syncfusion PDF Viewer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
