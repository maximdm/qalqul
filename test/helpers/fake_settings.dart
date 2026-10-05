import 'package:qalqul/shared/providers/settings_provider.dart';

/// [SettingsNotifier] that never touches sqflite: it starts from [initial] and
/// keeps every write in memory.
///
/// Every write also marks the settings as loaded, so tests don't need a
/// separate `settingsReadyProvider` override.
class FakeSettings extends SettingsNotifier {
  FakeSettings([Map<String, String> initial = const {}])
      : initial = Map.of(initial);

  final Map<String, String> initial;

  @override
  Map<String, String> build() => Map.of(initial);

  @override
  Future<void> set(String key, String value) async {
    state = {...state, key: value};
    ref.read(settingsReadyProvider.notifier).markLoaded();
  }

  @override
  Future<void> remove(String key) async {
    state = Map.of(state)..remove(key);
  }
}
