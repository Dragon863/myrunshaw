import 'dart:convert';
import 'api_core.dart';
import 'package:runshaw/utils/models/api_responses.dart';

mixin ApiBus on ApiCore {
  Future<String> getBusBay(String busNumber) async {
    final response = await apiGet('/api/bus');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus bays";
    }

    final body = jsonDecode(response.body);

    for (var bus in body) {
      final arrival =
          BusArrival.fromJson(Map<String, dynamic>.from(bus as Map));
      if (arrival.id == busNumber) {
        if (arrival.bay == "0") {
          return "RSP_NYA"; // Response: not yet arrived
        }
        return arrival.bay ?? 'RSP_UNK';
      }
    }
    return "RSP_UNK"; // Response: unknown (no idea where the bus is!)
  }

  Future<Map<String, String?>> getBusBays() async {
    final response = await apiGet('/api/bus');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus bays";
    }

    final body = jsonDecode(response.body);
    Map<String, String?> bays = {};
    for (var bus in body) {
      final arrival =
          BusArrival.fromJson(Map<String, dynamic>.from(bus as Map));
      bays[arrival.id] = arrival.bay;
    }
    return bays;
  }

  Future<List<BusArrival>> getBusArrivals() async {
    // returns all data, including updated at times
    final response = await apiGet('/api/bus');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus arrivals";
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((bus) => BusArrival.fromJson(Map<String, dynamic>.from(bus)))
        .toList(growable: false);
  }

  Future<String?> getBusFor(String userId) async {
    final response = await apiGet('/api/bus/for?user_id=$userId');

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    return body?.toString();
  }

  Future<List<String>> getAllSubscribedBuses() async {
    final response = await apiGet('/api/extra_buses/get');

    if (response.statusCode != 200) {
      throw "Failed to fetch buses";
    }

    final body = jsonDecode(response.body);
    List<String> buses = [];

    for (var bus in body) {
      buses.add(
        BusSubscriptionData.fromJson(Map<String, dynamic>.from(bus as Map))
            .busId,
      );
    }
    return buses;
  }

  Future<void> addBus(String busId) async {
    final response = await apiPost(
      '/api/extra_buses/add',
      body: {'bus_number': busId},
    );

    if (response.statusCode != 200) {
      throw humanResponse(response.body);
    }
  }

  Future<void> removeBus(String busId) async {
    final response = await apiPost(
      '/api/extra_buses/remove',
      body: {'bus_number': busId},
    );

    if (response.statusCode != 200) {
      throw humanResponse(response.body);
    }
  }

  Future<BusRoute> getStopsForBus(String busId) async {
    final response = await apiGet('/api/bus/stops?bus_id=$busId');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus stops";
    }
    /*
    Example response:
    {
    description: "Preston & Leyland",
    stops: [
      {
        "name": "Demo Stop",
        "latitude": 53.9999,
        "longitude": -3.0000
      },
      {
        "name": "Example Road",
        "latitude": 53.6000000,
        "longitude": -3.00001,
      }
    ]
    }
    */
    final body = jsonDecode(response.body);
    if (body is! Map) return const BusRoute(stops: [], description: '');
    return BusRoute.fromJson(Map<String, dynamic>.from(body));
  }
}
