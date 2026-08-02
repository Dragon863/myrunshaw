import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/main_helpers.dart';
import 'package:runshaw/pages/main/slider/slider_widgets.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SliderView extends StatefulWidget {
  final Function(AppDestination)? onItemClick;
  final AppDestination currentDest;
  final String notification;
  final bool showNotifs;

  const SliderView({
    super.key,
    this.onItemClick,
    required this.currentDest,
    required this.notification,
    required this.showNotifs,
  });

  @override
  State<SliderView> createState() => _SliderViewState();
}

class _SliderViewState extends State<SliderView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: .3)),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(
              color: context.read<ThemeProvider>().isLightMode
                  ? Colors.black
                  : Colors.white,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const ScrollPhysics(),
                  children: <Widget>[
                    CircleAvatar(
                      radius: 72,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      child: const CircleAvatar(
                        radius: 70,
                        backgroundImage:
                            AssetImage('assets/img/logo-muted.png'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...AppDestination.values.map((destination) {
                      return SliderMenuItem(
                        destination: destination,
                        currentDest: widget.currentDest,
                        notificationStr: widget.notification,
                        onTap: widget.onItemClick,
                      );
                    }),
                  ],
                ),
              ),
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () async {
                    await logOut(context);
                  },
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  leading: const Icon(Icons.logout, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
