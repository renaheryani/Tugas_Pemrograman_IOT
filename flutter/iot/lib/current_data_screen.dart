import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'api_service.dart'; // Import your ApiService

class CurrentDataScreen extends StatefulWidget {
  const CurrentDataScreen({super.key});

  @override
  State<CurrentDataScreen> createState() => _CurrentDataScreenState();
}

class _CurrentDataScreenState extends State<CurrentDataScreen> {
  Map<String, dynamic>? currentData;
  Timer? _timer;

  final ApiService _apiService = ApiService();

  // Customized color palette
  final Color _backgroundColor = const Color(0xFFF1F5F9); // Lighter background
  final Color _primaryColor = const Color(0xFFF9BE09); // Yellow
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF2D3748); // Dark grey

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: _primaryColor,
      statusBarIconBrightness: Brightness.light,
    ));

    _fetchCurrentData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCurrentData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Method to fetch the data from the API.
  void _fetchCurrentData() async {
    try {
      final data = await ApiService().fetchData();
      print(data); // Periksa apakah data berubah
      setState(() {
        currentData = data.last; // Pastikan data yang diterima sesuai
      });

      // Logika untuk memeriksa level gas
      if (currentData!['sensor_value_gas'] > 2500) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: Gas level is above 2500 PPM!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch data: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tugas IoT - Rena',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.sensors, color: _primaryColor),
          ),
        ],
      ),
      body: currentData == null
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHighlightCard(),
                  const SizedBox(height: 20),
                  _buildMetricsCards(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IoT Monitoring\nReal-Time Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lokasi: Cikutra, Kota Bandung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // Adjust card spacing
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Temperature',
                value: currentData!['sensor_value_temp'].toString(),
                unit: '°C',
                icon: Icons.thermostat,
                color: Colors.blue,
                isCompactHeader: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Humidity',
                value: currentData!['sensor_value_humidity'].toString(),
                unit: '%',
                icon: Icons.water_drop,
                color: Colors.green,
                isCompactHeader: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _buildMetricCard(
                title: 'Gas',
                value: currentData!['sensor_value_gas'].toString(),
                unit: 'ppm',
                icon: Icons.warning,
                color: Colors.red,
                isCompactHeader: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
    bool isCompactHeader = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompactHeader)
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: _textColor.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (isCompactHeader) const SizedBox(height: 8),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCompactHeader)
                      Text(
                        title,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '$value $unit',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
