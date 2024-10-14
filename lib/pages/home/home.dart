import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/main.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(
        title: "Home",
        actions: [
          IconButton(
              onPressed: () async {
                final api = context.read<AuthAPI>();
                await api.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const BaseApp(),
                  ),
                );
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile layout
                return Image.asset(
                  "assets/img/busesmap.png",
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              } else {
                // Desktop layout
                return Image.asset(
                  "assets/img/busesmap.png",
                );
              }
            },
          ),
          const Center(
            child: Text(
              'Logged In! :D',
            ),
          ),
        ],
      ),
    );
  }
}
