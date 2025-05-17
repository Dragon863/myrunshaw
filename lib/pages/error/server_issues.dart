import 'package:flutter/material.dart';

class NoServersPage extends StatelessWidget {
  const NoServersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 120.0, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 20.0),
            const Text(
              'Oops!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Sorry, it looks like we\'re having some server issues or are down for maintenance. Please try again later!',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/splash');
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
