import 'package:demo/change_language_screen.dart';
import 'package:demo/dark_mode_screen.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';
import 'package:demo/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables to store settings
  bool isPushNotificationsEnabled = true;
  bool isEmailNotificationsEnabled = false;
  bool isUsageAlertsEnabled = false;
  bool isLeakAlertsEnabled = false;

  @override
  void initState() {
    super.initState();
    // Load settings from SharedPreferences when the screen is initialized
    loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isPushNotificationsEnabled = prefs.getBool('pushNotifications') ?? true;
      isEmailNotificationsEnabled =
          prefs.getBool('emailNotifications') ?? false;
      isUsageAlertsEnabled = prefs.getBool('usageAlerts') ?? false;
      isLeakAlertsEnabled = prefs.getBool('leakAlerts') ?? false;
    });
  }

  // Save settings to SharedPreferences and show a toast message
  Future<void> saveSetting(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    Fluttertoast.showToast(msg: 'Setting saved');
  }

  // Navigate to Change Language Screen
  void changeLanguage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangeLanguageScreen()),
    );
  }

  // Navigate to Dark Mode Screen
  void toggleDarkMode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DarkModeScreen()),
    );
  }

  // Show a logout confirmation dialog
  void logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Add actual logout logic here
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title for the settings screen
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Notification Settings section
            ExpansionTile(
              title: const Text(
                'Notification Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              children: [
                SwitchListTile(
                  title: const Text('Enable Push Notifications'),
                  value: isPushNotificationsEnabled,
                  onChanged: (value) async {
                    setState(() => isPushNotificationsEnabled = value);
                    await saveSetting('pushNotifications', value);
                    await NotificationService.handlePushNotification(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: isEmailNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      isEmailNotificationsEnabled = value;
                    });
                    saveSetting('emailNotifications', value);
                  },
                ),
              ],
            ),

            const Divider(),

            // App Settings section
            ExpansionTile(
              title: const Text(
                'App Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: changeLanguage,
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: toggleDarkMode,
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Theme Customization'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Implement theme customization functionality
                  },
                ),
              ],
            ),
            const Divider(),

            // Water Usage Tracking section
            ExpansionTile(
              title: const Text(
                'Water Usage Tracking',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              children: [
                ListTile(
                  leading: const Icon(Icons.water_damage),
                  title: const Text('View Usage History'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Implement view usage history functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: const Text('Usage Alerts'),
                  trailing: Switch(
                    value: isUsageAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        isUsageAlertsEnabled = value;
                      });
                      saveSetting('usageAlerts', value);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),

            // Billing Information section
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Billing Information'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Implement billing information functionality
              },
            ),
            const Divider(),

            // Leak Detection section
            ExpansionTile(
              title: const Text(
                'Leak Detection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              children: [
                ListTile(
                  leading: const Icon(Icons.warning),
                  title: const Text('Enable Leak Alerts'),
                  trailing: Switch(
                    value: isLeakAlertsEnabled,
                    onChanged: (value) {
                      setState(() {
                        isLeakAlertsEnabled = value;
                      });
                      saveSetting('leakAlerts', value);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),

            // Automatic Meter Reading section
            ListTile(
              leading: const Icon(Icons.av_timer),
              title: const Text('Automatic Meter Reading'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Implement automatic meter reading functionality
              },
            ),
            const Divider(),

            // Usage Goals section
            ExpansionTile(
              title: const Text(
                'Usage Goals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              children: [
                ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: const Text('Set Usage Goals'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Implement set usage goals functionality
                  },
                ),
              ],
            ),
            const Divider(),

            // About section
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About'),
                    content: const Text(
                        'App Version 1.0.0\nDeveloped by [Your Team]'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Feedback & Support section
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Feedback & Support'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Implement feedback and support functionality
              },
            ),
            const Divider(),

            // Logout button
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
