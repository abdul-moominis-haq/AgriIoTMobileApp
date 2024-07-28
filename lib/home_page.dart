import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';
import 'services/thingspeak_service.dart';
import 'models/temperature_humidity.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ThingSpeakService _thingSpeakService;
  TemperatureHumidity? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _thingSpeakService = ThingSpeakService(
      channelId: '2342037',
      readApiKey: 'FTZ54ZF6G1J1BDPY',
    );
    _fetchData();
    // Fetch data every 30 seconds
    Timer.periodic(Duration(seconds: 30), (timer) => _fetchData());
  }

  Future<void> _fetchData() async {
    try {
      final data = await _thingSpeakService.fetchData();
      setState(() {
        _data = TemperatureHumidity(
          temperature: data['temperature'],
          humidity: data['humidity'],
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agri-IoT Farm'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
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
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings
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
            : _data != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
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
                    'Temperature: ${_data!.temperature} °C',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Humidity: ${_data!.humidity} %',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        )
            : Text('Failed to load data'),
      ),
    );
  }
}
