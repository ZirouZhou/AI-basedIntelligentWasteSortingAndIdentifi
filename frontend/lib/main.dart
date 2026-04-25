// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Application Entry Point
// ------------------------------------------------------------------------------------------------
//
// This is the entry point of the EcoSort AI Flutter mobile application. It
// calls [runApp] with the root widget [WasteSortingApp], which sets up the
// Material Design theme and the bottom-navigation shell.
//
// Run with:
//   flutter run
//   flutter run -d chrome  (for web testing)
// ------------------------------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'app/waste_sorting_app.dart';

/// Bootstraps the EcoSort AI mobile application.
///
/// The entire app is wrapped inside a [WasteSortingApp] widget that provides
/// the Material theme and navigation structure.
void main() {
  runApp(const WasteSortingApp());
}
