import 'package:flutter/material.dart';

import 'features/home/home_screen_mvp.dart';
import 'theme/app_theme.dart';

/// Main App for Blur App MVP
///
/// Sprint 0-1 focused implementation:
/// - Privacy-first image blur tool
/// - Offline processing only
/// - Clean Material 3 design
class BlurApp extends StatelessWidget {
  const BlurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blur App',
      theme: AppTheme.darkTheme,
      home: const HomeScreenMVP(),
      debugShowCheckedModeBanner: false,
    );
  }
}
