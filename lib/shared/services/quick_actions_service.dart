import 'package:quick_actions/quick_actions.dart';

/// A home-screen shortcut the app knows how to handle.
enum QuickActionType { newCalculation, newNote }

const String kNewCalculationShortcut = 'qalqul.new_calculation';
const String kNewNoteShortcut = 'qalqul.new_note';

/// Maps the platform's raw shortcut type back to an action, or `null` when the
/// shortcut is one this version of the app doesn't know about.
QuickActionType? quickActionFromType(String raw) => switch (raw) {
      kNewCalculationShortcut => QuickActionType.newCalculation,
      kNewNoteShortcut => QuickActionType.newNote,
      _ => null,
    };

/// Long-press / home-screen actions ("New calculation", "New note").
///
/// Every call is guarded: quick actions are a platform nicety, so a missing
/// channel must never stop the app from starting.
class QuickActionsService {
  QuickActionsService({this.plugin = const QuickActions()});

  final QuickActions plugin;
  /// The plugin holds on to the callback for the lifetime of the process, and
  /// it can fire before any widget is listening, so the latest listener lives
  /// in a static field.
  static void Function(QuickActionType type)? _listener;

  bool _initialized = false;

  /// Registers [onSelected] and wakes the platform up. Safe to call twice.
  Future<void> initialize(void Function(QuickActionType) onSelected) async {
    _listener = onSelected;
    if (_initialized) return;
    _initialized = true;
    try {
      await plugin.initialize(dispatch);
    } on Object {
      // No platform support (or a test host): shortcuts simply don't appear.
      _initialized = false;
    }
  }

  /// Publishes the visible shortcut list. Titles are localized, so they have to
  /// be supplied by the caller.
  Future<void> setItems({
    required String newCalculation,
    required String newNote,
  }) async {
    try {
      await plugin.setShortcutItems([
        ShortcutItem(type: kNewCalculationShortcut, localizedTitle: newCalculation),
        ShortcutItem(type: kNewNoteShortcut, localizedTitle: newNote),
      ]);
    } on Object {
      // Ignored for the same reason as [initialize].
    }
  }

  Future<void> clearItems() async {
    try {
      await plugin.clearShortcutItems();
    } on Object {
      // Ignored for the same reason as [initialize].
    }
  }

  /// Entry point handed to the plugin. Exposed so tests (and the Android
  /// launcher) can deliver a shortcut without a real platform channel.
  static void dispatch(String rawType) {
    final action = quickActionFromType(rawType);
    final listener = _listener;
    if (action == null || listener == null) return;
    listener(action);
  }
}
