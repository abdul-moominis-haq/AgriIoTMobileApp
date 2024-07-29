import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart' show BarAreaData, FlBorderData, FlGridData, FlSpot, FlTitlesData, LineChart, LineChartBarData, LineChartData;
import 'services/thingspeak_service.dart';
import 'models/temperature_humidity.dart' show TemperatureHumidity;
import 'control_page.dart' show ControlPage;
import 'settings_page.dart';
import 'package:agri_iot_app/login_page.dart' show LoginPage;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ThingSpeakService _thingSpeakService;
  List<TemperatureHumidity> _dataList = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _thingSpeakService = ThingSpeakService(
      channelId: '2342037',
      readApiKey: 'FTZ54ZF6G1J1BDPY',
    );
    _fetchData();
    Timer.periodic(Duration(seconds: 30), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final data = await _thingSpeakService.fetchData();
      setState(() {
        _dataList.add(TemperatureHumidity(
          temperature: data['temperature'],
          humidity: data['humidity'],
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ControlPage()),
      );
    }
  }

  List<FlSpot> _createTemperatureSpots() {
    return _dataList
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.temperature))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri-IoT Farm'),
        backgroundColor: Colors.green[700],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.power_settings_new),
              title: Text('Control Device'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ControlPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16.0),
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Temperature: ${_dataList.isNotEmpty ? _dataList.last.temperature : 'N/A'} °C',
                    style: TextStyle(fontSize: 24, color: Colors.green[900]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Humidity: ${_dataList.isNotEmpty ? _dataList.last.humidity : 'N/A'} %',
                    style: TextStyle(fontSize: 24, color: Colors.green[900]),
                  ),
                  SizedBox(height: 16),
                  _dataList.isNotEmpty
                      ? SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey),
                        ),
                        minX: 0,
                        maxX: _dataList.length.toDouble(),
                        minY: 0,
                        maxY: 40, // assuming temperature range
                        lineBarsData: [
                          LineChartBarData(
                            spots: _createTemperatureSpots(),
                            isCurved: true,
                            colors: [Colors.green],
                            barWidth: 3,
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  )
                      : Text('No temperature data available.'),
                ],
              ),
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
            icon: Icon(Icons.settings),
            label: 'Settings',
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
}
