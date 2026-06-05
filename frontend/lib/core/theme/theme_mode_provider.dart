import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple in-memory light/dark mode toggle.
/// (Persisting can be added later.)
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

