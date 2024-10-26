import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'services/thingspeak_service.dart';
import 'models/temperature_humidity.dart';
import 'control_page.dart';
import 'settings_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ThingSpeakService _thingSpeakService;
  List<TemperatureHumidity> _dataList = []; // Changed from final to allow modification
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _thingSpeakService = ThingSpeakService(
      channelId: '2342037',
      readApiKey: 'FTZ54ZF6G1J1BDPY',
    );
    _loadData(); // Load saved data
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
      _saveData();
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

  // Function to calculate average temperature and humidity
  double _calculateAverage(List<TemperatureHumidity> data, bool isTemperature) {
    if (data.isEmpty) return 0.0;
    double total = data.fold(0, (sum, item) => sum + (isTemperature ? item.temperature : item.humidity));
    return total / data.length;
  }

  // Function to calculate max value
  double _calculateMax(List<TemperatureHumidity> data, bool isTemperature) {
    if (data.isEmpty) return 0.0;
    return isTemperature
        ? data.map((item) => item.temperature).reduce((a, b) => a > b ? a : b)
        : data.map((item) => item.humidity).reduce((a, b) => a > b ? a : b);
  }

  // Function to calculate min value
  double _calculateMin(List<TemperatureHumidity> data, bool isTemperature) {
    if (data.isEmpty) return 0.0;
    return isTemperature
        ? data.map((item) => item.temperature).reduce((a, b) => a < b ? a : b)
        : data.map((item) => item.humidity).reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    double averageTemperature = _calculateAverage(_dataList, true);
    double averageHumidity = _calculateAverage(_dataList, false);
    double maxTemperature = _calculateMax(_dataList, true);
    double minTemperature = _calculateMin(_dataList, true);
    double maxHumidity = _calculateMax(_dataList, false);
    double minHumidity = _calculateMin(_dataList, false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri-IoT Farm'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.shade900,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.agriculture,
                    color: Colors.lightGreen,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                    ),
                  ),
                ],
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
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedBox(
                  'Temperature',
                  _dataList.isNotEmpty ? _dataList.last.temperature : 0,
                  '°C',
                  Colors.green[700]!,
                ),
                _buildAnimatedBox(
                  'Humidity',
                  _dataList.isNotEmpty ? _dataList.last.humidity : 0,
                  '%',
                  Colors.blue[700]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Display average, max, and min values in animated boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedBox(
                  'Avg Temp',
                  averageTemperature,
                  '°C',
                  Colors.orange[700]!,
                ),
                _buildAnimatedBox(
                  'Avg Humidity',
                  averageHumidity,
                  '%',
                  Colors.orange[700]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedBox(
                  'Max Temp',
                  maxTemperature,
                  '°C',
                  Colors.red[700]!,
                ),
                _buildAnimatedBox(
                  'Min Temp',
                  minTemperature,
                  '°C',
                  Colors.red[700]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedBox(
                  'Max Humidity',
                  maxHumidity,
                  '%',
                  Colors.blue[700]!,
                ),
                _buildAnimatedBox(
                  'Min Humidity',
                  minHumidity,
                  '%',
                  Colors.blue[700]!,
                ),
              ],
            ),
            const SizedBox(height: 20),
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
        selectedItemColor: Colors.green[700],
        onTap: _onItemTapped,
      ),
    );
  }

  // Widget for animated dashboard box
  Widget _buildAnimatedBox(String title, double value, String unit, Color color) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$title',
            style: TextStyle(fontSize: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(2)} $unit',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
