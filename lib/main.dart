// Core Flutter/Dart
import 'package:demo/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// State Management
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'firebase_options.dart';

// Supabase
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

// Screens
import 'sign_up_screen.dart';
import 'sign_in_screen.dart';
import 'home_screen_admin.dart';
import 'about_screen.dart';
import 'dark_mode_screen.dart';
import 'analysis_screen.dart';
import 'profile_screen.dart';
import 'payment_screen.dart';
import 'home_screen.dart' as home;
import 'settings_screen.dart' as settings;
import 'dashboard_page.dart';
import 'meter_management_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await supabase.Supabase.initialize(
    url: 'https://olvkerrxnerweinmozfl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sdmtlcnJ4bmVyd2Vpbm1vemZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMwNTgzNjUsImV4cCI6MjA1ODYzNDM2NX0.7Q04-1mwkclI0AO_JIeLdENCiUJ3xzxp1wGbxOENX20',
  );

  // Load theme preference from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create:
          (_) => ThemeProvider(isDarkMode ? ThemeMode.dark : ThemeMode.light),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  ThemeProvider(this._themeMode);

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Set the status bar style based on the current theme
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Smart Water Metering System',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const WelcomeScreen(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/meter': (context) => const MeterManagementPage(),
            '/home': (context) => const home.HomeScreen(),
            '/dashboard': (context) => const DashboardPage(),
            '/sign': (context) => const SignUpPage(),
            '/signin': (context) => const SignInPage(),
            '/admin_home': (context) => const HomeScreenAdmin(),
            '/about': (context) => const AboutScreen(),
            '/settings': (context) => const settings.SettingsScreen(),
            '/darkmode': (context) => const DarkModeScreen(),
            '/analysis': (context) => const AnalysisScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/payment': (context) => const PaymentScreen(),
          },
        );
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const home.HomeScreen();
        }
        return const home.HomeScreen();
      },
    );
  }
}
