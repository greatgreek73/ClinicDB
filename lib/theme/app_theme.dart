import 'package:flutter/material.dart';

class AppTheme {
  // --- COMMON COLORS ---
  static const Color primaryColor = Color(0xFF0F5BF1); // Main blue
  static const Color secondaryColor = Color(0xFF003479); // Dark blue
  static const Color accentColor = Color(0xFF00A3FF);   // Light blue accent
  static const Color errorColor = Color(0xFFE53935);     // Standard red for errors
  static const Color successColor = Color(0xFF43A047);   // Standard green for success

  // --- LIGHT THEME SPECIFIC COLORS ---
  static const Color lightBackgroundColor = Colors.white;
  static const Color lightCardColor = Color(0xFFF1F1F1);
  static const Color lightPrimaryTextColor = Color(0xFF151515); // For text on light backgrounds
  static const Color lightSecondaryTextColor = Color(0xFF555555); // For less prominent text on light backgrounds
  static const Color lightBorderColor = Color(0xFFD0D0D0); // Border color for light theme
  static Color lightShadowColor = Colors.black.withOpacity(0.1);

  // --- DARK THEME SPECIFIC COLORS ---
  static const Color darkBackgroundColor = Color(0xFF202020);
  static const Color darkCardColor = Color(0xFF2A2A2A); 
  static const Color darkSurfaceColor = Color(0xFF2A2A2A); 
  static const Color darkBorderColor = Color(0xFF484848); // #484848
  static const Color darkPrimaryTextColor = Colors.white; // For text on dark backgrounds
  static const Color darkSecondaryTextColor = Colors.white70; // For less prominent text
  static Color darkShadowColor = Colors.black.withOpacity(0.5); // More pronounced shadow for depth

  // --- GRADIENTS ---
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

  // --- RADII ---
  static const double smallRadius = 6.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 20.0;
  static const double extraLargeRadius = 30.0;

  // --- SHADOWS (Examples, can be theme-specific) ---
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: lightShadowColor,
      spreadRadius: 1,
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: darkShadowColor, // Using the dark theme shadow color
      spreadRadius: 1,
      blurRadius: 8, // Slightly adjusted blur
      offset: Offset(0, 4), // Slightly adjusted offset
    ),
  ];

  static List<BoxShadow> elevatedShadow = [ // Could be made theme-specific if needed
    BoxShadow(
      color: Colors.black.withOpacity(0.2), // Generic, works on both
      spreadRadius: 1,
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];

  // --- PADDINGS ---
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // --- DARK THEME DATA (Default Theme) ---
  static ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    fontFamily: 'Roboto', 
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor, 
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      error: errorColor,
      onPrimary: Colors.white, // Text/icons on primaryColor
      onSecondary: Colors.white, // Text/icons on accentColor
      onSurface: darkPrimaryTextColor, // Text/icons on card/surface colors
      onBackground: darkPrimaryTextColor, // Text/icons on background colors
      onError: Colors.white, // Text/icons on errorColor
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor, 
      elevation: 0, 
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkPrimaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: darkPrimaryTextColor),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkPrimaryTextColor),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkPrimaryTextColor),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkPrimaryTextColor),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkPrimaryTextColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkPrimaryTextColor),
      bodyLarge: TextStyle(fontSize: 16, color: darkPrimaryTextColor),
      bodyMedium: TextStyle(fontSize: 14, color: darkSecondaryTextColor), // Use secondary for less emphasis
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkPrimaryTextColor), // For buttons
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2, // Subtle elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: 3, // Adjusted elevation
      shadowColor: darkShadowColor.withOpacity(0.3), // Adjusted shadow
      margin: EdgeInsets.all(smallPadding), // Consistent padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        side: BorderSide(color: darkBorderColor, width: 1.0),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkCardColor,
      titleTextStyle: TextStyle(color: darkPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: darkSecondaryTextColor, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        side: BorderSide(color: darkBorderColor, width: 1.0),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBackgroundColor.withOpacity(0.5), // Slightly different from card for depth
      hintStyle: TextStyle(color: darkSecondaryTextColor.withOpacity(0.7)),
      labelStyle: TextStyle(color: primaryColor), // Accent color for labels
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: darkBorderColor.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: errorColor, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: defaultPadding, vertical: smallPadding),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor, // Use accent for text buttons
        textStyle: TextStyle(fontWeight: FontWeight.w600)
      )
    ),
    iconTheme: IconThemeData(color: darkSecondaryTextColor), // Default icon color
    dividerTheme: DividerThemeData(color: darkBorderColor.withOpacity(0.5), thickness: 1),
  );

  // --- LIGHT THEME DATA ---
  static ThemeData lightThemeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackgroundColor,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightCardColor,
      background: lightBackgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: lightPrimaryTextColor, 
      onSurface: lightPrimaryTextColor,
      onBackground: lightPrimaryTextColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme( // Original settings from problem description
      backgroundColor: Colors.black, 
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: lightPrimaryTextColor),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightPrimaryTextColor),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightPrimaryTextColor),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightPrimaryTextColor),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: lightPrimaryTextColor),
      bodyLarge: TextStyle(fontSize: 16, color: lightPrimaryTextColor),
      bodyMedium: TextStyle(fontSize: 14, color: lightSecondaryTextColor),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), // For buttons
    ),
    elevatedButtonTheme: ElevatedButtonThemeData( // Original settings
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(smallRadius)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardTheme( // Original settings
      color: lightCardColor,
      elevation: 5,
      shadowColor: lightShadowColor,
      margin: EdgeInsets.all(smallPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: lightBackgroundColor,
      titleTextStyle: TextStyle(color: lightPrimaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: lightSecondaryTextColor, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)),
    ),
     inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightBackgroundColor,
      hintStyle: TextStyle(color: lightSecondaryTextColor.withOpacity(0.7)),
      labelStyle: TextStyle(color: primaryColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: lightBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(smallRadius),
        borderSide: BorderSide(color: errorColor, width: 2.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: defaultPadding, vertical: smallPadding),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor, // Primary color for text buttons in light theme
        textStyle: TextStyle(fontWeight: FontWeight.w600)
      )
    ),
    iconTheme: IconThemeData(color: lightSecondaryTextColor),
    dividerTheme: DividerThemeData(color: lightBorderColor, thickness: 1),
  );

  // --- STATIC STYLES (Review and update for dark theme compatibility or provide variants) ---

  // Action Button Style - Should work on dark theme due to explicit colors
  static ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: largePadding, vertical: defaultPadding), // Adjusted padding
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(mediumRadius)), // Adjusted radius
    elevation: 3,
  );

  // Info Card Decoration - Dark Theme Variant
  static BoxDecoration infoCardDecorationDark = BoxDecoration(
    color: darkCardColor,
    borderRadius: BorderRadius.circular(largeRadius),
    boxShadow: cardShadowDark,
    border: Border.all(color: darkBorderColor, width: 1.0),
  );
  
  // Info Card Decoration - Light Theme Variant (Original)
  static BoxDecoration infoCardDecorationLight = BoxDecoration(
    color: lightBackgroundColor, // Was Colors.white
    borderRadius: BorderRadius.circular(largeRadius),
    boxShadow: cardShadowLight, // Original cardShadow
  );


  // Nav Panel Decoration - Assumed to be dark, should work well
  static BoxDecoration navPanelDecoration = BoxDecoration(
    color: darkCardColor.withOpacity(0.9), // Using darkCardColor for consistency
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(extraLargeRadius),
      bottomLeft: Radius.circular(extraLargeRadius),
    ),
    boxShadow: elevatedShadow, // Generic shadow
  );
}
