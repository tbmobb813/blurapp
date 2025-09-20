import 'package:flutter/material.dart';

import 'features/editor/editor_screen.dart';
import 'theme/app_theme.dart';

class BlurApp extends StatelessWidget {
  const BlurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlurApp',
      theme: AppTheme.darkTheme,
      home: const EditorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
