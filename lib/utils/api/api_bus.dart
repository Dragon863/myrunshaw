import 'dart:convert';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_core.dart';

mixin ApiBus on ApiCore {
  Future<void> setBusNumber(String? number) async {
    // LEGACY CODE, should not be run
    // Preferences currentPrefs = await account.getPrefs();
    // await OneSignal.User.addTagWithKey("bus", number);

    // if (currentPrefs.data["bus_number"] == number) {
    //   return;
    // }
    // currentPrefs.data["bus_number"] = number;
    // await account.updatePrefs(prefs: currentPrefs.data);
  }

  Future<void> migrateBuses() async {
    // LEGACY: since it's been 6 months, it's safe to assume migration has happened or the user was inactive
    // for long enough that their account was deleted in compliance with GDPR

    // This is a one-time migration to remove the bus_number key from the prefs, and move to the new approach
    // which is to use the extra_buses endpoint and OneSignal's external IDs
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    bool migrated = prefs.getBool("migrated_buses") ?? false;
    debugLog("Has migrated buses: $migrated");
    if (migrated && !kDebugMode) {
      return;
    }

    try {
      // Primary bus was stored in Appwrite preferences
      Preferences currentPrefs = await account.getPrefs();

      // Remove the bus tag from OneSignal
      await OneSignal.User.removeTag("bus");

      // Check if bus_number exists and is not null before adding it as an extra bus
      String? busNumber = currentPrefs.data["bus_number"];
      debugLog("Migrating bus number: $busNumber");
      if (busNumber != null && busNumber.isNotEmpty) {
        await addExtraBus(busNumber);
        debugLog("Added bus number as extra bus");
      }

      // Remove the bus number from the prefs if it exists
      currentPrefs.data.remove("bus_number");
      debugLog("Removed bus number from prefs");

      // Update the prefs
      await account.updatePrefs(prefs: currentPrefs.data);
      debugLog("Updated prefs");

      // Set the migration flag
      await prefs.setBool("migrated_buses", true);
    } catch (e) {
      debugLog("Error migrating buses: $e");
    }
  }

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
