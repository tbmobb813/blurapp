import 'package:flutter/material.dart';

import '../../services/image_picker_service.dart';
import '../../settings/privacy_settings_screen.dart';
import '../../theme/app_icons.dart';
import '../editor/editor_screen.dart';

/// Home screen where users select photos to edit
/// Provides gallery and camera options with privacy-first approach
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePickerService _pickerService = ImagePickerService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BlurApp'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildPickerButtons(),
          const SizedBox(height: 32),
          _buildPrivacyNote(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(
          AppIcons.blur,
          size: 80,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Select a Photo to Blur',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose from gallery or take a new photo',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPickerButtons() {
    return Column(
      children: [
        _buildPickerButton(
          icon: Icons.photo_library,
          label: 'Choose from Gallery',
          onPressed: () => _pickFromGallery(),
        ),
        const SizedBox(height: 16),
        _buildPickerButton(
          icon: Icons.camera_alt,
          label: 'Take Photo',
          onPressed: () => _pickFromCamera(),
        ),
      ],
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All editing happens offline on your device. No photos are uploaded.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final imageData = await _pickerService.pickFromGallery();

      if (imageData != null) {
        _navigateToEditor();
      } else {
        if (mounted) {
          ImagePickerService.showPermissionDialog(context, 'Gallery');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isLoading = true);

    try {
      final imageData = await _pickerService.pickFromCamera();

      if (imageData != null) {
        _navigateToEditor();
      } else {
        if (mounted) {
          ImagePickerService.showPermissionDialog(context, 'Camera');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditorScreen(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }
}
