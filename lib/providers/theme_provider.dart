import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode (like Instagram)

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveThemePreference();
    notifyListeners();
  }

  // Load theme preference from SharedPreferences
  void _loadThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default to dark
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  // Save theme preference to SharedPreferences
  void _saveThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Get the current theme data
  ThemeData get currentTheme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  // Dark theme configuration
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color.fromRGBO(0, 0, 0, 1),
    cardColor: const Color.fromRGBO(38, 38, 38, 1),
    dividerColor: const Color.fromRGBO(38, 38, 38, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromRGBO(0, 0, 0, 1),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(0, 0, 0, 1),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.grey),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color.fromRGBO(38, 38, 38, 1),
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey),
    ),
  );

  // Light theme configuration
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    cardColor: const Color.fromRGBO(250, 250, 250, 1),
    dividerColor: const Color.fromRGBO(219, 219, 219, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
      bodySmall: TextStyle(color: Colors.grey),
      titleLarge: TextStyle(color: Colors.black),
      titleMedium: TextStyle(color: Colors.black),
      titleSmall: TextStyle(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.black),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Color.fromRGBO(250, 250, 250, 1),
      filled: true,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey),
    ),
  );
}