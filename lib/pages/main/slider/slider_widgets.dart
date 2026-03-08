import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SliderMenuItem extends StatelessWidget {
  final String title;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final Function(String, int)? onTap;
  final bool? isBeta;
  final int index;
  final int currentIndex;

  const SliderMenuItem({super.key, 
    required this.title,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.onTap,
    required this.isBeta,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: index == currentIndex
            ? context.read<ThemeProvider>().isLightMode
                ? const Color.fromARGB(255, 255, 209, 209)
                : Theme.of(context).colorScheme.surface
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.read<ThemeProvider>().isLightMode
                    ? Colors.black
                    : Colors.white,
              ),
            ),
            if (isBeta == true)
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
          index == currentIndex ? activeIcon : inactiveIcon,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: () => onTap?.call(title, index),
      ),
    );
  }
}

class Menu {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String title;
  final bool? isBeta;

  Menu(this.inactiveIcon, this.activeIcon, this.title, {this.isBeta = false});
}
