import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate email format
  bool isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  // Validate phone number format
  bool isValidPhone(String phone) {
    return phone.length >= 10 && RegExp(r'^\+?[0-9]+$').hasMatch(phone);
  }

  // Validate password strength
  bool isValidPassword(String password) {
    return RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  // Sign-up function for API integration
  Future<void> signUp() async {
    final url = Uri.parse(
        'http://10.11.3.6:3000/api/users/signup'); // Update to your local IP

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 201) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
          json.decode(response.body)['message'] ?? 'Sign-up failed');
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your account has been created successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Create an Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nameController,
                labelText: 'Full Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _emailController,
                labelText: 'Email Address',
                icon: Icons.email,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                icon: Icons.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _addressController,
                labelText: 'Address',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (_validateInputs()) {
                    signUp();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Validate user inputs
  bool _validateInputs() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return false;
    }
    if (!isValidEmail(_emailController.text)) {
      _showErrorDialog('Invalid email format');
      return false;
    }
    if (!isValidPhone(_phoneController.text)) {
      _showErrorDialog('Invalid phone number');
      return false;
    }
    if (!isValidPassword(_passwordController.text)) {
      _showErrorDialog(
          'Password must contain at least 8 characters, an uppercase letter, a number, and a special character');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return false;
    }
    return true;
  }

  // Helper function to build input fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
