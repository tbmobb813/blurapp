import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool crashReportingEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BlurApp is privacy-first. All editing is offline. No data is sent to any server.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Send anonymous crash reports'),
              value: crashReportingEnabled,
              onChanged: (val) {
                setState(() => crashReportingEnabled = val);
              },
              subtitle: const Text('Helps improve app stability. No personal or image data is ever sent.'),
            ),
          ],
        ),
      ),
    );
  }
}
