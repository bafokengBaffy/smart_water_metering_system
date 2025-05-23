// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show json;
// ignore: unused_shown_name
import 'dart:async' show Future, Stream, StreamSubscription, Timer;
import 'dart:math';

import 'firebase_options.dart';
import 'payment_screen.dart';
// ignore: duplicate_ignore
// ignore: unused_import
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'analysis_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
  }

  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const String _weatherApiKey = 'fa49971f87eebb578199a5a203e1c1b6';
  static const double _lat = -29.3167;
  static const double _lon = 27.4833;

  late DatabaseReference _databaseRef;
  // ignore: unused_field
  late StreamSubscription<DatabaseEvent> _databaseSubscription;
  late AnimationController _waveController;
  late AnimationController _graphController;
  late AnimationController _meterController;
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  User? currentUser;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  double meterReading = 0.0;
  double _previousMeterValue = 0.0;

  List<FlSpot> _graphData = [];
  final List<double> _graphPoints = [];

  @override
  void initState() {
    super.initState();
    _setupStreams();
    _initializeFirebase(); // Add this
    _setupDatabaseListener();
    _initializeControllers();
    _fetchWeather(); // Add this
  }

  void _setupStreams() {
    // Example: setting up a Firebase stream
    FirebaseFirestore.instance
        .collection('sensor_readings')
        .doc('-OMw1-uiSiIqwg_tkqZc')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            double latestReading = snapshot['reading'].toDouble();
            setState(() {
              _previousMeterValue = latestReading;
            });
          }
        });
  }

  void _setupDatabaseListener() async {
    try {
      if (kDebugMode) {
        print('Attempting to initialize database listener...');
      }

      // First ensure Firebase Auth is initialized
      await _initializeFirebase();
      if (kDebugMode) {
        print('User authenticated: ${FirebaseAuth.instance.currentUser?.uid}');
      }

      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://smart-water-metering-sys-default-rtdb.firebaseio.com',
      );
      if (kDebugMode) {
        print('Database instance created');
      }

      _databaseRef = database.ref('sensor_readings');
      if (kDebugMode) {
        print('Database reference created for path: sensor_readings');
      }

      _databaseSubscription = _databaseRef
          .orderByKey()
          .limitToLast(1)
          .onChildAdded
          .listen(
            (DatabaseEvent event) {
              if (kDebugMode) {
                print(
                  'Received database event with key: ${event.snapshot.key}',
                );
              }
              if (event.snapshot.value != null) {
                final data = event.snapshot.value as Map<dynamic, dynamic>;
                if (kDebugMode) {
                  print('Data received: $data');
                }
                _updateWaterUsage(data);
              }
            },
            onError: (error) {
              if (kDebugMode) {
                print('Database listener error: $error');
              }
            },
          );

      if (kDebugMode) {
        print('Database listener established successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up database listener: $e');
      }
      _showError('Failed to connect to database');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      // Check current auth state
      final currentUser = FirebaseAuth.instance.currentUser;
      if (kDebugMode) {
        print('Current auth state: ${currentUser?.uid ?? "Not logged in"}');
      }

      // Sign in anonymously if needed
      if (currentUser == null) {
        if (kDebugMode) {
          print('Attempting anonymous sign-in...');
        }
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        if (kDebugMode) {
          print('Signed in anonymously: ${userCredential.user?.uid}');
        }
      }

      this.currentUser = FirebaseAuth.instance.currentUser;
      if (kDebugMode) {
        print('Final auth state: ${this.currentUser?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
      _showError('Failed to initialize authentication');
      rethrow;
    }
  }

  void _updateWaterUsage(Map<dynamic, dynamic> data) {
    try {
      // Handle all possible field name variations
      String volumeStr =
          data['total_wolume']?.toString() ??
          data['total_volume']?.toString() ??
          data['volume']?.toString() ??
          '0';

      // Clean the string (remove $ and other non-numeric chars)
      volumeStr = volumeStr.replaceAll(RegExp(r'[^0-9.]'), '');

      double totalVolume = double.tryParse(volumeStr) ?? 0.0;
      double flowRate =
          (data['Flow_rate'] ?? data['flow_rate'] ?? 0).toDouble();
      int timestamp = (data['timestamp'] ?? 0).toInt();

      if (kDebugMode) {
        print(
          'Parsed values - Volume: $totalVolume, Flow: $flowRate, Time: $timestamp',
        );
      }

      if (mounted) {
        setState(() {
          _previousMeterValue = meterReading;
          meterReading = totalVolume;
          _updateGraphData();
        });
        _meterController.reset();
        _meterController.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating water usage: $e');
      }
      _showError('Failed to update water usage display');
    }
  }

  void _updateGraphData() {
    // Maintain last 24 readings
    if (_graphPoints.length >= 24) {
      _graphPoints.removeAt(0);
    }
    _graphPoints.add(meterReading);

    _graphData =
        _graphPoints
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
  }

  void _initializeControllers() {
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _graphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _meterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize graph with 24 data points
    for (int i = 0; i < 24; i++) {
      _graphPoints.add(0.0);
      _graphData.add(FlSpot(i.toDouble(), _graphPoints[i]));
    }
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;

    setState(() => isLoadingWeather = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$_lat&lon=$_lon&appid=$_weatherApiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            weatherData = data;
            isLoadingWeather = false;
          });
        }
      } else {
        _showError('Weather error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    setState(() => isLoadingWeather = false);
  }

  Widget _buildMeterReading() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.lightBlue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              "WATER USAGE",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _meterController,
              builder: (context, child) {
                final value =
                    Tween<double>(begin: _previousMeterValue, end: meterReading)
                        .animate(
                          CurvedAnimation(
                            parent: _meterController,
                            curve: Curves.easeOut,
                          ),
                        )
                        .value;

                return Text(
                  '${value.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUsageIndicator(
                  "Current",
                  "${meterReading.toStringAsFixed(1)} L",
                ),
                _buildUsageIndicator("Avg/Day", "325.4 L"),
                _buildUsageIndicator("Monthly", "9,762 L"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageIndicator(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Community Forum",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Post a comment or suggestion...",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _submitComment,
                  ),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Please enter text' : null,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return _buildCommentTile(doc);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(data['text'], style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            _formatTimestamp(data['timestamp']),
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'text': _commentController.text,
        'userId': currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
      _commentFocusNode.unfocus();
    } catch (e) {
      if (kDebugMode) print('Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post comment')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Management Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchWeather,
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalysisScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _buildMeterReading(),
            const SizedBox(height: 16),
            _buildLiveGraph(),
            const SizedBox(height: 16),
            _buildWeatherCard(),
            const SizedBox(height: 16),
            _buildCommentsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildLiveGraph() {
    return AnimatedBuilder(
      animation: _graphController,
      builder:
          (context, child) => Opacity(
            opacity: _graphController.value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - _graphController.value)),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 23,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _graphData,
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              // ignore: deprecated_member_use
                              Colors.blueAccent.withOpacity(0.3),
                              // ignore: deprecated_member_use
                              Colors.blueAccent.withOpacity(0.1),
                            ],
                          ),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildWeatherCard() {
    final weather = weatherData?['weather']?[0];
    final main = weatherData?['main'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade200, Colors.yellow.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _waveController,
              builder:
                  (context, child) => Transform.rotate(
                    angle: _waveController.value * 0.1,
                    child: child,
                  ),
              child: Icon(
                _getWeatherIcon(weather?['main']),
                size: 40,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Weather",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                isLoadingWeather
                    ? const CircularProgressIndicator(
                      color: Colors.deepOrange,
                      strokeWidth: 2,
                    )
                    : (weather != null && main != null)
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather['description'].toString().capitalize(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${main['temp']?.round() ?? '--'}°C',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Feels like ${main['feels_like']?.round() ?? '--'}°C',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    )
                    : const Text(
                      'Weather data unavailable',
                      style: TextStyle(color: Colors.red),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomAppBar(
            height: 70,
            padding: EdgeInsets.zero,
            color: Colors.white,
            elevation: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavButton(
                  icon: Icons.home,
                  label: "Home",
                  isActive: true,
                  onTap: () {},
                ),
                _NavButton(
                  icon: Icons.analytics,
                  label: "Stats",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalysisScreen(),
                        ),
                      ),
                ),
                _NavButton(
                  icon: Icons.payment,
                  label: "Pay",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentScreen(),
                        ),
                      ),
                ),
                _NavButton(
                  icon: Icons.settings,
                  label: "Settings",
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _graphController.dispose();
    _meterController.dispose();
    super.dispose();
  }
}

// ignore: unused_element
void _initializeFirebase() async {
  var currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
    currentUser = FirebaseAuth.instance.currentUser;
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  // ignore: deprecated_member_use
                  ? Colors.blueAccent.withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blueAccent : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blueAccent : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
