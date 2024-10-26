import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';
import 'control_page.dart';
import 'login_page.dart';
import 'services/thingspeak_service.dart';
import 'models/temperature_humidity.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 1;
  late ThingSpeakService _thingSpeakService;
  List<TemperatureHumidity> _dataList = []; // Changed from final to allow modification
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _thingSpeakService = ThingSpeakService(
      channelId: '2342037',
      readApiKey: 'FTZ54ZF6G1J1BDPY',
    );
    _loadData(); // Load saved data when the page initializes
    _fetchData();
    Timer.periodic(const Duration(seconds: 30), (timer) => _fetchData());
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedData = prefs.getStringList('temperature_humidity_data');

    if (savedData != null) {
      _dataList = savedData
          .map((data) {
        final parts = data.split(',');
        return TemperatureHumidity(
          temperature: double.parse(parts[0]),
          humidity: double.parse(parts[1]),
          timestamp: DateTime.parse(parts[2]),
        );
      })
          .toList();
    }

    setState(() {
      _isLoading = false; // Set loading to false after loading data
    });
  }

  Future<void> _fetchData() async {
    try {
      final data = await _thingSpeakService.fetchData();
      TemperatureHumidity newEntry = TemperatureHumidity(
        temperature: data['temperature'],
        humidity: data['humidity'],
        timestamp: DateTime.now(),
      );

      setState(() {
        _dataList.add(newEntry);
        _isLoading = false;
      });

      // Save the updated data list to SharedPreferences
      await _saveData();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> dataToSave = _dataList.map((entry) {
      return '${entry.temperature},${entry.humidity},${entry.timestamp.toIso8601String()}';
    }).toList();
    await prefs.setStringList('temperature_humidity_data', dataToSave);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ControlPage()),
      );
    }
  }

  // Function to build line charts
  Widget _buildLineChart(List<FlSpot> spots, Color lineColor, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.redAccent),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    colors: [lineColor],
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Convert live data to chart spots
  List<FlSpot> _convertToTemperatureSpots() {
    return _dataList
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.temperature))
        .toList();
  }

  List<FlSpot> _convertToHumiditySpots() {
    return _dataList
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.humidity))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphs'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: const Text('Graphs'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: const Text('Control Device'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ControlPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildLineChart(
              _convertToTemperatureSpots(),
              Colors.red,
              'Temperature Over Time',
            ),
            _buildLineChart(
              _convertToHumiditySpots(),
              Colors.blue,
              'Humidity Over Time',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'Graphs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new),
            label: 'Control',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
    );
  }
}
