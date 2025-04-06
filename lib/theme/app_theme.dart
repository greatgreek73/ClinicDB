import 'package:flutter/material.dart';

class AppTheme {
  // Основные цвета приложения
  static const Color primaryColor = Color(0xFF0F5BF1); // Основной синий цвет
  static const Color secondaryColor = Color(0xFF003479); // Темно-синий
  static const Color accentColor = Color(0xFF00A3FF); // Светло-синий акцент
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF1F1F1);
  static const Color darkTextColor = Color(0xFF151515);
  static const Color lightTextColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Скругления
  static const double smallRadius = 6.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 20.0;
  static const double extraLargeRadius = 30.0;

  // Тени
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      spreadRadius: 1,
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      spreadRadius: 1,
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];

  // Отступы
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Основная тема приложения
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Roboto', // Можно заменить на другой шрифт

    // AppBar тема
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: lightTextColor),
    ),

    // Тема текста
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.bold, 
        color: darkTextColor
      ),
      headlineMedium: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.bold, 
        color: darkTextColor
      ),
      headlineSmall: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.bold, 
        color: darkTextColor
      ),
      titleLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        color: darkTextColor
      ),
      titleMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        color: darkTextColor
      ),
      bodyLarge: TextStyle(
        fontSize: 16, 
        color: darkTextColor
      ),
      bodyMedium: TextStyle(
        fontSize: 14, 
        color: darkTextColor
      ),
    ),

    // Тема кнопок
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Тема карточек
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 5,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
    ),
  );

  // Стиль для главных кнопок действий
  static ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 3,
  );

  // Стиль для карточек информации
  static BoxDecoration infoCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(largeRadius),
    boxShadow: cardShadow,
  );

  // Стиль для панели навигации
  static BoxDecoration navPanelDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.8),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(extraLargeRadius),
      bottomLeft: Radius.circular(extraLargeRadius),
    ),
  );
}
