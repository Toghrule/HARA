import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark, or whatever the phone is set to (the default). The choice is kept on the phone.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();

    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      final mode = ThemeMode.values.where((value) => value.name == saved);
      if (mode.isNotEmpty) state = mode.first;
    } catch (_) {
      // Follows the phone.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;

    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {
      // Kept for this run only.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
