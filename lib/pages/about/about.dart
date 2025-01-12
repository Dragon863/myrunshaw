import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Method to copy email to clipboard and show a SnackBar
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details about My Runshaw app',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Last Updated: 6th January 2025',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Introduction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Welcome to the My Runshaw App, designed to provide timetable sharing and bus updates for Runshaw College students. Please note that this app is NOT affiliated with Runshaw College, and is a personal project by the developer. The app is designed to be a helpful tool for students to share their timetables and bus information with friends.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Source Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Wrap(
                  children: [
                    const Text(
                      'The source code for this app is available on GitHub at the following link: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    InkWell(
                      child: const Text(
                        'https://github.com/Dragon863/myrunshaw/',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      onTap: () {
                        _copyToClipboard(
                            context, 'https://github.com/Dragon863/myrunshaw/');
                      },
                    ),
                  ],
                ),
                const Text(
                  "All source code is licensed under the MIT License, and contributions are welcome!",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Copyright',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This app is not affiliated with Runshaw College, and is not intended for commercial use. All rights to Runshaw College for the map graphic used in the "Buses" page. All other content is the property of the developer.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
