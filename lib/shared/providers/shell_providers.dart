import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

  void setMode(ThemeMode mode) => state = mode;
}

final navIndexProvider =
    NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}
