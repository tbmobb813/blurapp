import 'package:flutter/material.dart';
import 'dart:io';

import 'app.dart';

// Import real plugin packages so we can wire them into the runtime bridges.
// These imports are safe in test environments; plugin methods may throw
// MissingPluginException when invoked on the VM, so we only assign the
// bridge objects and avoid calling plugin methods here.
import 'package:gal/gal.dart' as gal;
import 'package:path_provider/path_provider.dart' as path_provider;

import 'services/gallery_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire the real plugin bridges. Assignments are safe; any runtime calls to
  // plugin methods should still be wrapped in try/catch by the provider.
  try {
    GalBridge.gal = gal.Gal;
  } catch (e) {
    // ignore - Gal not available in this environment
  }

  try {
    // Provide a small wrapper object for the path_provider top-level APIs
    PathProviderBridge.pp = _PathProviderImpl();
  } catch (e) {
    // ignore - path_provider not available in this environment
  }

  runApp(const BlurApp());
}

class _PathProviderImpl {
  Future<Directory> getTemporaryDirectory() => path_provider.getTemporaryDirectory();
  Future<Directory> getApplicationDocumentsDirectory() => path_provider.getApplicationDocumentsDirectory();
}
