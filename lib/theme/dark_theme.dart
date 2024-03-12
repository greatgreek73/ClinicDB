import 'package:flutter/material.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
        useMaterial3: true,
        canvasColor: const Color(0xff1d2428),
        primaryColor: Colors.deepPurple,
        hoverColor: Colors.deepPurple.shade400,
        scaffoldBackgroundColor: const Color(0xff14181b),
        primarySwatch: Colors.deepPurple,
        textTheme: TextTheme(
          bodyMedium: ThemeData.dark().textTheme.bodyMedium?.copyWith(
                color: Colors.deepPurple,
              ),
        ),
        brightness: ThemeData.dark().brightness);
  }
}
