import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  // Time segment tracking
  List<double> _timeSegmentsUsage = [0.0, 0.0, 0.0, 0.0];
  final List<String> _timeSegmentLabels = [
    'Night (12AM-6AM)',
    'Morning (6AM-9AM)',
    'Daytime (9AM-5PM)',
    'Evening (5PM-12AM)',
  ];
  DateTime? _currentDay;

  // Database variables
  double _dailyTotalUsage = 0.0; // <-- Add this line
  double _weeklyAverage = 0.0;
  double _monthlyAverage = 0.0;
  double _previousTotalVolume = 0.0;
  final List<double> _monthlyData = List.filled(30, 0.0);
  double _currentFlowRate = 0.0;
  double _currentVolume = 0.0;
  double _peakFlow = 0.0;
  double _totalUsage = 0.0;
  List<double> _weeklyData = [];
  List<double> _dailyPeakFlows = List.filled(7, 0.0);
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  late DatabaseReference _databaseRef;
  late StreamSubscription<DatabaseEvent> _databaseSubscription;
  late DatabaseReference _usageStatsRef;

  int _getTimeSegmentIndex(DateTime time) {
    int hour = time.hour;
    if (hour >= 0 && hour < 6) return 0;
    if (hour >= 6 && hour < 9) return 1;
    if (hour >= 9 && hour < 17) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _weeklyData = List.filled(7, 0.0);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _initializeDatabaseListener();
  }

  Future<void> _initializeDatabaseListener() async {
    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://smart-water-metering-sys-default-rtdb.firebaseio.com',
      );

      _databaseRef = database.ref('sensor_readings');
      _usageStatsRef = database.ref('USAGE_STATISTICS');

      // Load historical data
      final sensorDataSnapshot = await _databaseRef.get(); // Fetch all entries
      if (sensorDataSnapshot.exists) {
        final allData = sensorDataSnapshot.value as Map<dynamic, dynamic>;
        allData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            _updateRealtimeData(value); // Process historical entries
          }
        });
      }

      // Load persisted totals and peaks
      final totalUsageSnapshot =
          await _usageStatsRef.child('total_usage').get();
      if (totalUsageSnapshot.exists) {
        setState(
          () => _totalUsage = (totalUsageSnapshot.value as num).toDouble(),
        );
      }

      final weeklySnapshot = await _usageStatsRef.child('weekly_data').get();
      if (weeklySnapshot.exists && weeklySnapshot.value != null) {
        setState(
          () =>
              _weeklyData = List<double>.from(
                weeklySnapshot.value as List<dynamic>,
              ),
        );
      }

      final peaksSnapshot = await _usageStatsRef.child('daily_peaks').get();
      if (peaksSnapshot.exists && peaksSnapshot.value != null) {
        setState(
          () =>
              _dailyPeakFlows = List<double>.from(
                peaksSnapshot.value as List<dynamic>,
              ),
        );
      }

      // Listen for new data
      _databaseSubscription = _databaseRef.onChildAdded.listen((
        DatabaseEvent event,
      ) {
        if (event.snapshot.value != null) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _updateRealtimeData(data);
        }
      }, onError: (error) => _handleError(error.toString()));

      setState(() => _isLoading = false);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _updateRealtimeData(Map<dynamic, dynamic> data) {
    try {
      DateTime dateTime;
      final timestampRaw = data['timestamp'];

      // 1. Parse timestamp
      if (timestampRaw is String) {
        try {
          dateTime = DateTime.parse(timestampRaw).toLocal();
        } catch (_) {
          debugPrint('Skipping invalid timestamp: $timestampRaw');
          return;
        }
      } else {
        final timestamp =
            (timestampRaw as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        dateTime =
            DateTime.fromMillisecondsSinceEpoch(
              timestamp * 1000,
              isUtc: true,
            ).toLocal();
      }

      // 2. Daily reset logic
      if (_currentDay?.day != dateTime.day) {
        _timeSegmentsUsage = [0.0, 0.0, 0.0, 0.0];
        _peakFlow = 0.0;
        _previousTotalVolume = 0.0; // Critical reset
        _dailyTotalUsage = 0.0; // Reset daily total
        _currentDay = dateTime;
      }

      // 3. Parse values safely
      final currentTotalVolume = _safeParseDouble(data['total_volume']) ?? 0.0;
      final flowRate = _safeParseDouble(data['Flow_rate']) ?? 0.0;

      // 4. Calculate valid incremental volume
      double incrementalVolume = currentTotalVolume - _previousTotalVolume;
      incrementalVolume = incrementalVolume < 0 ? 0 : incrementalVolume;
      _previousTotalVolume = currentTotalVolume;

      // 5. Update metrics
      final segmentIndex = _getTimeSegmentIndex(dateTime);
      _timeSegmentsUsage[segmentIndex] += incrementalVolume;
      _dailyTotalUsage += incrementalVolume;

      _updateWeeklyData(incrementalVolume, dateTime);
      _updateMonthlyData(incrementalVolume, dateTime);

      if (flowRate > _peakFlow) _peakFlow = flowRate;

      // 6. Update UI
      if (mounted) {
        setState(() {
          _currentFlowRate = flowRate;
          _currentVolume = currentTotalVolume;
        });
      }
    } catch (e) {
      debugPrint('Error updating data: $e');
    }
  }

  // Add this helper method for safe parsing
  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Update weekly/monthly methods to use DateTime instead of timestamp
  void _updateWeeklyData(double volume, DateTime dateTime) {
    int weekday = dateTime.weekday - 1;
    if (weekday >= 0 && weekday < 7) {
      _weeklyData[weekday] += volume;
      if (_currentFlowRate > _dailyPeakFlows[weekday]) {
        _dailyPeakFlows[weekday] = _currentFlowRate;
      }
    }
  }

  void _updateMonthlyData(double volume, DateTime dateTime) {
    int dayOfMonth = dateTime.day - 1;
    if (dayOfMonth < _monthlyData.length) {
      _monthlyData[dayOfMonth] += volume;
    }
  }

  void _calculateAverages() {
    try {
      // Weekly average calculation
      _weeklyAverage =
          _weeklyData.isNotEmpty
              ? _weeklyData.reduce((a, b) => a + b) / 7
              : 0.0;

      // Monthly average calculation
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final monthlySum =
          _monthlyData.isNotEmpty ? _monthlyData.reduce((a, b) => a + b) : 0.0;

      // Handle current day adjustment for partial months
      final daysToCalculate = min(now.day, daysInMonth);
      _monthlyAverage =
          daysToCalculate > 0 ? monthlySum / daysToCalculate : 0.0;
    } catch (e) {
      debugPrint('Error calculating averages: $e');
      _weeklyAverage = 0.0;
      _monthlyAverage = 0.0;
    }
  }

  void _handleError(String error) {
    debugPrint('Error: $error');
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _initializeDatabaseListener,
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaymentScreen()),
        );
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasError) return _buildErrorScreen();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 80.0),
        child: Column(
          children: [
            const Text(
              'Water Analytics',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildRealtimeMetrics(),
            const SizedBox(height: 20),
            _buildUsageComparisonCard(),
            const SizedBox(height: 20),
            _buildMainMetrics(),
            const SizedBox(height: 20),
            _buildTimeSegmentsChart(),
            const SizedBox(height: 20),
            _buildWeeklyChartSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeDatabaseListener,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildRealtimeMetrics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Current Readings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRealtimeMetric(
                  'Flow Rate',
                  '${_currentFlowRate.toStringAsFixed(2)} L/min',
                  Icons.speed,
                  Colors.blue,
                ),
                _buildRealtimeMetric(
                  'Current Volume',
                  '${_currentVolume.toStringAsFixed(2)} L',
                  Icons.water_drop,
                  Colors.lightBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealtimeMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageComparisonCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.leaderboard, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Usage Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    LinearProgressIndicator(
                      value:
                          _currentVolume /
                          (_currentVolume > 0 ? _currentVolume * 1.5 : 1),
                      minHeight: 20,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.blue.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current Volume: ${_currentVolume.toStringAsFixed(1)} L',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainMetrics() {
    final today = DateTime.now().weekday - 1;
    _calculateAverages();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Usage',
                value: _totalUsage.toStringAsFixed(0),
                unit: 'Liters',
                icon: Icons.water_drop,
                color: Colors.blue,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Today\'s Peak',
                value: _dailyPeakFlows[today].toStringAsFixed(1),
                unit: 'L/day',
                icon: Icons.opacity,
                color: Colors.lightBlue,
                isLoading: _isLoading,
              ),
            ),
            // In _buildMainMetrics()
            Expanded(
              child: _MetricCard(
                title: 'Today\'s Usage',
                value: _dailyTotalUsage.toStringAsFixed(1),
                unit: 'Liters',
                icon: Icons.water_drop,
                color: Colors.blue,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Weekly Average',
                value: _weeklyAverage.toStringAsFixed(1),
                unit: 'L/day',
                icon: Icons.calendar_view_week,
                color: Colors.green,
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Monthly Average',
                value: _monthlyAverage.toStringAsFixed(1),
                unit: 'L/day',
                icon: Icons.calendar_month,
                color: Colors.orange,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSegmentsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Daily Usage by Time Segment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_timeSegmentLabels[groupIndex]}\n'
                          'Usage: ${_timeSegmentsUsage[groupIndex].toStringAsFixed(1)} L',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _timeSegmentLabels[value.toInt()],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      axisNameWidget: Text('Usage (L)'),
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups:
                      _timeSegmentsUsage.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value,
                              color: Colors.blue,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChartSection() {
    return Column(
      children: [
        const Text(
          'Weekly Usage Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildWeeklyBarChart(),
        _buildWeeklyTable(),
      ],
    );
  }

  Widget _buildWeeklyBarChart() {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Peak: ${_dailyPeakFlows[groupIndex].toStringAsFixed(1)} L/day\n'
                  'Total: ${_weeklyData[groupIndex].toStringAsFixed(1)} L',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              axisNameWidget: Text('Peak Flow (L/day)'),
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final days = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt()]),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          barGroups:
              _dailyPeakFlows.asMap().entries.map((entry) {
                final idx = entry.key;
                final value = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      gradient: LinearGradient(
                        colors: [Colors.lightBlue, Colors.blue],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 20,
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyTable() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = DateTime.now().weekday - 1; // Monday=0, Sunday=6

    return DataTable(
      columns: const [
        DataColumn(label: Text('Day')),
        DataColumn(label: Text('Total (L)')),
        DataColumn(label: Text('Peak (L/day)')),
      ],
      rows: List.generate(7, (index) {
        // Use today's usage for the current day
        final total =
            (index == todayIndex)
                ? _dailyTotalUsage
                : (_weeklyData.length > index)
                ? _weeklyData[index]
                : 0.0;

        final peak =
            (_dailyPeakFlows.length > index) ? _dailyPeakFlows[index] : 0.0;

        return DataRow(
          cells: [
            DataCell(Text(days[index])),
            DataCell(Text(total.toStringAsFixed(1))),
            DataCell(Text(peak.toStringAsFixed(1))),
          ],
        );
      }),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        height: 70,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(
              icon: Icons.home,
              label: "Home",
              isActive: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            _NavButton(
              icon: Icons.analytics,
              label: "Stats",
              isActive: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            _NavButton(
              icon: Icons.payment,
              label: "Pay",
              isActive: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            _NavButton(
              icon: Icons.settings,
              label: "Settings",
              isActive: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _databaseSubscription.cancel();
    _animationController.dispose();
    super.dispose();
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const LinearProgressIndicator()
                : Text(
                  '$value $unit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ],
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? Colors.blueAccent.withAlpha((0.2 * 255).toInt())
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
