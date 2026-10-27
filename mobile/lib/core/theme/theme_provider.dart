import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { serene, ocean }

class AppThemeData {
  final AppTheme id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const AppThemeData({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  static const serene = AppThemeData(
    id: AppTheme.serene,
    name: 'Serene Clinical',
    primary: Color(0xFF1B4332), // Deep Forest
    secondary: Color(0xFFBDEACD), // Soft Mint
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF), // Paper White
    textPrimary: Color(0xFF012D1D),
    textSecondary: Color(0xFF414844), // Slate Gray approx
  );

  static const ocean = AppThemeData(
    id: AppTheme.ocean,
    name: 'Ocean Breeze',
    primary: Color(0xFF005F73),
    secondary: Color(0xFF94D2BD),
    background: Color(0xFFF0F8FF),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0A1128),
    textSecondary: Color(0xFF5A6171),
  );

}

class ThemeNotifier extends Notifier<AppThemeData> {
  @override
  AppThemeData build() {
    _loadTheme();
    return AppThemeData.serene;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('app_theme') ?? 'serene';
    
    switch (themeString) {
      case 'ocean':
        state = AppThemeData.ocean;
        break;
      case 'serene':
      default:
        state = AppThemeData.serene;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (theme) {
      case AppTheme.ocean:
        state = AppThemeData.ocean;
        await prefs.setString('app_theme', 'ocean');
        break;
      case AppTheme.serene:
        state = AppThemeData.serene;
        await prefs.setString('app_theme', 'serene');
        break;
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeData>(() {
  return ThemeNotifier();
});
