# Milestones — Qalqul

Status legend: ⬜ not started · 🟡 in progress · ✅ done

## M0 — Project setup ✅
- [x] Install Flutter SDK (3.47.5, user-folder, no admin)
- [x] `flutter create qalqul`
- [x] Add dependencies (riverpod, sqflite, path_provider, file_picker, fl_chart,
      flutter_staggered_grid_view, math_expressions, intl)
- [x] Theme + `BentoGrid`/`BentoCard` + bottom nav shell (`flutter analyze` clean, tests pass)

## M1 — Calculator ✅
- [x] Scientific engine (`math_expressions`; MIT repo logic ported/restyled)
- [x] Calculator screen (basic + scientific toggle, DEG mode, history, dark/light)
- [x] Engine unit tests (10 passing)

## M2 — Notes ✅
- [x] Note model (immutable, copyWith, toMap/fromMap) + sqflite `DatabaseHelper`
- [x] `NotesRepository` + `NotesNotifier` (Riverpod)
- [x] Notes list (search, favorite toggle, last-updated) + editor screen
- [x] `QalqulAppBar` + `themeModeProvider`/`navIndexProvider` shell refactor
- [x] Model unit tests (3) — 13/13 tests pass, analyze clean

## M3 — Finance core ✅
- [x] `AppTransaction`, `Investment`, `Budget` models (immutable + helpers)
- [x] `DatabaseHelper` v2: `transactions`, `investments`, `budgets` tables (onUpgrade preserves notes)
- [x] Repos + Riverpod providers for all three domains
- [x] Finance screen with TabBar (Investments · Spending · Credit · Budget) placeholders
- [x] Finance model unit tests — 16/16 tests pass, analyze clean

## M4 — Finance tabs ✅
- [x] Investments: list + allocation donut + return card
- [x] Spending: transactions + category bar chart
- [x] Credit: lender/amount/due-date cards
- [x] Budget: goal, target, saved, progress, deadline card

## M5 — Global Search ✅
- [x] `core/utils/search.dart` fan-out (notes, transactions, investments, budgets)
- [x] `GlobalSearch` SearchDelegate with navigation to editors

## M6 — Widget Studio (in-app cards) ✅
- [x] `UserWidget` model + `kind` enum + `user_widgets` table (v3)
- [x] Widget Studio: kind picker + create/edit/delete
- [x] `UserWidgetCard` renderer per kind (note summary, calculator, finance, spending)
- [x] Home dashboard renders user widgets via `BentoGrid`
- [ ] Custom chart widgets (source picker → fl_chart config) — future
- [ ] Custom calculator tools (formula template → mini-tool) — future

## M7 — Export / Import & settings ✅
- [x] `BackupService`: JSON export/import of all tables (notes, transactions, investments, budgets, user_widgets)
- [x] `SettingsScreen`: theme mode (System/Light/Dark), export/import actions, about
- [x] Settings gear added to `QalqulAppBar`; import refreshes all data providers

## M8 — Polish & quality ✅
- [x] Empty states: all list screens (notes, finance tabs, widgets studio, home) handle empty data
- [x] Dark/light QA: theme uses `Theme.of` tokens; only semantic status colors are hardcoded
- [x] `flutter analyze` clean
- [x] Unit tests: engine (`calculator_engine_test`), search (`search_test`), repositories (`repositories_test`)
- [x] `flutter build apk` passes (iOS requires a macOS host — not runnable here)
- [x] Added in-memory test seam (`DatabaseHelper.useTestDatabase`) for repo tests

## M9 — (Future) OS home-screen widgets ⬜
- [ ] `home_widget` integration (Android/iOS native config)
- [ ] "Pin to home" from a user widget
- [ ] Stub the action in v1; implement when confirmed

## M10 — Polish & enhancement backlog (ideas) ✅
Prioritised from a code review (see `plan.md` → Roadmap). Each item references the
files it touches.

### P0 — quick wins
- [x] Make Home widgets **reorderable + resizable** (use existing `UserWidget.position`;
      add `config` cell sizes; wire drag in `widgets_studio_screen.dart`; render in
      `bento_grid.dart` / `user_widget_card.dart`)
- [x] **Calculator history + memory** (M+, M−, MR, tappable history, copy result) in
      `calculator_provider.dart` + `calculator_screen.dart`
- [x] **Unify duplicate expression evaluators** — `calculator_engine.evaluateExpression`
      and `NoteExpression._eval` are near-identical; extract `core/utils/expression.dart`

### P1 — finance depth
- [x] **Recurring transactions + reminders** via `flutter_local_notifications` (MIT)
      — model fields + editor + `ReminderService` (best-effort scheduling; needs device
      permission prompt)
- [x] **CSV export** of transactions/investments (extend `BackupService`)
- [x] **Category-linked budgets** — assign transactions to a budget; show live progress
      in `budget_screen.dart`
- [x] **Net-worth Home widget** (investments + cash − debts)

### P2 — new surfaces
- [x] **Markdown notes** via `flutter_markdown` (MIT) — per-note `is_markdown` flag (DB v5),
      Edit/Preview toggle in `note_editor_screen.dart`, `NoteMarkdownView` renderer,
      `core/utils/markdown.dart` strips syntax for list previews/search snippets
- [x] **Multi-currency** + manual FX rates in `core/utils/money.dart` — `currency` column on
      transactions/investments/budgets (DB v5), `fx_rates` table + editor, `FxRates.convert`
      with pivot and an explicit `converted: false` fallback so totals never mix currencies
- [x] **App lock** via `local_auth` (BSD) — `AppLockGate` over the shell, phase state machine,
      grace period on backgrounding, biometric-only default, `unavailable` phase so devices
      without a screen lock aren't bricked
- [x] **i18n scaffold** (dep `intl` already used for dates/money) — `l10n.yaml` + `gen-l10n`,
      `en`/`es` ARB catalogues, `context.l10n`, device-local `app_settings` for the locale
- [x] More **smart Home widgets** (month spend, portfolio value, bills due) — new
      `UserWidgetKind`s with per-kind config in the studio (`monthOffset`, `category`,
      `billsWithinDays`)

### P3 — quality / growth
- [x] **Onboarding** + sample widgets / sample note demonstrating the `= ` trick
      - `lib/features/onboarding/onboarding_screen.dart` (3 pages, swipeable), gated by
      `onboardingDone` behind `settingsReadyProvider` so a returning user never sees
      it flash; `sample_data.dart` seeds 4 widgets, a Markdown note and 2 transactions
      and refuses to write into a non-empty database; replay from Settings
- [x] **Finance widget tests** (providers, calculator history)
- [x] **Tappable search results** + app shortcuts for "New calculation" / "New note"
      - search debounced (180 ms) and cached: one full read, then in-memory filtering,
        grouped by type with formatted amounts, and pushed through a captured
        `NavigatorState` so results open after the delegate closes
      - `QuickActionsService` (`quick_actions`, BSD-3) + `pendingShortcutProvider`,
        handled by the shell; localized titles
- [x] App icon / splash / adaptive icons — `tool/generate_brand_art.dart` draws the
      brand mark into `assets/brand/` (shared painter in `lib/shared/brand/brand_mark.dart`),
      `flutter_launcher_icons` + `flutter_native_splash` generate Android adaptive +
      monochrome icons and iOS `AppIcon.appiconset` / launch images
