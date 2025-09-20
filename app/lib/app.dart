import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/editor/editor_screen.dart';

void main() {
  runApp(const BlurApp());
}

class BlurApp extends StatelessWidget {
  const BlurApp({Key? key}) : super(key: key);

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
