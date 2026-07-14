import 'package:flutter/material.dart';

/// Global theme controller. Wrap your MaterialApp with ValueListenableBuilder
/// listening to themeController, and call themeController.toggle() (or
/// set themeController.value directly) from anywhere to switch themes.
final ValueNotifier<ThemeMode> themeController = ValueNotifier(ThemeMode.light);

class ThemeControllerHelper {
  static void toggle() {
    themeController.value =
    themeController.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static void setDark(bool isDark) {
    themeController.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static bool get isDark => themeController.value == ThemeMode.dark;
}