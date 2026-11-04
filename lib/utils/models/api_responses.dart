/// Typed models for backend responses. Parsers accept the current snake_case fields 
/// and camelCase aliases in case the serialiser changes in the future
class BusArrival {
  const BusArrival({
    required this.id,
    required this.bay,
    required this.arrivalTime,
    this.routeMap,
  });

  final String id;
  final String? bay;
  final DateTime? arrivalTime;
  final String? routeMap;

  factory BusArrival.fromJson(Map<String, dynamic> json) => BusArrival(
        id: _read(json, 'bus_id', 'busId')?.toString() ?? '',
        bay: _read(json, 'bus_bay', 'busBay')?.toString(),
        arrivalTime: DateTime.tryParse(
          _read(json, 'arrival_time', 'arrivalTime')?.toString() ?? '',
        ),
        routeMap: _read(json, 'route_map', 'routeMap')?.toString(),
      );
}

class BusSubscriptionData {
  const BusSubscriptionData(this.busId);

  final String busId;

  factory BusSubscriptionData.fromJson(Map<String, dynamic> json) =>
      BusSubscriptionData(json['bus']?.toString() ?? '');
}

class BusStop {
  const BusStop({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
        name: json['name']?.toString() ?? '',
        latitude: _readDouble(json['latitude']),
        longitude: _readDouble(json['longitude']),
      );
}

class BusRoute {
  const BusRoute({required this.stops, required this.description});

  final List<BusStop> stops;
  final String description;

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return BusRoute(
      stops: rawStops is List
          ? rawStops
              .whereType<Map>()
              .map((stop) => BusStop.fromJson(_asJsonMap(stop)))
              .toList(growable: false)
          : const [],
      description: json['description']?.toString() ?? '',
    );
  }
}

class InAppNoticeData {
  const InAppNoticeData({
    required this.id,
    required this.title,
    required this.description,
    required this.android,
    required this.ios,
    this.expires,
    this.imageUrl,
    this.link,
    this.linkText,
    this.minVersion,
    this.maxVersion,
  });

  final String id;
  final String title;
  final String description;
  final bool android;
  final bool ios;
  final DateTime? expires;
  final String? imageUrl;
  final String? link;
  final String? linkText;
  final String? minVersion;
  final String? maxVersion;

  factory InAppNoticeData.fromJson(Map<String, dynamic> json) =>
      InAppNoticeData(
        id: json['noticeId']?.toString() ?? json['notice_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        android: _readBool(json, 'android', 'Android', defaultValue: true),
        ios: _readBool(json, 'ios', 'Ios', defaultValue: true),
        expires: DateTime.tryParse(json['expires']?.toString() ?? ''),
        imageUrl: _read(json, 'imageUrl', 'imageurl')?.toString(),
        link: json['link']?.toString(),
        linkText: _read(json, 'linkText', 'linktext')?.toString(),
        minVersion: _read(json, 'minVersion', 'minversion')?.toString(),
        maxVersion: _read(json, 'maxVersion', 'maxversion')?.toString(),
      );
}

class FriendRequestData {
  const FriendRequestData({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
  });

  final int id;
  final String senderId;
  final String receiverId;
  final String status;

  factory FriendRequestData.fromJson(Map<String, dynamic> json) =>
      FriendRequestData(
        id: _readInt(json, 'id', 'requestId'),
        senderId: _read(json, 'sender_id', 'senderId')?.toString() ?? '',
        receiverId: _read(json, 'receiver_id', 'receiverId')?.toString() ?? '',
        status: json['status']?.toString() ?? '',
      );
}

Object? _read(Map<String, dynamic> json, String first, String second) =>
    json[first] ?? json[second];

bool _readBool(
  Map<String, dynamic> json,
  String first,
  String second, {
  required bool defaultValue,
}) {
  final value = _read(json, first, second);
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return defaultValue;
}

int _readInt(
  Map<String, dynamic> json,
  String first,
  String second,
) {
  final value = _read(json, first, second);
  return value is int ? value : int.tryParse('$value') ?? 0;
}

double _readDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

Map<String, dynamic> _asJsonMap(Map value) =>
    value.map((key, value) => MapEntry('$key', value));
