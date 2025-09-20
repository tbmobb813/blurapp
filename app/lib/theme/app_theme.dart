import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1A1A1A),
    scaffoldBackgroundColor: const Color(0xFF181818),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4F8EFF),
      secondary: Color(0xFF00C6AE),
      background: Color(0xFF181818),
      surface: Color(0xFF232323),
      error: Color(0xFFFF4F4F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181818),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      headline1: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      bodyText1: TextStyle(fontSize: 16, color: Colors.white70),
      bodyText2: TextStyle(fontSize: 14, color: Colors.white60),
      button: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF4F8EFF), size: 24),
    toolbarTheme: const ToolbarTheme(
      backgroundColor: Color(0xFF232323),
      height: 56,
      iconSize: 28,
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF4F8EFF),
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
