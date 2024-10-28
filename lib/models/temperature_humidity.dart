import 'package:agri_iot_app/services/models/api_response.dart';

class TemperatureHumidity implements Serializable {
  final double temperature;
  final double humidity;
  final DateTime timestamp;

  TemperatureHumidity(
      {required this.temperature,
      required this.humidity,
      required this.timestamp});

  @override
  Map<String, dynamic> toJson() {
    return {
      "temperature": temperature,
      "humidity": humidity,
      "timestamp": timestamp,
    };
  }
}

class Feed implements Serializable {
  Channel? channel;
  List<FeedData>? feeds;

  Feed({
    this.channel,
    this.feeds,
  });

  factory Feed.fromJson(Map<String, dynamic> json) => Feed(
    channel: json["channel"] == null ? null : Channel.fromJson(json["channel"]),
    feeds: json["feeds"] == null ? [] : List<FeedData>.from(json["feeds"]!.map((x) => FeedData.fromJson(x))),
  );

  @override
  Map<String, dynamic> toJson() => {
    "channel": channel?.toJson(),
    "feeds": feeds == null ? [] : List<dynamic>.from(feeds!.map((x) => x.toJson())),
  };
}

class Channel implements Serializable {
  int? id;
  String? name;
  String? latitude;
  String? longitude;
  String? field1;
  String? field2;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? lastEntryId;

  Channel({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.field1,
    this.field2,
    this.createdAt,
    this.updatedAt,
    this.lastEntryId,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json["id"],
    name: json["name"],
    latitude: json["latitude"],
    longitude: json["longitude"],
    field1: json["field1"],
    field2: json["field2"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    lastEntryId: json["last_entry_id"],
  );

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "latitude": latitude,
    "longitude": longitude,
    "field1": field1,
    "field2": field2,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "last_entry_id": lastEntryId,
  };
}

class FeedData implements Serializable {
  DateTime? createdAt;
  int? entryId;
  String? field1;
  String? field2;

  FeedData({
    this.createdAt,
    this.entryId,
    this.field1,
    this.field2,
  });

  factory FeedData.fromJson(Map<String, dynamic> json) => FeedData(
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    entryId: json["entry_id"],
    field1: json["field1"],
    field2: json["field2"],
  );

  @override
  Map<String, dynamic> toJson() => {
    "created_at": createdAt?.toIso8601String(),
    "entry_id": entryId,
    "field1": field1,
    "field2": field2,
  };
}


// class TemperatureHumidity {
//   final double temperature;
//   final double humidity;
//   final DateTime timestamp; // Add a field to store the timestamp
//
//   // Update the constructor to properly initialize the timestamp
//   TemperatureHumidity({
//     required this.temperature,
//     required this.humidity,
//     required this.timestamp,
//   });
//
// // Getter for timestamp is no longer needed as it's directly accessible
// }
