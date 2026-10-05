# Agents — Qalqul

Guidance for AI agents and contributors working in this repository.

## Project
Qalqul: Flutter calculator + finance/notes app with a minimalistic Bento grid.
Free to publish; all dependencies must be MIT/BSD licensed.

## Tech stack
Dart + Flutter. State via `flutter_riverpod` (Notifier, **no codegen** — avoid
`build_runner`). Local persistence via `sqflite`. Charts via `fl_chart`.
Bento layout via `flutter_staggered_grid_view`. Calculator engine via
`math_expressions`.

## Commands
- `flutter pub get` — install deps
- `flutter analyze` — lint/type check (must pass before commit)
- `flutter test` — run unit/widget tests
- `flutter run` — run on connected device/emulator
- `flutter build apk` / `flutter build ios` — release builds

## Conventions
- **Feature-first** folder layout under `lib/features/*`; shared widgets in `lib/shared`;
  cross-cutting logic in `lib/core`.
- **State:** Riverpod `Notifier`/`AsyncNotifier` providers. Repositories expose data;
  providers expose state. No `setState`-heavy globals.
- **Models:** immutable classes with `copyWith`, `toMap()`, `fromMap()`. Keep model
  files free of UI.
- **Storage:** one `DatabaseHelper` (singleton) opens the sqflite DB. Each domain has a
  repository class wrapping its table. Migrations bump `dbVersion`.
- **Bento UI:** every dashboard card is a `BentoCard`. User-created widgets render
  through a `BentoCard` factory that switches on `UserWidget.kind`.
- **Money/date:** always format with `intl` via helpers in `core/utils/money.dart`.
- **Theme:** light/dark defined once in `core/theme.dart`; use `Theme.of(context)`
  tokens, no hardcoded colors.
- **Naming:** files `snake_case`, classes `PascalCase`, providers `<Name>Provider`.

## License rules (important)
- **Do NOT** add Syncfusion packages (commercial license required).
- **Do NOT** copy code from `SaadKhanJadoon/Notes-App` (no license). Study the pattern only.
- Prefer MIT/BSD libs: `fl_chart`, `flutter_staggered_grid_view`, `math_expressions`.
- The MIT `williansantaana/scientific-calculator` engine may be ported (attribute origin).

## How to add a new finance tab
1. Add model in `core/models` + table in `DatabaseHelper`.
2. Add repository + Riverpod provider in `features/finance/<tab>/`.
3. Register the tab in `finance_screen.dart` TabBar.
4. Build its Bento cards with `BentoCard`.

## How to add a new user-widget kind
1. Add the kind to `UserWidget.kind` enum.
2. Add a config form in `features/widgets_studio/`.
3. Add a renderer branch in the `BentoCard` factory.
4. Update export/import serialization if config shape changes.

## Search
`core/utils/search.dart` fans out to every repo and returns unified
`SearchResult{type, id, title, subtitle, payload}`. Extend it when adding new
searchable domains.
