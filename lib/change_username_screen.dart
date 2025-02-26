import 'package:flutter/material.dart';

class ChangeUsernameScreen extends StatelessWidget {
  const ChangeUsernameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Username'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Update your username below.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'New Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
// TODO Implement this library.