import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';

class FeatureFlagWidget extends StatefulWidget {
  final String flagName;
  final Widget child;

  const FeatureFlagWidget({
    super.key,
    required this.flagName,
    required this.child,
  });

  @override
  State<FeatureFlagWidget> createState() => _FeatureFlagWidgetState();
}

class _FeatureFlagWidgetState extends State<FeatureFlagWidget> {
  late final Future<bool> _flagFuture;

  @override
  void initState() {
    super.initState();
    _flagFuture = _loadFlag();
  }

  Future<bool> _loadFlag() async {
    // We use appwrite for feature flags as posthog doesn't treat anonymous users
    final api = context.read<BaseAPI>();
    final Client client = api.client;
    final databases = TablesDB(client);

    final appwrite_models.Row row = await databases.getRow(
      databaseId: MyRunshawConfig.featureFlagsDbId,
      tableId: MyRunshawConfig.featureFlagsCollectionId,
      rowId: widget.flagName,
    );
    if (row.data["state"] == true) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _flagFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (snapshot.hasError) {
            debugLog(
              "Error loading feature flag ${widget.flagName}: ${snapshot.error}",
              level: 3,
            );
          }
          return Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: widget.child,
          );
        } else {
          debugLog(
            "Feature flag ${widget.flagName} is ${snapshot.data == true ? "enabled" : "disabled"}",
          );
          return snapshot.data == true ? widget.child : const SizedBox.shrink();
        }
      },
    );
  }
}
