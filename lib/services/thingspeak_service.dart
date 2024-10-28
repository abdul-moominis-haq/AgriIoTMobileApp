import 'dart:convert';
import 'package:agri_iot_app/models/temperature_humidity.dart';
import 'package:agri_iot_app/services/models/api_response.dart';
import 'package:http/http.dart' as http;

class ThingSpeakService {
  final String channelId;
  final String readApiKey;

  ThingSpeakService({required this.channelId, required this.readApiKey});

  Future<ApiResponse<Feed>> fetchData() async {
    try{
      // prepare api url for api call
      final url = Uri.parse(
        'https://api.thingspeak.com/channels/$channelId/feeds.json?api_key=$readApiKey&results=100',
      );

      // make api cal to prepared url above
      final response = await http.get(url);
      // final response = await http.get(Uri.parse("$_baseUrl/channels/$_channelId/feeds.json?api_key=$_readApiKey"));

      final data = json.decode(response.body);
      print("Data from api is $data");

      if (response.statusCode >= 200 && response.statusCode <= 300) {
        final feedData = Feed.fromJson(data);
        final apiResponse = ApiResponse(
          status: ResponseStatus.success,
          data: feedData,
          message: response.reasonPhrase,
        );
        return apiResponse;
        // final latestFeed = data['feeds'].last;
        // final feedData = FeedData.fromJson(data);
        // return feedData;
        // return {
        //   'temperature': double.parse(latestFeed['field1']),
        //   'humidity': double.parse(latestFeed['field2']),
        // };
      } else {
        final apiResponse = ApiResponse(
          status: ResponseStatus.failure,
          data: Feed(),
          message: response.reasonPhrase,
        );
        return apiResponse;
      }
    }catch(e){
      print("API Error: $e");
      final apiResponse = ApiResponse(
        status: ResponseStatus.failure,
        data: Feed(),
        message: "$e",
      );
      return apiResponse;
    }
  }
}
