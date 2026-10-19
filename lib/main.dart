import 'package:flutter/material.dart';

import 'screens/main_tab_shell_page.dart';
import 'screens/theme.dart';
import 'widgets/app_system_safe_area.dart';
import 'widgets/startup_splash.dart';

void main() {
  runApp(const FlutterScreensTestApp());
}

class FlutterScreensTestApp extends StatelessWidget {
  const FlutterScreensTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprout English',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const StartupSplash(
        child: AppSystemSafeArea(
          backgroundColor: AppTheme.backgroundLight,
          child: MainTabShellPage(),
        ),
      ),
    );
  }
}
