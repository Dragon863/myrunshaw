import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

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
        title: const Text('Terms of Use'),
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
                  'Terms of Use for the My Runshaw application',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Effective Date: 20th December 2024',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Introduction',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Welcome to the My Runshaw App. By using this app, you agree to comply with and be bound by these Terms of Use. If you do not agree with these terms, please do not use the app.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Eligibility',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'This app is intended for use by current Runshaw College students. By creating an account, you confirm that you meet this requirement.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'User-Generated Content',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Users may provide full names and profile pictures as part of their account information. By submitting this content, you represent and warrant that:\n'
                  '1. You own or have the necessary permissions to use and share this content.\n'
                  '2. The content is accurate and does not violate any laws or third-party rights.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reporting Content',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Wrap(
                  children: [
                    const Text(
                      'If you encounter content that violates these Terms of Use, you may report it by emailing us at ',
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
                const SizedBox(height: 20),
                const Text(
                  'Acceptable Use',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'You agree not to:\n'
                  '• Use the app for any unlawful or prohibited activities.\n'
                  '• Upload or share any content that is abusive, defamatory, obscene, or otherwise objectionable.\n'
                  '• Attempt to gain unauthorized access to the app or its systems.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Responsibilities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Termination',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We reserve the right to suspend or terminate your access to the app at any time, without prior notice, for any violation of these Terms of Use or for other reasons deemed necessary.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Changes to These Terms',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'We may update these Terms of Use from time to time. Any significant changes will be communicated to you through the app or via email. Continued use of the app after changes are made constitutes acceptance of the updated terms.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contact Us',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Wrap(
                  children: [
                    const Text(
                      'If you have any questions about these Terms of Use, please contact us at ',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
