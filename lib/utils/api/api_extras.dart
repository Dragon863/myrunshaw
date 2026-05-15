import 'dart:convert';

import 'package:runshaw/utils/api/api_core.dart';
import 'package:runshaw/utils/config.dart';

mixin ApiExtras on ApiCore {
  Future<void> submitWifiSurveyResults(Map<String, Object> props) async {
    final String jwtToken = await getJwt();

    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/surveys/wifi-speed-test/results'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(props),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to submit wifi survey results: ${response.body}');
    }
  }
}
