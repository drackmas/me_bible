import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ThemeService extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _fontFamilyKey = 'font_family';
  static const _keepScreenOnKey = 'keep_screen_on';

  ThemeMode _mode = ThemeMode.system;
  double _fontSize = 16.0;
  String _fontFamily = 'Inter';
  bool _keepScreenOn = false;

  ThemeMode get mode => _mode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  bool get keepScreenOn => _keepScreenOn;

  static const List<double> fontSizes = [14, 16, 18, 20, 22, 24, 28];

  static const List<String> fontFamilies = [
    'System',
    'Inter',
    'Roboto',
    'Open Sans',
    'Lato',
    'Source Sans 3',
    'Merriweather',
    'Lora',
    'Noto Serif',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString(_themeKey) ?? 'system';
    _mode = switch (themeValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;
    if (!fontSizes.contains(_fontSize)) _fontSize = 16.0;

    _fontFamily = prefs.getString(_fontFamilyKey) ?? 'Inter';
    if (!fontFamilies.contains(_fontFamily)) _fontFamily = 'Inter';

    _keepScreenOn = prefs.getBool(_keepScreenOnKey) ?? false;
    await _applyKeepScreenOn(_keepScreenOn);

    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system',
    );
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, family);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepScreenOnKey, value);
    await _applyKeepScreenOn(value);
    notifyListeners();
  }

  Future<void> _applyKeepScreenOn(bool enable) async {
    try {
      if (enable) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // Ignore on platforms that don't support it
    }
  }
}
