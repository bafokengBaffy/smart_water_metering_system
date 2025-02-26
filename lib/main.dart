import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For status bar style

// Import screens
import 'home_screen_admin.dart';
import 'sign_in_screen.dart' as sign_in;
import 'sign_up_screen.dart' as sign_up;
import 'home_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'dark_mode_screen.dart';
import 'analysis_screen.dart';
import 'welcome_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set the status bar to transparent with light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Smart Water Metering System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreenAdmin(), // Initial screen
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // List of screens
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    AboutScreen(),
    SettingsScreen(),
    sign_in.SignInPage(),
    sign_up.SignUpPage(),
    DarkModeScreen(),
    AnalysisScreen(),
    ProfileScreen(), // Profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Water Metering \nSystem'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const sign_in.SignInPage(),
                ),
              );
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'), // Profile button
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
