// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Root MaterialApp Widget
// ------------------------------------------------------------------------------------------------
//
// [WasteSortingApp] is the root [MaterialApp] widget for the EcoSort AI
// mobile application. It configures:
//   • App title and debug banner
//   • The custom light theme from [AppTheme.lightTheme]
//   • The [AppShell] as the home screen (which provides bottom navigation)
// ------------------------------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_shell.dart';

/// The root widget of the EcoSort AI application.
///
/// Wraps the entire app in a [MaterialApp] with the EcoSort brand theme and
/// the bottom-navigation shell as the home screen.
class WasteSortingApp extends StatelessWidget {
  const WasteSortingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSort AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
