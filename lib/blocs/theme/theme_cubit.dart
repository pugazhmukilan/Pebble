import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

/// Manages the app-wide theme mode (system / light / dark), persisted in Hive.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._settingsBox) : super(ThemeMode.system) {
    _load();
  }

  static const _settingsBoxName = 'settings';
  static const _themeModeKey = 'themeMode';

  final Box _settingsBox;

  Future<void> _load() async {
    final stored = _settingsBox.get(_themeModeKey);
    if (stored == null) return;
    final mode = ThemeMode.values.where((m) => m.name == stored).firstOrNull;
    if (mode != null) emit(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _settingsBox.put(_themeModeKey, mode.name);
  }

  static Future<Box> openSettingsBox() async {
    return await Hive.openBox(_settingsBoxName);
  }
}