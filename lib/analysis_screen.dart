import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts
import 'dart:async'; // For periodic updates

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool isLoading = true;
  bool hasError = false;
  double selectedTimePeriod = 1;
  int totalEnergyConsumption = 500;
  int peakEnergyUsage = 120;
  String selectedDevice = 'Device 1';
  List<String> devices = ['Device 1', 'Device 2', 'Device 3', 'Device 4'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      await Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detailed Analytics'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detailed Analytics'),
        ),
        body: const Center(
          child: Text('Error loading data, please try again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                'Welcome to the Analysis Screen!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Here you can display detailed metrics, charts, and insights.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // Total Energy Consumption Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Total Energy Consumption',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$totalEnergyConsumption kWh',
                        style: const TextStyle(
                            fontSize: 22, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Peak Energy Usage Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Peak Energy Usage',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$peakEnergyUsage kWh',
                        style: const TextStyle(
                            fontSize: 22, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Time Period Selector (Dialog)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 20.0),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final selectedPeriod = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Time Period'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<int>(
                            title: const Text('Daily'),
                            value: 1,
                            groupValue: selectedTimePeriod.toInt(),
                            onChanged: (value) {
                              Navigator.pop(context, value);
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Weekly'),
                            value: 7,
                            groupValue: selectedTimePeriod.toInt(),
                            onChanged: (value) {
                              Navigator.pop(context, value);
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text('Monthly'),
                            value: 30,
                            groupValue: selectedTimePeriod.toInt(),
                            onChanged: (value) {
                              Navigator.pop(context, value);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                  if (selectedPeriod != null) {
                    setState(() {
                      selectedTimePeriod = selectedPeriod.toDouble();
                    });
                  }
                },
                child: Text('Show Data for Last $selectedTimePeriod Days'),
              ),
              const SizedBox(height: 40),

              // Tabbed Charts Section
              DefaultTabController(
                length: 4, // Number of tabs (charts)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Line Chart'),
                        Tab(text: 'Bar Chart'),
                        Tab(text: 'Histogram'),
                        Tab(text: 'Pie Chart'),
                      ],
                    ),
                    SizedBox(
                      height: 300, // Height for the chart section
                      child: const TabBarView(
                        children: [
                          LineChartSection(),
                          BarChartSection(),
                          HistogramSection(),
                          PieChartSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Device Filtering Dropdown
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    value: selectedDevice,
                    isExpanded: true,
                    items: devices
                        .map((device) => DropdownMenuItem(
                              value: device,
                              child: Text(device),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDevice = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Refresh and Go Back Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent),
                    child: const Text('Refresh Data'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartSection extends StatelessWidget {
  const LineChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Mon');
                    case 1:
                      return const Text('Tue');
                    case 2:
                      return const Text('Wed');
                    case 3:
                      return const Text('Thu');
                    case 4:
                      return const Text('Fri');
                    case 5:
                      return const Text('Sat');
                    case 6:
                      return const Text('Sun');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(1, 2),
                FlSpot(2, 4),
                FlSpot(3, 5),
                FlSpot(4, 4),
                FlSpot(5, 3),
                FlSpot(6, 5),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 5,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class BarChartSection extends StatelessWidget {
  const BarChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 8, color: Colors.blue), // toY is now 8
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 6, color: Colors.blue), // toY is now 6
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 7, color: Colors.blue), // toY is now 7
            ]),
            BarChartGroupData(x: 3, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 5, color: Colors.blue), // toY is now 5
            ]),
          ],
        ),
      ),
    );
  }
}

class HistogramSection extends StatelessWidget {
  const HistogramSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(show: true),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 4, color: Colors.green), // toY is now 4
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 3, color: Colors.green), // toY is now 3
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 2, color: Colors.green), // toY is now 2
            ]),
            BarChartGroupData(x: 3, barRods: [
              BarChartRodData(
                  fromY: 0, toY: 1, color: Colors.green), // toY is now 1
            ]),
          ],
        ),
      ),
    );
  }
}

class PieChartSection extends StatelessWidget {
  const PieChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 25,
              color: Colors.blue,
              title: '25%',
            ),
            PieChartSectionData(
              value: 50,
              color: Colors.green,
              title: '50%',
            ),
            PieChartSectionData(
              value: 25,
              color: Colors.red,
              title: '25%',
            ),
          ],
        ),
      ),
    );
  }
}
