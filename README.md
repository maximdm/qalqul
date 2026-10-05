# Qalqul

A minimalistic **Bento grid** Flutter app combining a **scientific calculator**,
**notes**, and **personal finance** tracking — with a **Widget Studio** that lets
you build your own dashboard cards.

> Status: planning / pre-scaffold. See [`plan.md`](plan.md),
> [`milestones.md`](milestones.md), and [`agents.md`](agents.md).

## Features
- 🧮 **Calculator** — full scientific (trig, log, exp, √, ^, %), history, dark/light.
- 📝 **Notes** — create, edit, favorite, and search notes (local `sqflite`).
- 🔎 **Global Search** — one search across notes **and** all finance entries.
- 📈 **Investments** — track holdings, allocation, and returns.
- 💸 **Spending** — log transactions by category with monthly trends.
- 💳 **Credit** — manage credit accounts, balances, and due dates.
- 🎯 **Budget** — build goal-based budgets (e.g. a PC or gift) with progress.
- 🧩 **Widget Studio** — create your own Bento cards: trackers, counters, quick
  notes, progress meters, custom charts, and custom calculator tools.
- 💾 **Export / Import** — back up all data as a JSON file.

## Screens / navigation
Bottom tabs: **Home** (Bento dashboard + Add-Widget FAB) · **Calculator** ·
**Notes** · **Finance** (Investments / Spending / Credit / Budget).
Global search is available from the app bar.

## Tech stack
Flutter + Dart · Riverpod · sqflite · fl_chart · flutter_staggered_grid_view ·
math_expressions · intl.

## Getting started
```bash
flutter pub get
flutter run
```
Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install).

## License & attribution
- Calculator engine logic adapted from
  [williansantaana/scientific-calculator](https://github.com/williansantaana/scientific-calculator) (MIT).
- UI/learning patterns referenced from
  [Crealify/Flutter-100-Widgets-with-Handwritten-Notes](https://github.com/Crealify/Flutter-100-Widgets-with-Handwritten-Notes) (MIT).
- This project is original code; `syncfusion/flutter-widgets` is intentionally
  **not** used (commercial license). The `SaadKhanJadoon/Notes-App` repo has no
  license and was used for pattern reference only.
