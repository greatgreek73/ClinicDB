import 'package:flutter/material.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
        useMaterial3: true,
        canvasColor: const Color(0xfff1f4f8),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(color: Colors.white),
        disabledColor: Colors.grey,
        cardColor: Colors.white,
        // hoverColor: Colors.grey.shade300,
        brightness: ThemeData.light().brightness);
  }
}
