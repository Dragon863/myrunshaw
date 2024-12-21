import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // Method to copy email to clipboard and show a SnackBar
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                  'Privacy Policy for My Runshaw App',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Effective Date: 14th December 2024',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Introduction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Welcome to the My Runshaw App, designed to provide timetable sharing and bus updates for Runshaw College students. In the My Runshaw team, your privacy is of paramount importance to us. This Privacy Policy outlines the types of information we collect, how we use it, and the steps we take to ensure your data is handled securely.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data We Collect',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  '• Email Address: Collected during account creation and used for communication purposes.\n'
                  '• Full Name: Used to personalize your experience within the app and to display to friends added by the User within the app\n'
                  '• Password Hash: Securely stored to protect your account credentials.\n'
                  '• Device Information: Collected to provide a personalized experience and to improve the app\'s features and functionality.\n'
                  '• Student ID: Used as a unique identifier to distinguish users\n',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How We Use Your Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We use the information you provide to:\n'
                  '• Create and manage your account.\n'
                  '• Send notifications through OneSignal, a GDPR-compliant service.\n'
                  '• Enhance your experience by improving our app\'s features and functionality.\n'
                  '• Provide support and respond to your inquiries.\n',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Legal Basis for Processing',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Our processing of your personal data is based on:\n'
                  '• Your Consent: By creating an account or installing the app, you consent to the collection and use of your data as outlined in this policy.\n'
                  '• Legitimate Interests: We have a legitimate interest in processing your data to operate and maintain the app effectively.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Security',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We take data security seriously and employ a range of measures to protect your personal information, including:\n'
                  '• Encryption: Your data is encrypted both at rest (using AES-256 encryption) and during transit (via TLS encryption).\n'
                  '• Access Control: Data access is strictly controlled and managed through access policies at the database level.\n'
                  '• Secure Transmission: All data is transmitted using HTTPS, ensuring end-to-end encryption.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Rights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'You have the right to access, correct, or delete your data at any time. Please contact us at ',
                  style: TextStyle(fontSize: 16),
                ),
                InkWell(
                  child: const Text(
                    'hi@danieldb.uk',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  onTap: () {
                    _copyToClipboard(context, 'hi@danieldb.uk');
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Retention',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We retain your personal data for as long as your account remains active or as necessary to provide our services. If you choose to deactivate your account, we will delete your data in accordance with applicable legal requirements.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Changes to This Policy',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We may revise this Privacy Policy from time to time. Any significant changes will be communicated to you through the app or via the email address associated with your account. Your continued use of the app following these changes indicates your acceptance of the updated policy.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contact Us',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'If you have any questions, concerns, or requests related to this Privacy Policy or your personal data, please contact us at ',
                  style: TextStyle(fontSize: 16),
                ),
                InkWell(
                  child: const Text(
                    'hi@danieldb.uk',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  onTap: () {
                    _copyToClipboard(context, 'hi@danieldb.uk');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
