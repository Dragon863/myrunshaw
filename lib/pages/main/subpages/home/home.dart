import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
