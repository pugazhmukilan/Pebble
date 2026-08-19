# Expense Tracker — Build Specification (v2)

## 1. What this app is

A **personal, manual-entry, local-only** expense tracker built in Flutter. One user. No accounts, no cloud, no sync, no social features, no budgets, no recurring transactions, no income tracking. Visual language: clean, professional, restrained — think native iOS design: lots of white space, monochrome-first palette, rounded pill controls, thin-line data visuals, no decoration that isn't functional.

**Changed from v1 (explicitly, on purpose — noted here so nothing gets "re-cut" by accident later):**
- A pie chart of category breakdown is now included on the home screen, alongside the total card. (v1 had cut this down to a number only — this is a deliberate reversal.)
- Expense entries can have an optional **note** field.
- A single-page onboarding screen is included for first launch.
- Expenses can be **edited**, not just deleted — but only within the current month.
- State management is **BLoC** (`flutter_bloc`), not Riverpod/Provider.
- A calendar/month picker is available as a shortcut, in addition to swipe navigation.

**Still explicitly OUT of scope:**
- Multiple accounts or payment methods
- Recurring/scheduled expenses
- Budgets, limits, or alerts
- Tags or sub-categories
- Cloud sync, login, multi-device
- Income tracking (expenses only)
- Editing/deleting expenses in past (non-current) months
- Home screen / lock screen widget (still deferred to v1.1 — unchanged, see §10)

---

## 2. Tech stack

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter (latest stable) | Single codebase |
| State management | `flutter_bloc` (Cubit-style for simplicity, within the bloc pattern) | Explicit requirement |
| Local storage | `hive` + `hive_flutter` | Lightweight, no SQL boilerplate for single-user data |
| Onboarding flag | `shared_preferences` (or a small Hive `settingsBox`) | Persist "has seen onboarding" as a simple bool |
| Charts | `fl_chart` | Pie chart for category breakdown |
| Fonts | System default (San Francisco on iOS, Roboto on Android) or `Inter` via `google_fonts` if a consistent cross-platform look is preferred | Matches the clean/native-feeling reference — avoid a decorative custom font |
| Export | `share_plus` | Native share sheet for CSV/JSON |
| File handling | `path_provider` | Locate app directory for export files |
| Date formatting | `intl` | Month labels, date chip formatting |
| Icons | Built-in `Icons` (Material) or `cupertino_icons` for iOS-flavored icon set | Category icons |

**Still do not add:** HTTP client, backend SDK, auth package, analytics/crash SDK. Zero network calls.

---

## 3. Folder structure

```
lib/
├── main.dart
├── models/
│   └── expense.dart              # Hive model: Expense (amount, categoryId, date, note, createdAt)
├── data/
│   └── expense_repository.dart   # All Hive read/write logic
├── blocs/
│   ├── expense/
│   │   ├── expense_cubit.dart    # Loads/mutates expenses for the selected month
│   │   └── expense_state.dart    # Loading / Loaded(expenses, total, categoryBreakdown, month) / Error
│   └── onboarding/
│       └── onboarding_cubit.dart # Tracks whether onboarding has been completed
├── screens/
│   ├── onboarding_screen.dart    # Single-page intro, shown only on first launch
│   └── home_screen.dart          # The main screen: total + chart + list
├── widgets/
│   ├── month_header.dart         # Month label, chevrons, calendar-picker icon
│   ├── month_picker_sheet.dart   # Modal: jump directly to any month/year
│   ├── total_summary_card.dart   # Total amount card
│   ├── category_pie_chart.dart   # fl_chart pie, category breakdown
│   ├── expense_list.dart         # Grouped-by-day list, swipe-to-delete / tap-to-edit
│   ├── expense_entry_sheet.dart  # Shared bottom sheet for BOTH add and edit
│   ├── category_grid.dart
│   ├── amount_keypad.dart
│   └── date_chip_selector.dart
├── export/
│   └── export_service.dart
├── theme/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
└── constants/
    └── categories.dart
```

