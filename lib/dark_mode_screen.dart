// DarkModeScreen
import 'package:flutter/material.dart';

class DarkModeScreen extends StatelessWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dark Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Toggle Dark Mode below.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Dark Mode'),
              value: false, // Replace with actual dark mode state
              onChanged: (value) {
                // Handle dark mode toggle
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Save logic
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
