import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'analytics_page.dart';
import 'home_screen_admin.dart'; // Import the HomeScreenAdmin
import 'user_management_page.dart'; // Import the UserManagementPage
import 'meter_management_page.dart'; // Import the MeterManagementPage
import 'settings_screen_admin.dart'; // Import the SettingsScreen

class BillingManagementPage extends StatefulWidget {
  const BillingManagementPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BillingManagementPageState createState() => _BillingManagementPageState();
}

class _BillingManagementPageState extends State<BillingManagementPage> {
  final List<Map<String, dynamic>> _bills = [
    {
      'billID': 'B001',
      'customerName': 'User 1',
      'amount': 150.0,
      'status': 'Paid',
    },
    {
      'billID': 'B002',
      'customerName': 'User 2',
      'amount': 75.0,
      'status': 'Pending',
    },
    {
      'billID': 'B003',
      'customerName': 'User 3',
      'amount': 300.0,
      'status': 'Paid',
    },
  ];

  int _currentIndex =
      3; // Track the selected index for bottom navigation (Billing is index 3)

  void _toggleBillStatus(int index) {
    setState(() {
      _bills[index]['status'] =
          _bills[index]['status'] == 'Paid' ? 'Pending' : 'Paid';
    });
  }

  void _generateNewBill() {
    setState(() {
      _bills.add({
        'billID': 'B00${_bills.length + 1}',
        'customerName': 'User ${_bills.length + 1}',
        'amount': 100.0,
        'status': 'Pending',
      });
    });
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
        // Stay on the current page
        break;
      case 4: // Meters
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MeterManagementPage()),
        );
        break;
      case 5: // Settings
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Billing Management',
          style: GoogleFonts.roboto(), // Using Google Fonts for the title
        ),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _generateNewBill,
            tooltip: 'Generate New Bill',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._bills.map(
              (bill) => BillingCard(
                bill: bill,
                onStatusToggle: () {
                  _toggleBillStatus(_bills.indexOf(bill));
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _generateNewBill,
                child: const Text('Generate New Bill'),
              ),
            ),
            const SizedBox(height: 20),
            // Example of a chart from fl_chart dependency
            const Text(
              'Billing Status Chart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(fromY: 0, toY: 4, color: Colors.green),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(fromY: 0, toY: 3, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class BillingCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onStatusToggle;

  const BillingCard({
    super.key,
    required this.bill,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          bill['billID'].toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Customer: ${bill['customerName']}'),
            Text('Amount: M${bill['amount']}'), // Changed from $ to M
          ],
        ),
        trailing: GestureDetector(
          onTap: onStatusToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color:
                  bill['status'] == 'Paid'
                      ? Colors.green.withAlpha((0.2 * 255).toInt())
                      : Colors.red.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              bill['status'],
              style: TextStyle(
                color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
