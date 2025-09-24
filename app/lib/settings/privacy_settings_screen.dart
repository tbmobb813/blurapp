import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';
import '../services/image_saver_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool crashReportingEnabled = false;
  bool _clearingCache = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: theme.colorScheme.surface),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrivacySection(theme),
            const SizedBox(height: 32),
            _buildCacheSection(theme),
            const SizedBox(height: 32),
            _buildAboutSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy First',
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: withOpacitySafe(theme.colorScheme.surface, 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: withOpacitySafe(theme.colorScheme.outline, 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All editing happens offline on your device',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '• No photos are uploaded to any server\n'
                '• No personal data is collected\n'
                '• No internet connection required for editing\n'
                '• No account creation or sign-in needed',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Anonymous crash reports'),
          value: crashReportingEnabled,
          onChanged: (val) {
            setState(() => crashReportingEnabled = val);
          },
          subtitle: const Text('Help improve app stability. No personal or image data is ever sent.'),
          secondary: const Icon(Icons.bug_report_outlined),
        ),
      ],
    );
  }

  Widget _buildCacheSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Management',
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined),
          title: const Text('Clear temporary cache'),
          subtitle: const Text('Remove temporary files created during editing'),
          trailing: _clearingCache
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.chevron_right),
          onTap: _clearingCache ? null : _clearCache,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About storage'),
          subtitle: const Text('Saved images are stored in your Documents folder'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showStorageInfo(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About BlurApp',
          style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Version'),
          subtitle: Text('0.0.1+1'),
          trailing: Icon(Icons.chevron_right),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Privacy Policy'),
          subtitle: const Text('Learn about our privacy practices'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPrivacyPolicy(),
        ),
      ],
    );
  }

  Future<void> _clearCache() async {
    setState(() => _clearingCache = true);

    try {
      await ImageSaverService.clearCache();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache cleared successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _clearingCache = false);
      }
    }
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Information'),
        content: const Text(
          'BlurApp stores your edited images in your device\'s Documents folder. '
          'You can access these files through your file manager.\n\n'
          'Temporary files used during editing are automatically cleaned up, '
          'but you can manually clear the cache if needed.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy-First Photo Editing\n\n'
            'BlurApp is designed with your privacy as the top priority:\n\n'
            '• All image processing happens locally on your device\n'
            '• No photos are ever uploaded to any server\n'
            '• No user accounts or personal information required\n'
            '• No tracking or analytics data collection\n'
            '• Optional anonymous crash reporting only (if enabled)\n'
            '• Open source and transparent development\n\n'
            'Your photos remain completely private and under your control.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }
}
