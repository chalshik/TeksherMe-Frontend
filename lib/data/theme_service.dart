import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';
  static const String _useGlassKey = 'use_glass';
  static const String _useNeumorphismKey = 'use_neumorphism';
  
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = AppTheme.primaryLight;
  bool _useGlassmorphism = true;
  bool _useNeumorphism = false;
  
  // Predefined color schemes
  final List<Color> availableColorSchemes = [
    AppTheme.primaryLight, // Indigo (Default)
    const Color(0xFF00669E), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF6D4C41), // Brown
  ];
  
  ThemeService() {
    _loadPreferences();
  }
  
  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get useGlassmorphism => _useGlassmorphism;
  bool get useNeumorphism => _useNeumorphism;
  
  // Generate theme
  ThemeData get lightTheme => AppTheme.getTheme(Brightness.light, _primaryColor);
  ThemeData get darkTheme => AppTheme.getTheme(Brightness.dark, _primaryColor);
  
  // Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    // Load color scheme
    final colorValue = prefs.getInt(_colorSchemeKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    
    // Load UI effect preferences
    _useGlassmorphism = prefs.getBool(_useGlassKey) ?? true;
    _useNeumorphism = prefs.getBool(_useNeumorphismKey) ?? false;
    
    notifyListeners();
  }
  
  // Toggle between light and dark themes
  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    
    notifyListeners();
  }
  
  // Set theme mode directly
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    
    notifyListeners();
  }
  
  // Set primary color
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, _primaryColor.value);
    
    notifyListeners();
  }
  
  // Toggle glassmorphism
  Future<void> toggleGlassmorphism() async {
    _useGlassmorphism = !_useGlassmorphism;
    
    // Ensure both effects aren't active at the same time
    if (_useGlassmorphism && _useNeumorphism) {
      _useNeumorphism = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useNeumorphismKey, false);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGlassKey, _useGlassmorphism);
    
    notifyListeners();
  }
  
  // Toggle neumorphism
  Future<void> toggleNeumorphism() async {
    _useNeumorphism = !_useNeumorphism;
    
    // Ensure both effects aren't active at the same time
    if (_useNeumorphism && _useGlassmorphism) {
      _useGlassmorphism = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useGlassKey, false);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useNeumorphismKey, _useNeumorphism);
    
    notifyListeners();
  }
  
  // Check if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && 
       WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
} 