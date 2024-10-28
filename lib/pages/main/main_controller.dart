import 'package:flutter/material.dart';
import '../../utils/api.dart';
import 'package:provider/provider.dart';

Future<void> logOut(BuildContext context) async {
  final api = context.read<BaseAPI>();
  await api.signOut();
  print("Signed out");
  Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
}
