# Plan — Qalqul

Qalqul is a Flutter **calculator + finance/notes** app with a minimalistic **Bento grid** UI.
Users get a scientific calculator, notes with global search, four finance areas
(Investments, Spending, Credit, Budget), and a **Widget Studio** to build their own
dashboard cards.

Status: pre-scaffold. Flutter SDK is not yet installed; project folder is empty.

## Decisions (locked)
- **Distribution:** publish free (Play/App Store) → all deps must be MIT/BSD; no Syncfusion.
- **Calculator:** full scientific (trig, log, exp, √, ^, %).
- **State management:** Riverpod (`flutter_riverpod`, Notifier, no codegen).
- **Storage:** `sqflite` local + JSON export/import (no server).
- **Charts:** `fl_chart` (replaces commercial Syncfusion).
- **Bento layout:** `flutter_staggered_grid_view` + custom `BentoCard`.
- **OS home-screen widgets:** deferred to a future release (Phase 11 stub only).

## Stack / dependencies
- `flutter_riverpod` — state
- `sqflite` + `path_provider` — local storage
- `file_picker` — JSON backup file selection
- `fl_chart` — charts (BSD)
- `flutter_staggered_grid_view` — Bento masonry (MIT)
- `math_expressions` — scientific calculator engine (MIT)
- `intl` — currency / date formatting

## Architecture
```
lib/
  main.dart, app.dart
  core/
    theme.dart
    db/database_helper.dart
    models/{note, transaction, investment, budget, user_widget}.dart
    utils/{export_import.dart, money.dart, search.dart}
  shared/
    widgets/{bento_grid, bento_card, bottom_nav, global_search}.dart
    providers/*.dart
  features/
    home/            # Bento dashboard: auto summary cards + user widgets + Add-Widget FAB
    calculator/      # engine + screen (+ reused by calc-tool widgets)
    notes/           # list, editor, search
    finance/         # finance_screen (TabBar) + investments/spending/credit/budget
    widgets_studio/  # create/edit user widgets (kind picker + config forms)
```

### Navigation (4 bottom tabs)
`Home · Calculator · Notes · Finance`
- **Home** — Bento grid: auto summary cards (net worth, month spend, budgets due)
  **+ user-created widgets**; FAB → Widget Studio.
- **Search** — AppBar global SearchDelegate on Home/Notes/Finance.
- **Finance** — TabBar: Investments · Spending · Credit · Budget.
- **Widget Studio** — route from Home FAB; long-press a user widget to edit/remove.

## Data models (`core/models`)
- **Note**: id, title, body, isFavorite, createdAt, updatedAt
- **Transaction** (spending + credit): id, kind(`spend`|`credit`), amount, category, date, note
- **Investment**: id, name, principal, currentValue, asOf
- **Budget**: id, name (PC/Gift…), targetAmount, savedAmount, deadline, category
- **UserWidget**: id, kind(`tracker`|`counter`|`note`|`progress`|`chart`|`calc`),
  title, config(JSON), order, createdAt

All models are immutable with `copyWith` and `toMap`/`fromMap` for sqflite.

## Features
1. **Calculator** — scientific, history, light/dark. Engine ported/restyled from the
   MIT `williansantaana/scientific-calculator`, evaluated with `math_expressions`.
2. **Notes** — CRUD, favorite, search, last-updated; editor screen.
3. **Investments** — list + add/edit; allocation donut; total return card.
4. **Spending** — transactions by category; monthly trend chart; total spent card.
5. **Credit** — credit accounts, balances, due-date cards.
6. **Budget** — goal, target, saved, progress, deadline reminder card.
7. **Global Search** — SearchDelegate across Notes + Finance (type-chipped results).
8. **Widget Studio** — create in-app cards:
   - tracker / counter / quick note / progress meter
   - **custom chart widget** (pick finance source + chart type → saved card)
   - **custom calculator tool** (named formula template → mini-tool reusing engine)
9. **Export/Import** — dump all tables → JSON; import merges/replaces.

## Build phases / milestones
See `milestones.md`.

## Roadmap (post-M8 ideas)
Code-review backlog, tracked as **M10** in `milestones.md`, grouped by priority:

- **P0 (quick wins):** reorderable/resizable Home widgets; calculator history + memory;
  unify the two duplicate expression evaluators into `core/utils/expression.dart`.
- **P1 (finance depth):** recurring transactions + reminders; CSV export; category-linked
  budgets; net-worth Home widget.
- **P2 (new surfaces):** Markdown notes; multi-currency; app lock (`local_auth`); i18n;
  more smart Home widgets.
- **P3 (quality/growth):** onboarding + sample data; finance widget tests; tappable
  search results + app shortcuts; app icon/splash.


## License & reuse caveats
- `williansantaana/scientific-calculator` — **MIT**: calculator engine safe to port.
- `Crealify/Flutter-100-Widgets-with-Handwritten-Notes` — **MIT**: reference only (learning gallery).
- `SaadKhanJadoon/Notes-App` — **no license** (all-rights-reserved): study the
  sqflite + MVC pattern only; do **not** copy code. Our persistence code is original.
- `syncfusion/flutter-widgets` — **commercial**: avoided entirely; use `fl_chart`.
