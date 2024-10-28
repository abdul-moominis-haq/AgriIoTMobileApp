import 'package:agri_iot_app/services/models/api_response.dart';
import 'package:agri_iot_app/services/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';
import 'control_page.dart';
import 'login_page.dart';
import 'services/thingspeak_service.dart';
import 'models/temperature_humidity.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // late Future<List<Map<String, dynamic>>> _data;
  // final ThingSpeakService _thingSpeakService = ThingSpeakService();
  int _selectedIndex = 1;
  late ThingSpeakService _thingSpeakService;
  List<TemperatureHumidity> _dataList = [];
  List<TemperatureHumidity> _filteredDataList = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // _data = _thingSpeakService.fetchData();

    _thingSpeakService = ThingSpeakService(
      channelId: '2554592',
      readApiKey: 'BYQJAPB6IBLM48MX',
    );
    _loadData();
    _fetchData();
    Timer.periodic(const Duration(seconds: 30), (timer) => _fetchData());
    // _loadData();
    // _fetchData();
    // Timer.periodic(const Duration(seconds: 30), (timer)=> _fetchData());
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedData = prefs.getStringList('temperature_humidity_data');

    if (savedData != null) {
      _dataList = savedData.map((data) {
        final parts = data.split(',');
        return TemperatureHumidity(
          temperature: double.parse(parts[0]),
          humidity: double.parse(parts[1]),
          timestamp: DateTime.parse(parts[2]),
        );
      }).toList();
      _applyFilter();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchData() async {
    try {
      final response = await _thingSpeakService.fetchData();

      if (response.status == ResponseStatus.success) {
        final List<TemperatureHumidity> entries = (response.data.feeds ?? []).map(
          (e) {
            return TemperatureHumidity(
              temperature: double.tryParse(e.field1 ?? "0.0") ?? 0.0,
              humidity: double.tryParse(e.field2 ?? "0.0") ?? 0.0,
              timestamp: DateTime.now(),
            );
          },
        ).toList();

        setState(() {
          _dataList = entries;
          _isLoading = false;
          // _applyFilter(); // Apply filter after fetching new data
        });

        _saveData();

        UiHelper.showSnackbar(context, message: "${_dataList.lastOrNull?.toJson()}");

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${response.message ?? "Data was not fetched"}"),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching data on settings: $e');
    }
  }

  // Future<void> _fetchData() async {
  //   try {
  //     final data = await _thingSpeakService.fetchData();
  //     TemperatureHumidity newEntry = TemperatureHumidity(
  //       temperature: data['temperature'],
  //       humidity: data['humidity'],
  //       timestamp: DateTime.now(),
  //     );
  //
  //     setState(() {
  //       _dataList.add(newEntry);
  //       _applyFilter();
  //       _isLoading = false;
  //     });
  //
  //     await _saveData();
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     print('Error fetching data: $e');
  //   }
  // }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> dataToSave = _dataList.map((entry) {
      return '${entry.temperature},${entry.humidity},${entry.timestamp.toIso8601String()}';
    }).toList();
    await prefs.setStringList('temperature_humidity_data', dataToSave);
  }

  // Filter data by selected date range
  void _applyFilter() {
    setState(() {
      _filteredDataList = _dataList.where((entry) {
        if (_startDate != null && entry.timestamp.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && entry.timestamp.isAfter(_endDate!)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Convert filtered data to chart spots
  List<FlSpot> _convertToTemperatureSpots() {
    return _filteredDataList
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.temperature))
        .toList();
  }

  List<FlSpot> _convertToHumiditySpots() {
    return _filteredDataList
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.humidity))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphs'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                  _applyFilter();
                });
              }
            },
          ),
        ],
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

  Widget _buildLineChart(List<FlSpot> spots, Color lineColor, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 50),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.purple),
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
}
