import 'package:flutter/material.dart';
import 'wrapd_theme.dart';
import '../services/storage_service.dart';

// ─────────────────────────────────────────────────────────
//  AppTheme - 2026 Design Excellence Wrapper
//  Modern theme provider with 2026 design principles
// ─────────────────────────────────────────────────────────

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark

  ThemeProvider() {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final isDark = _storage.loadThemePreference();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;

  ThemeData get currentTheme => _themeMode == ThemeMode.dark
      ? WrapdTheme.dark
      : WrapdTheme.light;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() => toggleTheme();

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _storage.saveThemePreference(_themeMode == ThemeMode.dark);
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _storage.saveThemePreference(_themeMode == ThemeMode.dark);
    notifyListeners();
  }
}

// Export WrapdTheme for direct access if needed
class WrapdThemeWrapper {
  static ThemeData createLightTheme() => WrapdTheme.light;
  static ThemeData createDarkTheme() => WrapdTheme.dark;
}
