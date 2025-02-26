import 'package:flutter/material.dart';
import 'package:demo/home_screen.dart'; // Ensure proper import
import 'package:demo/home_screen_admin.dart'; // Import the new admin home screen
import 'sign_up_screen.dart'; // Ensure proper import
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please sign in to continue.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                // Email/Username TextField
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password TextField
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Add forgot password functionality here
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Sign In Button
                ElevatedButton(
                  onPressed: () {
                    // Validate fields before navigating
                    if (emailController.text.isNotEmpty &&
                        passwordController.text.isNotEmpty) {
                      _handleSignIn(context, emailController.text, passwordController.text);
                    } else {
                      // Show an error dialog if fields are empty
                      _showErrorDialog(context, 'Please fill in all fields');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                // Sign Up Redirect
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account? '),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Colors.blueAccent),
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

  void _handleSignIn(BuildContext context, String email, String password) async {
    try {
      // Use your machine's IP address instead of localhost
      final adminResponse = await http.post(
        Uri.parse('http://192.168.185.194:3306/api/admins/signin'), // Updated IP
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (adminResponse.statusCode == 200) {
        final responseData = json.decode(adminResponse.body);
        if (responseData['role'] == 'admin') {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => const HomeScreenAdmin(),
              ),
            );
          }
          return;
        }
      }

      // If not an admin, check if email belongs to a user
      final userResponse = await http.post(
        Uri.parse('http://192.168.185.194:3306/api/users/signin'), // Updated IP
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (userResponse.statusCode == 200) {
        final responseData = json.decode(userResponse.body);
        if (responseData['role'] == 'user') {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => const HomeScreen(),
              ),
            );
          }
        } else {
          if (context.mounted) {
            _showErrorDialog(context, 'Invalid credentials. Please try again.');
          }
        }
      } else {
        final errorData = json.decode(userResponse.body);
        if (context.mounted) {
          _showErrorDialog(context, errorData['message'] ?? 'Invalid credentials. Please try again.');
        }
      }
    } catch (error) {
      if (context.mounted) {
        _showErrorDialog(context, 'An error occurred: $error');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}