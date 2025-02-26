import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreenAdmin extends StatefulWidget {
  const HomeScreenAdmin({super.key});

  @override
  State<HomeScreenAdmin> createState() => _HomeScreenAdminState();
}

class _HomeScreenAdminState extends State<HomeScreenAdmin> {
  final List<Map<String, dynamic>> _users = [
    {'name': 'User 1', 'usage': 150, 'status': 'Active', 'account': 'Premium'},
    {'name': 'User 2', 'usage': 75, 'status': 'Active', 'account': 'Basic'},
    {'name': 'User 3', 'usage': 300, 'status': 'Inactive', 'account': 'Premium'},
  ];

  final List<Map<String, dynamic>> _alerts = [
    {'type': 'Leak', 'location': 'Zone A', 'time': '2h ago', 'resolved': false},
    {'type': 'Low Pressure', 'location': 'Main Line', 'time': '5h ago', 'resolved': true},
    {'type': 'High Usage', 'location': 'User 5', 'time': '8h ago', 'resolved': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Text(
                'Admin Tools',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(Icons.people, 'User Management'),
            _buildDrawerItem(Icons.analytics, 'System Analytics'),
            _buildDrawerItem(Icons.settings, 'System Configuration'),
            _buildDrawerItem(Icons.report, 'Reports'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemOverview(),
            const SizedBox(height: 20),
            _buildUsageChart(),
            const SizedBox(height: 20),
            _buildRecentAlerts(),
            const SizedBox(height: 20),
            _buildUserManagement(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'System Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total Users', '1,234', Icons.people),
                  _buildStatCard('Active Devices', '5,678', Icons.device_hub),
                  _buildStatCard('Daily Usage', '50,000L', Icons.water_drop),
                  _buildStatCard('Active Alerts', '3', Icons.warning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Water Usage Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(1, 1),
                        FlSpot(2, 4),
                        FlSpot(3, 2),
                        FlSpot(4, 5),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._alerts.map((alert) => ListTile(
              leading: Icon(Icons.warning,
                  color: alert['resolved'] ? Colors.green : Colors.red),
              title: Text(alert['type'].toString()),
              subtitle: Text('${alert['location']} • ${alert['time']}'),
              trailing: Text(
                alert['resolved'] ? 'Resolved' : 'Pending',
                style: TextStyle(
                    color: alert['resolved'] ? Colors.green : Colors.red),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Usage (L)')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Account')),
                ],
                rows: _users
                    .map((user) => DataRow(
                  cells: [
                    DataCell(Text(user['name'].toString())),
                    DataCell(Text(user['usage'].toString())),
                    DataCell(
                      Chip(
                        label: Text(user['status'].toString()),
                        backgroundColor: user['status'] == 'Active'
                            ? Colors.green[100]
                            : Colors.red[100],
                      ),
                    ),
                    DataCell(Text(user['account'].toString())),
                  ],
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {},
    );
  }
}