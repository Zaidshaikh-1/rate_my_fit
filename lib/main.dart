import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/shell_screen.dart';

void main() {
  runApp(const RateMyFitApp());
}

class RateMyFitApp extends StatelessWidget {
  const RateMyFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rate My Fit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ShellScreen(),
    );
  }
}
