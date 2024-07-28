import 'dart:convert';
import 'package:http/http.dart' as http;

class ThingSpeakService {
  final String channelId;
  final String readApiKey;

  ThingSpeakService({required this.channelId, required this.readApiKey});

  Future<Map<String, dynamic>> fetchData() async {
    final url = Uri.parse(
      'https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$readApiKey&results=1',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final latestFeed = data['feeds'].last;
      return {
        'temperature': double.parse(latestFeed['field1']),
        'humidity': double.parse(latestFeed['field2']),
      };
    } else {
      throw Exception('Failed to load data');
    }
  }
}
