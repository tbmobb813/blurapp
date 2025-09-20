import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service responsible for picking images from gallery or camera
/// Follows privacy-first principles with no network access
class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery with proper permission handling
  Future<Uint8List?> pickFromGallery() async {
    try {
      // Check storage permission
      final permission = await _checkPermission(Permission.photos);
      if (!permission) {
        debugPrint('Gallery permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image == null) return null;

      return await image.readAsBytes();
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera with proper permission handling
  Future<Uint8List?> pickFromCamera() async {
    try {
      // Check camera permission
      final permission = await _checkPermission(Permission.camera);
      if (!permission) {
        debugPrint('Camera permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image == null) return null;

      return await image.readAsBytes();
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Check and request permission if needed
  Future<bool> _checkPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }

    // Permanently denied or restricted
    return false;
  }

  /// Show permission dialog to help user understand why we need access
  static void showPermissionDialog(
      BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'BlurApp needs $permissionType access to select and edit your photos. '
          'All editing happens offline on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
