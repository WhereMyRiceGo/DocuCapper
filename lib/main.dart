import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/pick_image_screen.dart';
import 'theme.dart';

void main() {
  runApp(const DocuCapperApp());
}

class DocuCapperApp extends StatefulWidget {
  const DocuCapperApp({super.key});

  @override
  State<DocuCapperApp> createState() => _DocuCapperAppState();
}

class _DocuCapperAppState extends State<DocuCapperApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    setState(() {
      if (isDark == null) {
        _themeMode = ThemeMode.system;
      } else if (isDark) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
        prefs.setBool('isDarkMode', true);
      } else {
        _themeMode = ThemeMode.light;
        prefs.setBool('isDarkMode', false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      home: PickImageScreen(onToggleTheme: toggleTheme),
    );
  }
}
