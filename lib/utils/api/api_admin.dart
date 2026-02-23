import 'dart:convert';
import 'package:runshaw/utils/config.dart';
import 'api_core.dart';

mixin ApiAdmin on ApiCore {
  Future<bool> isAdmin() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/admin/is_admin'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      return false;
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["is_admin"];
    }
  }

  Future<Map> getUserInfoTechnician(String userID) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/admin/user/$userID'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw "Error fetching user info";
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
  }
}
