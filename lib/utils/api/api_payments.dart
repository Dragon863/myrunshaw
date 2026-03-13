import 'dart:convert';
import 'package:http/retry.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/models/exceptions.dart';
import 'package:runshaw/utils/models/transaction.dart';
import 'api_core.dart';

mixin ApiPayments on ApiCore {
  Future<String?> getRunshawPayBalance() async {
    final String jwtToken = await getJwt();
    final response = await RetryClient(httpClient, retries: 2).get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/balance'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      return null;
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["balance"];
    }
  }

  Future<List<Transaction>> getRunshawPayTransactions() async {
    final String jwtToken = await getJwt();
    // Retry the request up to 2 times if it fails, to handle timeouts which are common on the server end
    final response = await RetryClient(httpClient, retries: 2).get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/transactions'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw RunshawPayException(jsonDecode(response.body)["detail"]);
    } else {
      List<Transaction> toReturn = [];
      final List allTransactions = jsonDecode(utf8.decode(response.bodyBytes));

      for (final transaction in allTransactions) {
        if (transaction["amount"] == "Err" || transaction["balance"] == "Err") {
          // API response for failure parsing - just skip it
          continue;
        }
        toReturn.add(
          Transaction(
            transaction["date"],
            transaction["details"],
            transaction["action"],
            transaction["amount"],
            transaction["balance"],
          ),
        );
      }

      return toReturn;
    }
  }

  Future<String> getRunshawPayTopupUrl() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/deeplink'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw RunshawPayException(jsonDecode(response.body)["detail"]);
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["deeplink"];
    }
  }
}