**Still one primary screen** (`home_screen.dart`). Add and edit both use the same `expense_entry_sheet.dart` as a modal bottom sheet — not separate routes. Onboarding is the only other full screen, and it only ever appears once.

---

## 4. Data model

```dart
@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  late double amount;

  @HiveField(1)
  late String categoryId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  String? note; // optional, nullable — no UI friction if left blank
}
```

Categories remain a static hardcoded list (same 8 as before: Food, Transport, Bills, Shopping, Health, Fun, Home, Other) — no user-facing category management in this version either.

---

## 5. Onboarding (first launch only)

- Single static screen. Content: app name, one short line on what makes it different (manual-only, private, local, fast entry — your actual value prop, not marketing fluff), and a "Get Started" button.
- Button navigates to `home_screen.dart` and sets the "has onboarded" flag to true (via `shared_preferences` or a settings box) so it never shows again.
- No swipeable multi-slide carousel, no permissions requests, no sign-up. One screen, one decision, done.
- `main.dart` checks the flag on launch: if true, go straight to `home_screen.dart`; if false, show onboarding first.

---

## 6. Home screen layout (top to bottom)

1. **Month header** — `< AUGUST 2026 >` with chevrons for swipe-adjacent navigation, plus a small calendar icon that opens `month_picker_sheet.dart` — a modal letting the user jump directly to any month/year instead of swiping incrementally. Both interactions update the same underlying selected-month state.
2. **Total summary card** — total spent in the selected month, prominent number, card-style container.
3. **Category pie chart** — simple pie/donut showing proportion of spend per category for the selected month. No legend clutter — tapping a slice can optionally highlight the matching category in the list below, but this is a nice-to-have, not required for v2.
4. **Expense list** — grouped by day, most recent first. Each row: category icon, label, note (if present, shown small/muted under the label), amount.
   - **Tap a row** → opens `expense_entry_sheet.dart` pre-filled for editing, *only if the row belongs to the currently-selected month AND that month is the real current month* (see §8 — past months are read-only).
   - **Swipe or long-press a row** → delete, with the same current-month-only restriction.
5. **Floating "+" button** — opens `expense_entry_sheet.dart` in add mode.

