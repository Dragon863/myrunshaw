import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class FeatureFlagWidget extends StatelessWidget {
  final String flagName;
  final Widget child;

  const FeatureFlagWidget({
    super.key,
    required this.flagName,
    required this.child,
  });

  Future<bool> isFeatureEnabled() async {
    return await Posthog().isFeatureEnabled(flagName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isFeatureEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return const SizedBox.shrink();
        } else {
          return snapshot.data == true ? child : const SizedBox.shrink();
        }
      },
    );
  }
}
