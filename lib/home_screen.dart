import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analysis_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int meterReading = 0;
  int activeDevices = 0;
  int targetUsage = 100;
  late Timer _timer;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> schedules = [
    {
      "time": "06:00",
      "description": "Morning irrigation",
      "icon": Icons.wb_sunny,
      "color": Colors.orange,
      "isActive": true,
      "duration": 2,
      "assignedDevices": 5,
    },
    {
      "time": "12:00",
      "description": "Midday water usage",
      "icon": Icons.wb_cloudy,
      "color": Colors.yellow,
      "isActive": true,
      "duration": 4,
      "assignedDevices": 8,
    },
    {
      "time": "20:00",
      "description": "Evening irrigation",
      "icon": Icons.nights_stay,
      "color": Colors.blue,
      "isActive": false,
      "duration": 3,
      "assignedDevices": 3,
    },
  ];

  List<Day> weekdays = [
    Day(name: 'Mon', isSelected: true),
    Day(name: 'Tue', isSelected: true),
    Day(name: 'Wed', isSelected: true),
    Day(name: 'Thu', isSelected: true),
    Day(name: 'Fri', isSelected: false),
    Day(name: 'Sat', isSelected: false),
    Day(name: 'Sun', isSelected: false),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateMetrics);
  }

  void _updateMetrics(Timer timer) {
    setState(() {
      meterReading += 1;
      if (meterReading % 10 == 0) {
        activeDevices = (activeDevices + 1) % 15 + 5;
      }
      schedules = schedules.map((schedule) {
        if (schedule['isActive']) {
          schedule['assignedDevices'] = (schedule['assignedDevices'] + 1) % 15 + 5;
        }
        return schedule;
      }).toList();

      if (meterReading % 10 == 0) {
        for (var day in weekdays) {
          day.isSelected = !day.isSelected;
        }
      }
    });
  }

  Future<void> _openCamera(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (photo != null) _handleMedia(photo, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(
                  source: ImageSource.camera,
                );
                if (video != null) _handleMedia(video, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMedia(XFile file, {required bool isVideo}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isVideo ? 'Video Captured' : 'Photo Captured'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('File path: ${file.path}'),
            const SizedBox(height: 16),
            const Text('This would typically be uploaded to your server'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _editSchedule(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        TextEditingController durationController = TextEditingController(
          text: schedules[index]['duration'].toString(),
        );
        TextEditingController devicesController = TextEditingController(
          text: schedules[index]['assignedDevices'].toString(),
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (hours)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: devicesController,
                decoration: const InputDecoration(
                  labelText: 'Assigned Devices',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    schedules[index]['duration'] =
                        int.tryParse(durationController.text) ?? 0;
                    schedules[index]['assignedDevices'] =
                        int.tryParse(devicesController.text) ?? 0;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (meterReading / targetUsage).clamp(0, 1);
    double averageUsage = meterReading / (DateTime.now().second + 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Usage Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _openCamera(context),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalysisScreen()),
              );
            },
            child: const Text(
              'Analysis',
              style: TextStyle(color: Colors.black),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...schedules.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> schedule = entry.value;
                return _buildScheduleCard(schedule, index);
              }),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Weekdays',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: weekdays.map((day) {
                  return _buildDayButton(day);
                }).toList(),
              ),
              const SizedBox(height: 16),

              const Text('Water Usage Progress:'),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of Target Reached',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text('Device Usage:'),
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: activeDevices / 15,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.greenAccent),
                        ),
                        Text(
                          '${((activeDevices / 15) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daily Device Activation',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryCard('Total Usage', '$meterReading gallons'),
                  _buildSummaryCard('Average Usage',
                      '${averageUsage.toStringAsFixed(1)} gallons'),
                  _buildSummaryCard('Active Devices', '$activeDevices'),
                ],
              ),

              const SizedBox(height: 16),

              Center(
                child: Tooltip(
                  message: 'This is your current water consumption in gallons.',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop, size: 80, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(
                        '$meterReading',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'gallons',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(Icons.home, 'Home', () {}),
                _buildNavButton(Icons.payment, 'Pay', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentScreen()),
                  );
                }),
                _buildNavButton(Icons.settings, 'Settings', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          schedule['icon'],
          color: schedule['color'],
        ),
        title: Text(schedule['time']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schedule['description']),
            Text(
              'Duration: ${schedule['duration']} hours',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              'Assigned Devices: ${schedule['assignedDevices']}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editSchedule(index),
            ),
            Switch(
              value: schedule['isActive'],
              onChanged: (value) {
                setState(() {
                  schedule['isActive'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayButton(Day day) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: day.isSelected ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        setState(() {
          day.isSelected = !day.isSelected;
        });
      },
      child: Text(day.name),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onPressed) {
    return Flexible(
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Day {
  final String name;
  bool isSelected;

  Day({required this.name, this.isSelected = false});
}