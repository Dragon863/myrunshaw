import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/main_helpers.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SliderMenuItem extends StatelessWidget {
  final AppDestination destination;
  final AppDestination currentDest;
  final String notificationStr;
  final Function(AppDestination)? onTap;

  const SliderMenuItem({
    super.key,
    required this.destination,
    required this.currentDest,
    required this.notificationStr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = destination == currentDest;

    return Material(
      color: isSelected
          ? context.read<ThemeProvider>().isLightMode
              ? const Color.fromARGB(255, 255, 209, 209)
              : Theme.of(context).colorScheme.surface
          : Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Row(
          children: [
            Text(
              destination.getTitle(notificationStr),
              style: TextStyle(
                color: context.read<ThemeProvider>().isLightMode
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            if (destination.isBeta)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  '(beta)',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
        leading: Icon(
          isSelected ? destination.activeIcon : destination.inactiveIcon,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: () => onTap?.call(destination),
      ),
    );
  }
}
