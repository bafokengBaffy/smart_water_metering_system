import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'analytics_page.dart';
import 'billing_management_page.dart';
import 'home_screen_admin.dart';
import 'user_management_page.dart';
import 'settings_screen_admin.dart';

class MeterManagementPage extends StatefulWidget {
  const MeterManagementPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MeterManagementPageState createState() => _MeterManagementPageState();
}

class _MeterManagementPageState extends State<MeterManagementPage> {
  int _currentIndex = 4; // Set to 4 because Meters is the fifth tab
  bool _isLoading = false;

  final List<Map<String, dynamic>> _meters = [
    {
      'meterID': 'M001',
      'location': 'Ha Thetsane Industrial Area',
      'status': 'Active',
      'latitude': -29.3167, // Coordinates for Ha Thetsane Industrial Area
      'longitude': 27.4833,
    },
    {
      'meterID': 'M002',
      'location': 'New York City, USA',
      'status': 'Active',
      'latitude': 40.7128, // Coordinates for New York City
      'longitude': -74.0060,
    },
  ];

  late LocationData _currentLocation;
  final Location _location = Location();

  // Polyline variables
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _createPolylines();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location services are enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Check if location permissions are granted
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    // Fetch the current location
    try {
      _currentLocation = await _location.getLocation();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Could not get the location: $e");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create polylines between meter locations
  void _createPolylines() {
    for (var meter in _meters) {
      _polylineCoordinates.add(LatLng(meter['latitude'], meter['longitude']));
    }

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('meter_polyline'),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
          geodesic: true, // Draw curved lines for long distances
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meter Management',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewMeter,
            tooltip: 'Add New Meter',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMeterManagement(),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildMeterManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meter List',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._meters.map(
            (meter) => MeterCard(
              meter: meter,
              onStatusToggle: () {
                _toggleMeterStatus(_meters.indexOf(meter));
              },
              onViewLocation: () {
                _showMeterLocationOnMap(
                  meter['latitude'],
                  meter['longitude'],
                  meter['location'],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _addNewMeter,
              icon: const FaIcon(FontAwesomeIcons.circlePlus),
              label: const Text('Add New Meter'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMeterLocationOnMap(
    double latitude,
    double longitude,
    String locationName,
  ) {}

  void _toggleMeterStatus(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Status Change'),
            content: Text(
              'Are you sure you want to change the status of ${_meters[index]['meterID']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _meters[index]['status'] =
            _meters[index]['status'] == 'Active' ? 'Inactive' : 'Active';
      });
    }
  }

  void _addNewMeter() async {
    // Use the current location for the new meter
    if (_currentLocation.latitude == null ||
        _currentLocation.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch current location. Please try again.'),
        ),
      );
      return;
    }

    final TextEditingController meterIDController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Meter'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: meterIDController,
                  decoration: const InputDecoration(labelText: 'Meter ID'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        _meters.add({
          'meterID': meterIDController.text,
          'location': locationController.text,
          'status': 'Active',
          'latitude': _currentLocation.latitude!,
          'longitude': _currentLocation.longitude!,
        });
        _createPolylines(); // Update polylines when a new meter is added
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Handle navigation based on the selected index
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreenAdmin()),
        );
        break;
      case 1: // Analytics
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsPage()),
        );
        break;
      case 2: // Users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserManagementPage()),
        );
        break;
      case 3: // Billing
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BillingManagementPage(),
          ),
        );
        break;
      case 4: // Meters
        // Stay on the current page
        break;
      case 5: // Settings
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }
}

class MeterCard extends StatelessWidget {
  final Map<String, dynamic> meter;
  final VoidCallback onStatusToggle;
  final VoidCallback onViewLocation;

  const MeterCard({
    super.key,
    required this.meter,
    required this.onStatusToggle,
    required this.onViewLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: FaIcon(
          meter['status'] == 'Active'
              ? FontAwesomeIcons.water
              : FontAwesomeIcons.ban,
          color: meter['status'] == 'Active' ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(
          meter['meterID'].toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Location: ${meter['location']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onStatusToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color:
                      meter['status'] == 'Active'
                          ? Colors.green.withAlpha((0.2 * 255).toInt())
                          : Colors.red.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meter['status'],
                  style: TextStyle(
                    color:
                        meter['status'] == 'Active' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: onViewLocation,
              tooltip: 'View Location',
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Bottom Navigation Bar Widget
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Billing'),
        BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'Meters'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
