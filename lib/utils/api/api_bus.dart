import 'dart:convert';
import 'package:appwrite/models.dart';
import 'package:runshaw/utils/config.dart';
import 'api_core.dart';

mixin ApiBus on ApiCore {
  Future<String?> getBusNumber() async {
    Preferences currentPrefs = await account.getPrefs();
    return currentPrefs.data["bus_number"];
  }

  Future<String> getBusBay(String busNumber) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/bus'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);

    for (var bus in body) {
      if (bus["bus_id"] == busNumber) {
        if (bus["bus_bay"].toString() == "0") {
          return "RSP_NYA"; // Reponse: not yet arrived
        }
        return bus["bus_bay"];
      }
    }
    return "RSP_UNK"; // Response: unknown (no idea where the bus is!)
  }

  Future<Map<String, String?>> getBusBays() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/bus'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    Map<String, String?> bays = {};
    for (var bus in body) {
      bays[bus["bus_id"]] = bus["bus_bay"];
    }
    return bays;
  }

  Future<String?> getBusFor(String userId) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/bus/for?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    return body;
  }

  Future<List<String>> getAllBuses() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/get'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    List<String> buses = [];
    for (var bus in body) {
      buses.add(bus["bus"]);
    }
    return buses;
  }

  Future<void> addExtraBus(String busId) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/add'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bus_number': busId}),
    );
    if (response.statusCode != 201) {
      throw "Error adding extra bus";
    }
  }

  Future<void> removeExtraBus(String busId) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/remove'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bus_number': busId}),
    );
    if (response.statusCode != 201) {
      throw "Error removing extra bus";
    }
  }
}
