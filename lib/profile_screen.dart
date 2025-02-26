import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfileScreen(),
  ));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Pick an image from gallery
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Save picked image to _image variable
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 171, 148, 196),
                Color.fromARGB(255, 237, 239, 242)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Picture Section with ImagePicker
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _image == null
                          ? const AssetImage('images/water.jpg')
                              as ImageProvider
                          : FileImage(_image!),
                      backgroundColor: Colors.white,
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // User Info Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: const [
                        Text(
                          'User Name',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'user@example.com',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Functionality to update profile details
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: const Color(0xFF6A11CB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // Button Row for Secondary Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionCard(
                      title: 'View Analytics',
                      icon: Icons.analytics_outlined,
                      onPressed: () {
                        // Functionality to view analytics
                      },
                    ),
                    _buildActionCard(
                      title: 'Manage Notifications',
                      icon: Icons.notifications_outlined,
                      onPressed: () {
                        // Functionality to manage notifications
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionCard(
                      title: 'Privacy Settings',
                      icon: Icons.privacy_tip_outlined,
                      onPressed: () {
                        // Functionality to manage privacy settings
                      },
                    ),
                    _buildActionCard(
                      title: 'Terms & Conditions',
                      icon: Icons.description_outlined,
                      onPressed: () {
                        // Functionality to view terms and conditions
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Log Out Button
                TextButton.icon(
                  onPressed: () {
                    // Functionality to log out
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 30, color: const Color(0xFF6A11CB)),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
