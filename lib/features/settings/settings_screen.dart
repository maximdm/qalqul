import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/features/onboarding/onboarding_screen.dart';
import 'package:qalqul/features/security/app_lock_provider.dart';
import 'package:qalqul/features/settings/backup_service.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/providers/shell_providers.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/load_state_views.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _appVersion = '1.0.0';

  static String _messageFor(BuildContext context, String result) {
    final l10n = context.l10n;
    return switch (result) {
      'ok' => l10n.actionOk,
      'cancelled' => l10n.actionCancelled,
      'bad' => l10n.actionBadFile,
      _ => result,
    };
  }

  Future<void> _exportCsv(BuildContext context) async {
    final result = await BackupService.exportCsv();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_messageFor(context, result))));
    }
  }

  /// Re-runs the first-run tour without touching the `onboardingDone` flag,
  /// so it stays available from Settings afterwards.
  void _replayTour(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          onDone: (_) async => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final result = await BackupService.export();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_messageFor(context, result))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l10n.settingsImportConfirmTitle),
            content: Text(l10n.settingsImportConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: Text(l10n.settingsImport),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final result = await BackupService.import();
    if (context.mounted) {
      if (result == 'ok') {
        ref.invalidate(notesProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(investmentsProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(userWidgetsProvider);
        ref.invalidate(fxRatesProvider);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_messageFor(context, result))));
    }
  }

  /// Rows for the stored exchange rates.
  ///
  /// Kept apart from the settings body so the async load is handled here: a
  /// rate table that has not loaded yet should not look exactly like a user who
  /// has stored no rates.
  List<Widget> _rateTiles(BuildContext context, WidgetRef ref) =>
      ref.watch(fxRatesProvider).when(
        loading: () => const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
        ],
        error: (error, _) => const [LoadErrorView()],
        data: (rates) => [
          for (final r in rates)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.currency_exchange, size: 18),
              title: Text('1 ${r.base} = ${_rate(r.rate)} ${r.quote}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(fxRatesProvider.notifier).delete(r.id!),
              ),
              onTap: () => _showRateEditor(context, ref, existing: r),
            ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = context.l10n;
    final base = ref.watch(baseCurrencyProvider);
    final lockEnabled = ref.watch(appLockEnabledProvider);
    final biometricOnly = ref.watch(appLockBiometricOnlyProvider);
    final grace = ref.watch(appLockGraceSecondsProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: QalqulAppBar(
        title: l10n.settingsTitle,
        showSettingsAction: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.settingsAppearance,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.brightness_5),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.brightness_4),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsLanguage,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: ''),
            child: DropdownButton<String>(
              value: locale?.languageCode ?? 'system',
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.settingsLanguageSystem),
                ),
                for (final supported in L10n.supportedLocales)
                  DropdownMenuItem(
                    value: supported.languageCode,
                    child: Text(_languageName(supported.languageCode)),
                  ),
              ],
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .set(SettingKeys.locale, v == 'system' ? '' : v!),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsCurrencySection,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.settingsBaseCurrency),
            subtitle: Text(l10n.settingsBaseCurrencySubtitle),
            trailing: DropdownButton<String>(
              value: base,
              items: [
                for (final c in supportedCurrencies)
                  DropdownMenuItem(value: c.code, child: Text(c.code)),
              ],
              onChanged: (v) {
                if (v == null) return;
                ref
                    .read(settingsProvider.notifier)
                    .set(SettingKeys.baseCurrency, v);
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.currency_exchange),
            title: Text(l10n.settingsRates),
            subtitle: Text(l10n.settingsRatesSubtitle),
            trailing: const Icon(Icons.add),
            onTap: () => _showRateEditor(context, ref),
          ),
          ..._rateTiles(context, ref),
          const SizedBox(height: 24),
          Text(l10n.settingsSecurity,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.lock_outline),
            title: Text(l10n.settingsAppLock),
            subtitle: Text(l10n.settingsAppLockSubtitle),
            value: lockEnabled,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .set(SettingKeys.appLockEnabled, v ? 'true' : 'false'),
          ),
          if (lockEnabled) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsAppLockBiometricOnly),
              subtitle: Text(l10n.settingsAppLockBiometricOnlySubtitle),
              value: biometricOnly,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .set(SettingKeys.appLockBiometricOnly, v ? 'true' : 'false'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.settingsAppLockGrace),
              trailing: DropdownButton<int>(
                value: grace,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('0 s')),
                  DropdownMenuItem(value: 30, child: Text('30 s')),
                  DropdownMenuItem(value: 60, child: Text('1 min')),
                  DropdownMenuItem(value: 300, child: Text('5 min')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  ref
                      .read(settingsProvider.notifier)
                      .set(SettingKeys.appLockGraceSeconds, '$v');
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock),
              title: Text(l10n.settingsAppLockNow),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(appLockProvider.notifier).lockNow();
              },
            ),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(l10n.settingsReplayTour),
              onTap: () => _replayTour(context),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.settingsBackup,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(l10n.settingsExportJson),
            subtitle: Text(l10n.settingsExportJsonSubtitle),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(l10n.settingsImportJson),
            subtitle: Text(l10n.settingsImportJsonSubtitle),
            onTap: () => _import(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.settingsExportCsv),
            subtitle: Text(l10n.settingsExportCsvSubtitle),
            onTap: () => _exportCsv(context),
          ),
          const SizedBox(height: 24),
          Text(l10n.settingsAbout, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Qalqul'),
            subtitle: Text(l10n.settingsVersion(_appVersion)),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Qalqul',
              applicationVersion: _appVersion,
              applicationLegalese: l10n.settingsLegalese,
            ),
          ),
        ],
      ),
    );
  }

  static String _rate(double rate) =>
      rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toString();

  static String _languageName(String code) => switch (code) {
        'en' => 'English',
        'es' => 'Español',
        _ => code,
      };

  Future<void> _showRateEditor(
    BuildContext context,
    WidgetRef ref, {
    FxRate? existing,
  }) async {
    final l10n = context.l10n;
    String from = existing?.base ?? ref.read(baseCurrencyProvider);
    String to = existing?.quote ?? 'EUR';
    final controller =
        TextEditingController(text: existing == null ? '' : _rate(existing.rate));
    final codes = supportedCurrencies.map((c) => c.code).toList();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(existing == null ? l10n.settingsAddRate : l10n.settingsEditRate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: from,
                decoration: InputDecoration(labelText: l10n.settingsRateFrom),
                items: [
                  for (final c in codes)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => set(() => from = v!),
              ),
              DropdownButtonFormField<String>(
                initialValue: to,
                decoration: InputDecoration(labelText: l10n.settingsRateTo),
                items: [
                  for (final c in codes)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => set(() => to = v!),
              ),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.settingsRateValue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;
    final notifier = ref.read(fxRatesProvider.notifier);
    final rate = double.tryParse(controller.text.replaceAll(',', '.').trim());
    if (rate == null || rate <= 0 || from == to) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(from == to ? l10n.settingsRateSame : l10n.settingsRateInvalid),
        ),
      );
      return;
    }
    await notifier.upsert(base: from, quote: to, rate: rate);
  }
}