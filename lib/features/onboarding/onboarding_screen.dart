import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/features/onboarding/sample_data.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/brand/brand_mark.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

/// One page of the first-run tour.
class _Page {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    this.bodyBuilder,
  });

  final IconData icon;
  final String Function(L10n) title;
  final String Function(L10n) body;

  /// Lets a page render rich content (the `=` trick needs a code sample).
  final Widget Function(BuildContext, L10n)? bodyBuilder;
}

/// The first-run tour.
///
/// Two modes:
///  * as the app's `home` (no [onDone]): it fills the window and can only be
///    left by finishing or skipping;
///  * pushed from Settings with [onDone]: same flow, but dismissible.
///
/// Completing it marks the `onboardingDone` setting, so it never reappears.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onDone});

  final Future<void> Function(bool withSamples)? onDone;

  static const int pageCount = 3;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Page> _pages(L10n l10n) => [
        _Page(
          icon: Icons.grid_view_rounded,
          title: (l) => l.onboardingWelcomeTitle,
          body: (l) => l.onboardingWelcomeBody,
        ),
        _Page(
          icon: Icons.functions,
          title: (l) => l.onboardingTrickTitle,
          body: (l) => l.onboardingTrickBody,
          bodyBuilder: (context, l) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.onboardingTrickBody),
              const SizedBox(height: 16),
              const _CodeBlock(lines: [
                'income = 3200',
                'rent = 1200',
                'left = income - rent = 2000',
              ]),
            ],
          ),
        ),
        _Page(
          icon: Icons.dashboard_customize_outlined,
          title: (l) => l.onboardingDashboardTitle,
          body: (l) => l.onboardingDashboardBody,
        ),
      ];

  Future<void> _finish({required bool withSamples}) async {
    if (_busy) return;
    setState(() => _busy = true);

    // Persist first: the shell swaps to the dashboard as soon as the flag is
    // set, so seeding has to happen before that.
    if (withSamples) {
      // A seeding failure must not trap the user on the tour — an empty app is
      // better than an app that cannot be started.
      try {
        await seedSampleData();
        ref.invalidate(userWidgetsProvider);
        ref.invalidate(notesProvider);
        ref.invalidate(transactionsProvider);
      } on Object catch (e, s) {
        debugPrint('Qalqul: onboarding sample data failed: $e\n$s');
      }
    }
    await ref
        .read(settingsProvider.notifier)
        .set(SettingKeys.onboardingDone, 'true');

    if (!mounted) return;
    final onDone = widget.onDone;
    if (onDone == null) {
      // The shell reacts to the setting; nothing to pop.
      return;
    }
    setState(() => _busy = false);
    await onDone(withSamples);
  }

  void _next() {
    if (_index == OnboardingScreen.pageCount - 1) {
      _finish(withSamples: true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pages = _pages(l10n);
    final isLast = _index == pages.length - 1;

    // Dismissible (Settings replay) gets a close button; the first-run tour
    // offers "skip" instead, since it fills the window.
    final topRight = widget.onDone != null
        ? IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _busy ? null : () => widget.onDone!(false),
          )
        : TextButton(
            onPressed: _busy ? null : () => _finish(withSamples: false),
            child: Text(l10n.onboardingSkip),
          );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.centerRight, child: topRight),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1} / ${pages.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (i == 0)
                          const Center(child: BrandMark(size: 120))
                        else
                          Center(
                            child: Icon(
                              page.icon,
                              size: 120,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          page.title(l10n),
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        page.bodyBuilder?.call(context, l10n) ??
                            Text(
                              page.body(l10n),
                              style: theme.textTheme.bodyLarge,
                            ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _next,
                    child: Text(
                      isLast ? l10n.onboardingStart : l10n.onboardingNext,
                    ),
                  ),
                  if (isLast) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _busy ? null : () => _finish(withSamples: false),
                      child: Text(l10n.onboardingStartEmpty),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monospaced preview of the `=` trick.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(
              line,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
