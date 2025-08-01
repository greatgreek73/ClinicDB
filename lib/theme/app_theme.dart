import 'package:flutter/material.dart';
import '../design_system/design_system_screen.dart' show DesignTokens;

class AppTheme {
  // Глобальная светлая неоморфная тема, синхронизированная с DesignTokens
  static ThemeData themeData = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    // Базовые цвета
    scaffoldBackgroundColor: DesignTokens.background,
    primaryColor: DesignTokens.accentPrimary,
    cardColor: DesignTokens.surface,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,

    // Типографика
    textTheme: const TextTheme(
      headlineLarge: DesignTokens.h1,
      headlineMedium: DesignTokens.h2,
      headlineSmall: DesignTokens.h3,
      titleLarge: DesignTokens.h4,
      bodyLarge: DesignTokens.body,
      bodyMedium: DesignTokens.small,
    ),

    // AppBar в светлом стиле
    appBarTheme: const AppBarTheme(
      backgroundColor: DesignTokens.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: DesignTokens.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: DesignTokens.textPrimary),
    ),

    // Карточки по умолчанию — светлые, без «материал» тени (тени рисуются нашими нео-компонентами)
    cardTheme: CardTheme(
      color: DesignTokens.surface, // светлый фон карточек
      elevation: 0, // убираем материал-тени, используем нео-тени в NeoCard
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cornerRadiusCard),
      ),
    ),

    // Кнопки — по умолчанию светлые, первичная — градиент задаётся нашим NeoButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.accentPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cornerRadiusButton),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Цветовая схема (минимальная синхронизация)
    colorScheme: ColorScheme.light(
      primary: DesignTokens.accentPrimary,
      secondary: DesignTokens.accentSecondary,
      surface: DesignTokens.surface,
      error: DesignTokens.error,
      onPrimary: Colors.white,
      onSurface: DesignTokens.textPrimary,
    ),
  );
}
