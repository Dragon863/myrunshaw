import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';

Future<void> syncFromUrl(String icalUrl, BuildContext context) async {
  final BaseAPI api = context.read<BaseAPI>();
  await api.associateTimetableUrl(icalUrl);
  await api.refreshUser();
}