**On app launch:** always opens to the real current month (today's month), regardless of whatever month was last viewed in a previous session.

---

## 7. Add/Edit expense sheet (shared component)

Same bottom sheet handles both flows — the only difference is whether it's pre-populated and whether it calls `addExpense()` or `updateExpense()` on submit.

Contents, top to bottom:
1. **Date chip row** — Today / Yesterday / 2d / 3d / Custom, defaulting to Today for new entries, or the entry's actual date (highlighted) when editing.
2. **Category grid** — 8 categories, single tap to select.
3. **Amount display + custom numeric keypad** — same as before.
4. **Note field (optional)** — simple single-line text input, no character limit enforcement needed, clearly marked optional (e.g. placeholder text "Add a note (optional)"), never required to proceed.
5. **Submit button** — "Log expense" (add mode) or "Save changes" (edit mode). Enabled once category + amount > 0.

---

## 8. Current-month-only edit/delete rule

This is a deliberate constraint, not a limitation to work around:
- Once a month is no longer the current calendar month, its entries become **read-only** in the UI — no edit sheet opens, no delete swipe/long-press action fires, when viewing an archived month.
- Rationale: keeps the mental model simple (this month is "live," everything before is settled history) and avoids retroactively changing totals for months you've already mentally closed out or already exported/backed up.
- Implementation detail: gate the tap-to-edit and swipe/long-press-to-delete handlers in `expense_list.dart` on `isCurrentMonth(selectedMonth)` — if false, the row is display-only.

---

## 9. Export flow

Unchanged from v1: CSV or JSON, all-time data (not just current month), via `share_plus`'s native share sheet, with a "last backup: N days ago" indicator on the home screen. See prior spec logic — `expense_repository.dart` still exposes `getAllExpenses()` for this.

---

## 10. Deferred to v1.1 (still not built now)

**Home screen / lock screen widget** — unchanged reasoning: needs native Kotlin/Jetpack Glance (Android) and SwiftUI/WidgetKit (iOS) since Flutter can't render the widget surface itself. Build the app first, add the widget once the core loop is proven in daily use.

---

## 11. Visual design system (Apple-influenced, clean/professional)

This replaces the earlier dark glassmorphic direction — the reference you provided is light, monochrome-first, and restrained. Locking these tokens:

| Token | Value | Use |
|---|---|---|
| Background | `#FFFFFF` / `#FAFAFA` | App background |
| Surface/card | `#F5F5F7` with subtle shadow, or hairline border `#E5E5EA` | Total card, list rows, sheet background |
| Text primary | `#1C1C1E` | Amounts, headings |
| Text muted | `#8E8E93` | Labels, notes, secondary text |
| Accent | Near-black `#1C1C1E` for primary buttons/active states — avoid a loud color accent; let category icons carry the only color variation | Buttons, active chip, active tab |
| Category chart colors | A muted, desaturated palette (one distinct hue per category, low saturation) | Pie chart slices only |

**Typography:** system font stack (or `Inter` if you want pixel-identical cross-platform rendering) — no display/decorative font. Numerals in the total card and list can use tabular figures via `FontFeature.tabularFigures()` in `TextStyle` for alignment, without needing a separate monospace font family.

**Component language, per the reference:** pill-shaped chips for filters/date selection, rounded-rectangle cards with soft shadows (not hard borders), a simple thin-line or pie chart with no heavy gridlines, a calendar day-strip pattern is optional inspiration for the month picker but a standard month/year picker is sufficient for v2.

---

## 12. Suggested build order

1. Scaffold Flutter project; add `flutter_bloc`, `hive`, `hive_flutter`, `fl_chart`, `shared_preferences`, `share_plus`, `path_provider`, `intl`.
2. Define `Expense` Hive model (with `note` field), run codegen.
3. Build `expense_repository.dart` — add `updateExpense()` alongside the existing add/delete/query methods.
4. Build `ExpenseCubit` + `ExpenseState` — loading/loaded states carrying the selected month's expenses, total, and category breakdown map.
5. Build theme files per §11.
6. Build `onboarding_screen.dart` + the "has onboarded" flag check in `main.dart`.
7. Build `home_screen.dart` static layout first — header, total card, pie chart placeholder, list, FAB.
8. Wire it to `ExpenseCubit` — real data, real month switching (swipe + calendar picker).
9. Build `expense_entry_sheet.dart` for add, wire submit to `addExpense()`.
10. Extend the same sheet for edit — pre-fill from a tapped row, wire to `updateExpense()`, gated by the current-month-only rule.
11. Add swipe/long-press delete, same current-month-only gate.
12. Wire `category_pie_chart.dart` to the cubit's category breakdown data.
13. Build `export_service.dart` and backup-age indicator (unchanged from v1 spec).
14. End-to-end test: onboarding shows once, add/edit/delete work only in current month, past months are read-only, chart and total match list contents, export produces valid CSV/JSON, month picker and swipe both update state consistently.

---

## 13. Definition of done for v2

- First launch shows onboarding once; never again after "Get Started" is tapped.
- Home screen opens directly to the real current month.
- Total card and pie chart accurately reflect the selected month's data.
- Can add an expense (category + amount required, note optional) in a bottom sheet, no page navigation.
- Can edit or delete an expense **only** if it belongs to the current month.
- Can swipe between months and also jump directly via the calendar picker.
- Can export all-time data as CSV or JSON via the native share sheet.
- Visual language matches §11 — light, monochrome-first, no decorative color beyond category icons/chart slices.
- Fully offline, zero network permissions.

---

## 14. Coding standards & architecture principles

"Production-level" and "SOLID" are easy to say and vague to build against. Here's what they mean concretely for this codebase — Copilot should follow these, not generic boilerplate patterns.

### SOLID, mapped to this app specifically

- **Single Responsibility** — each class does one job. `ExpenseCubit` orchestrates state only; it never touches Hive directly. `ExpenseRepository` only persists/queries; it never knows about BLoC states. `ExportService` only formats/writes files; it never touches UI. Widgets only render + dispatch events; no business logic (totals, grouping, validation) inside `build()` methods — that logic lives in the repository or a pure helper function, unit-testable in isolation.
- **Open/Closed** — the export flow should be extensible without editing existing code when a new format is added later. Define an `ExportFormatter` interface with `formatToString(List<Expense>)`; `CsvExportFormatter` and `JsonExportFormatter` implement it. Adding a third format later means adding a new class, not modifying the two existing ones.
- **Liskov Substitution** — any class implementing `ExpenseRepository` (or `ExportFormatter`) must be fully swappable without breaking callers. This is what makes a fake/in-memory repository usable in tests without touching real Hive storage.
- **Interface Segregation** — keep the repository interface scoped to what's actually needed (`getExpensesForMonth`, `addExpense`, `updateExpense`, `deleteExpense`, `getAllExpenses`) — don't bloat it with speculative methods for features that don't exist yet (no `getExpensesByTag()` just because it might be nice someday).
- **Dependency Inversion** — `ExpenseCubit` depends on the abstract `ExpenseRepository` interface, injected via constructor, not on a concrete `HiveExpenseRepository` directly. `main.dart` wires the concrete implementation in at startup. This is the one abstraction genuinely worth having here — it's what makes the state layer testable at all.

**Where I would deliberately *not* apply extra abstraction:** don't create an interface for `Category` (it's static data, not a swappable dependency), don't build a generic "repository factory" or service locator framework for a single local data source, don't add a caching layer — Hive reads for one person's monthly expense data are already fast enough that adding a cache is solving a problem that doesn't exist yet. If Copilot suggests this kind of scaffolding, skip it.

