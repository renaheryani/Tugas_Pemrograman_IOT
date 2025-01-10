import 'dart:async';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic>? historyData;
  Timer? _timer;
  String selectedMetric = 'Temperature';
  String selectedTimeRange = '1h';

  final metrics = ['Temperature', 'Humidity', 'Gas'];
  final metricKeys = {
    'Temperature': 'sensor_value_temp',
    'Humidity': 'sensor_value_humidity',
    'Gas': 'sensor_value_gas'
  };

  final timeRanges = {
    '1h': const Duration(hours: 1),
    '6h': const Duration(hours: 6),
    '24h': const Duration(hours: 24),
    '7d': const Duration(days: 7),
  };

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchHistoryData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchHistoryData() async {
    try {
      final data = await ApiService().fetchData();
      setState(() {
        historyData = data;
      });

      // Cek apakah ada level gas yang melebihi 2500
      if (data.isNotEmpty) {
        final latestData = data.last; // Ambil data terbaru
        final gasLevel = latestData['sensor_value_gas'];
        if (gasLevel > 2500) {
          // Tampilkan notifikasi
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Warning: Gas level too high! (${gasLevel.toStringAsFixed(1)})'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch data: $e')),
        );
      }
    }
  }

  List<dynamic> _getFilteredData() {
    if (historyData == null) return [];

    final now = DateTime.now();
    final duration = timeRanges[selectedTimeRange]!;
    final cutoffTime = now.subtract(duration);

    return historyData!
        .where((item) => DateTime.parse(item['timestamp']).isAfter(cutoffTime))
        .toList()
        .reversed
        .take(10) // Limit to 10 most recent entries
        .toList()
        .reversed
        .toList(); // Reverse back to chronological order
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: historyData == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 16),
                    _buildMetricSelector(),
                    const SizedBox(height: 24),
                    Expanded(child: _buildChart()),
                    const SizedBox(height: 16),
                    _buildStatistics(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: timeRanges.keys.map((range) {
          final isSelected = range == selectedTimeRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => selectedTimeRange = range),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.yellow[700] // Warna kuning 700 saat dipilih
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Colors.yellow[700]! // Warna kuning 700 untuk border
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey[600],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: metrics.map((metric) {
          final isSelected = metric == selectedMetric;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => selectedMetric = metric),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.yellow[700]
                      : Colors.transparent, // Warna kuning saat dipilih
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  metric,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.black
                        : Colors.grey[600], // Teks hitam saat dipilih
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          'No data available for selected time range',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final data = filteredData
        .map((item) => HistoryData(
              DateTime.parse(item['timestamp']),
              item[metricKeys[selectedMetric]!].toDouble(),
            ))
        .toList();

    final series = [
      charts.Series<HistoryData, DateTime>(
        id: selectedMetric,
        data: data,
        domainFn: (HistoryData data, _) => data.timestamp,
        measureFn: (HistoryData data, _) => data.value,
        colorFn: (_, __) =>
            charts.ColorUtil.fromDartColor(const Color(0xFF2D3250)),
      )
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: charts.TimeSeriesChart(
        series,
        animate: true,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec: const charts.BasicNumericTickProviderSpec(
            desiredTickCount: 5,
          ),
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 12,
              color: charts.ColorUtil.fromDartColor(Colors.grey[600]!),
            ),
            lineStyle: charts.LineStyleSpec(
              color: charts.ColorUtil.fromDartColor(Colors.grey[300]!),
            ),
          ),
        ),
        domainAxis: charts.DateTimeAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 12,
              color: charts.ColorUtil.fromDartColor(Colors.grey[600]!),
            ),
            lineStyle: charts.LineStyleSpec(
              color: charts.ColorUtil.fromDartColor(Colors.grey[300]!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final filteredData = _getFilteredData();
    if (filteredData.isEmpty) return const SizedBox();

    final values = filteredData
        .map((item) => item[metricKeys[selectedMetric]!].toDouble())
        .toList();

    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.4), // Bayangan kuning
            blurRadius: 20, // Tingkat blur
            offset: const Offset(0, 8), // Posisi bayangan
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Bayangan hitam lembut
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Average', avg.toStringAsFixed(1)),
          _buildStatItem('Maximum', max.toStringAsFixed(1)),
          _buildStatItem('Minimum', min.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3250),
          ),
        ),
      ],
    );
  }
}

class HistoryData {
  final DateTime timestamp;
  final double value;

  HistoryData(this.timestamp, this.value);
}
