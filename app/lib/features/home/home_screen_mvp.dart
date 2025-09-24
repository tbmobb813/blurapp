import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../editor/editor_screen_mvp.dart';
import '../../settings/privacy_settings_screen.dart';

/// MVP Home Screen for Sprint 1
///
/// Core features:
/// - Pick image from gallery or camera
/// - Navigate to editor
/// - Simple privacy-focused UI
class HomeScreenMVP extends StatefulWidget {
  const HomeScreenMVP({super.key});

  @override
  State<HomeScreenMVP> createState() => _HomeScreenMVPState();
}

class _HomeScreenMVPState extends State<HomeScreenMVP> {
  static const String _tag = 'HomeScreenMVP';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditorScreenMVP(
                imageBytes: imageBytes,
                sourcePath: image.path,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('$_tag: Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacySettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App logo/title
              const Icon(Icons.blur_on, size: 80, color: Colors.white),
              const SizedBox(height: 16),

              const Text(
                'BlurApp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select a Photo to Blur',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 48),

              // Pick from gallery button
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),

              const SizedBox(height: 16),

              // Take photo button
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _pickImage(ImageSource.camera),
              ),

              const SizedBox(height: 48),

              // Privacy note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Privacy First',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• All processing happens on your device\n'
                      '• No photos are uploaded to the internet\n'
                      '• No accounts or tracking required',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
