import 'dart:convert';
import 'api_core.dart';

mixin ApiBus on ApiCore {
  Future<String> getBusBay(String busNumber) async {
    final response = await apiGet('/api/bus');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus bays";
    }

    final body = jsonDecode(response.body);

    for (var bus in body) {
      if (bus["bus_id"] == busNumber) {
        if (bus["bus_bay"].toString() == "0") {
          return "RSP_NYA"; // Response: not yet arrived
        }
        return bus["bus_bay"].toString();
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
      bays[bus["bus_id"]] = bus["bus_bay"]?.toString();
    }
    return bays;
  }

  Future<List<Map<String, dynamic>>> getBusArrivals() async {
    // returns all data, including updated at times
    final response = await apiGet('/api/bus');

    if (response.statusCode != 200) {
      throw "Failed to fetch bus arrivals";
    }

    final body = jsonDecode(response.body)
        .map<Map<String, dynamic>>((bus) => bus as Map<String, dynamic>)
        .toList(); // cast to List<Map<String, dynamic>>
    return body;
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
      buses.add((bus["bus"]).toString());
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

  Future<Map> getStopsForBus(String busId) async {
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
    return body;
  }
}
