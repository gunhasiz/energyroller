import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  final SharedPreferences? _prefs;

  const ThemeService(this._prefs);

  static Future<ThemeService> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ThemeService(prefs);
    } catch (e) {
      debugPrint('Failed to initialize SharedPreferences: $e');
      return const ThemeService(null);
    }
  }

  ThemeMode loadThemeMode() {
    final savedValue = _prefs?.getString(_themeKey);
    return switch (savedValue) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await _prefs?.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }
}