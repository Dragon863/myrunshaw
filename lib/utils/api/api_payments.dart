import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:runshaw/utils/models/exceptions.dart';
import 'package:runshaw/utils/models/transaction.dart';
import 'package:runshaw/utils/widgets/runshaw_pay_widget_sync.dart';
import 'api_core.dart';

mixin ApiPayments on ApiCore {
  // Custom retry logic to replace the old RetryClient
  // which lets us easily use our clean `apiGet` method
  Future<http.Response> _apiGetWithRetry(String endpoint,
      {int retries = 2}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await apiGet(endpoint);
        if (response.statusCode == 200 || i == retries - 1) {
          return response;
        }
      } catch (e) {
        if (i == retries - 1) rethrow;
      }
    }
    return await apiGet(endpoint); // Fallback
  }

  Future<String?> getRunshawPayBalance() async {
    try {
      final response = await _apiGetWithRetry('/api/payments/balance');

      if (response.statusCode != 200) {
        await RunshawPayWidgetSync.saveWidgetPayload(
            balance: null, status: 'error');
        return null;
      } else {
        final String balance =
            jsonDecode(utf8.decode(response.bodyBytes))["balance"];
        await RunshawPayWidgetSync.saveWidgetPayload(
            balance: balance, status: 'ok');
        return balance;
      }
    } catch (e) {
      await RunshawPayWidgetSync.saveWidgetPayload(
          balance: null, status: 'error');
      return null;
    }
  }

  Future<List<Transaction>> getRunshawPayTransactions() async {
    final response = await _apiGetWithRetry('/api/payments/transactions');

    if (response.statusCode != 200) {
      // Uses the human parser from api_core to get the detail/message
      throw RunshawPayException(humanResponse(response.body));
    }

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

  Future<String> getRunshawPayTopupUrl() async {
    final response = await apiGet('/api/payments/deeplink');

    if (response.statusCode != 200) {
      throw RunshawPayException(humanResponse(response.body));
    }

    return jsonDecode(utf8.decode(response.bodyBytes))["deeplink"];
  }
}
