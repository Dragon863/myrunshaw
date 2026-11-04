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
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is! Map || decoded['balance'] == null) {
          throw const FormatException('Balance response is malformed');
        }
        final String balance = decoded['balance'].toString();
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

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    final toReturn = <Transaction>[];
    for (final transaction in decoded.whereType<Map>()) {
      final typed =
          Transaction.fromJson(Map<String, dynamic>.from(transaction));
      if (typed.amount == "Err" || typed.balance == "Err") {
        // API response for failure parsing - just skip it
        continue;
      }
      toReturn.add(typed);
    }

    return toReturn;
  }

  Future<String> getRunshawPayTopupUrl() async {
    final response = await apiGet('/api/payments/deeplink');

    if (response.statusCode != 200) {
      throw RunshawPayException(humanResponse(response.body));
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map && decoded['deeplink'] != null) {
      return decoded['deeplink'].toString();
    }
    throw RunshawPayException('The payment link response was malformed.');
  }
}
