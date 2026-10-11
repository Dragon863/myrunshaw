import 'package:material_ui/material_ui.dart';

class NoNetworkPage extends StatelessWidget {
  const NoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.wifi_off,
                size: 120.0, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 20.0),
            const Text(
              'No Internet!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Please check your connection and try again',
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