### Clean code conventions

- **No magic strings.** Category IDs (`'food'`, `'transport'`, etc.) should be a Dart `enum`, not raw strings scattered across files — the current `constants/categories.dart` list should map enum values to labels/icons, and `Expense.categoryId` should be typed as the enum (Hive supports enum adapters via codegen).
- **Immutable state.** BLoC states should be immutable classes (use `equatable` for value comparison so `BlocBuilder` doesn't rebuild on identical states).
- **Small, composable widgets.** No single widget file over roughly 150–200 lines — if `home_screen.dart` is getting long, that's a signal to extract another widget, which the folder structure in §3 already anticipates.
- **Typed error handling.** Repository methods that can fail (file I/O during export, Hive write errors) should surface typed failures rather than letting raw exceptions bubble into the UI unhandled — a simple sealed `Result<T>` (success/failure) or try/catch with a specific `ExportException` is enough; don't pull in a heavy functional-programming package for this.
- **Const everywhere possible.** Widgets, styles, and icons that don't change should use `const` constructors — this is a real, measurable rebuild-cost win in Flutter, not a style nitpick.

### Performance, scoped honestly to this app's actual data size

This is a single person's manual expense log — a few hundred to low thousands of entries a year, not a dataset that needs query optimization. "Optimized" here means:
- Use `BlocBuilder`'s `buildWhen` (or `BlocSelector`) so the pie chart doesn't rebuild when only the list scrolls, and the total card doesn't rebuild on every keystroke in the entry sheet.
- Compute month totals and category breakdowns once per state change inside the cubit, not recomputed inside every widget's `build()`.
- Don't prematurely index or paginate Hive queries — filtering an in-memory list of a few hundred `Expense` objects by month is effectively instant. Revisit only if real usage ever proves otherwise.

### Linting

Add `flutter_lints` (or `very_good_analysis` for a stricter preset) to `analysis_options.yaml` from the start — catching unused imports, missing const, and inconsistent naming as you go is cheaper than a cleanup pass later.
