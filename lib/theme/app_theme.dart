import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class AppTheme {
  // Primary colors
  static const Color primaryLight = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF818CF8);
  
  // Secondary colors
  static const Color secondaryLight = Color(0xFFEC4899); // Pink
  static const Color secondaryDark = Color(0xFFF472B6);
  
  // Accent colors
  static const Color accentLight = Color(0xFF10B981); // Emerald
  static const Color accentDark = Color(0xFF34D399);
  
  // Surface colors
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceDark = Color(0xFF1F2937);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111827);
  
  // Error colors
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  
  // Neutral colors
  static const Color neutralLight = Color(0xFF64748B);
  static const Color neutralDark = Color(0xFF94A3B8);

  // Get theme based on brightness
  static ThemeData getTheme(Brightness brightness, Color primaryColor) {
    final isDark = brightness == Brightness.dark;
    
    // Override system UI elements
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? backgroundDark : backgroundLight,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // Create color scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: isDark ? primaryDark : primaryColor,
        onPrimary: Colors.white,
        secondary: isDark ? secondaryDark : secondaryLight,
        onSecondary: Colors.white,
        tertiary: isDark ? accentDark : accentLight,
        onTertiary: Colors.white,
        error: isDark ? errorDark : errorLight,
        onError: Colors.white,
        background: isDark ? backgroundDark : backgroundLight,
        onBackground: isDark ? Colors.white : Colors.black,
        surface: isDark ? surfaceDark : surfaceLight,
        onSurface: isDark ? Colors.white : Colors.black,
        surfaceVariant: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        onSurfaceVariant: isDark ? Colors.white70 : Colors.black87,
        outline: isDark ? neutralDark : neutralLight,
      ),
      
      // Visual density for comfortable touch targets
      visualDensity: VisualDensity.comfortable,
      
      // Typography
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ).copyWith(
        displayLarge: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.25,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? primaryDark : primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: isDark ? primaryDark.withOpacity(0.5) : primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
          foregroundColor: isDark ? primaryDark : primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: isDark ? primaryDark : primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceDark : const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? primaryDark : primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? errorDark : errorLight,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? errorDark : errorLight,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 16,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 16,
        ),
        errorStyle: TextStyle(
          color: isDark ? errorDark : errorLight,
          fontSize: 12,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: isDark ? surfaceDark : surfaceLight,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? surfaceDark : surfaceLight,
        selectedItemColor: isDark ? primaryDark : primaryColor,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      
      // Chips Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceDark.withOpacity(0.8) : surfaceLight.withOpacity(0.8),
        selectedColor: isDark ? primaryDark : primaryColor,
        disabledColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: isDark ? surfaceDark : surfaceLight,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceDark : Colors.grey.shade900,
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white10 : Colors.black12,
        thickness: 1,
        space: 24,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        labelColor: isDark ? primaryDark : primaryColor,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        indicatorColor: isDark ? primaryDark : primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: isDark ? primaryDark : primaryColor,
        inactiveTrackColor: isDark ? primaryDark.withOpacity(0.3) : primaryColor.withOpacity(0.3),
        thumbColor: isDark ? primaryDark : primaryColor,
        overlayColor: isDark ? primaryDark.withOpacity(0.2) : primaryColor.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 10,
        ),
        overlayShape: const RoundSliderOverlayShape(
          overlayRadius: 24,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? primaryDark : primaryColor,
        linearTrackColor: isDark ? primaryDark.withOpacity(0.2) : primaryColor.withOpacity(0.2),
        circularTrackColor: isDark ? primaryDark.withOpacity(0.2) : primaryColor.withOpacity(0.2),
      ),
    );
  }
}

// Extension for glass effect
extension GlassMorphism on Widget {
  ClipRRect asGlass({
    double blurRadius = 10,
    Color? tintColor,
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
        child: Container(
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withOpacity(opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: this,
        ),
      ),
    );
  }
} 