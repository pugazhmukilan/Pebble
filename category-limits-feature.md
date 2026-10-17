# Pebble Category Spending Limits

## 1. Feature Summary

Pebble now supports optional monthly spending limits for each expense category.

A user can set a limit such as 5,000 for Food. Pebble then shows how much has been spent compared with that limit. The limit is informational only: it never prevents the user from adding, editing, or importing an expense.

The feature is designed around monthly history. A limit change affects the current calendar month and future months, but it does not rewrite the meaning of previous months.

## 2. User Flow

### Open the limits page

1. Open Pebble.
2. Open Settings.
3. Under `SPENDING LIMITS`, tap `Category limits`.
4. Pebble displays every existing category.
5. Each category shows either:
   - `No limit`, or
   - its current monthly limit.

This page is only for limits. It does not provide category creation, renaming, deletion, icon editing, or other category-management actions.

### Set a limit

1. Tap a category.
2. Enter a positive amount.
3. Tap `Save`.
4. Pebble saves the limit for the current calendar month.
5. The category list refreshes.
6. The dashboard refreshes its limit information.

Blank, invalid, zero, or negative values are rejected. Users must use `Remove limit` to unset an existing limit.

### Change a limit

1. Tap a category that already has a limit.
2. Replace the amount.
3. Tap `Save`.
4. The new amount becomes the limit for the current month and future months.
5. Previous months remain unchanged.

### Remove a limit

1. Tap a category with an existing limit.
2. Tap `Remove limit`.
3. Pebble records an explicit unset event for the current month.
4. The category becomes unlimited for the current month and future months.
5. Earlier months still retain their historical limit.

## 3. Month Rules

Limits are resolved using category, year, and month.

Example:

| Month | Action | Effective limit |
|---|---|---:|
| October | Set Food to 5,000 | 5,000 |
| October | Change Food to 6,000 | 6,000 for October |
| November | No change | 6,000 inherited |
| November | Change Food to 7,000 | 7,000 for November onward |
| December | Remove limit | Unlimited from December onward |

October remains 6,000 even after the November and December changes.

The resolver always selects the latest limit change whose effective month is on or before the month being viewed.

A category with no earlier limit change is unlimited. An unset record is different from a zero limit: it is a tombstone that explicitly removes the limit going forward.

## 4. Dashboard Behavior

The existing dashboard layout remains in place.

A compact `Limits` section is added inside the existing total summary card when at least one category has a limit. Each limited category shows:

- Category name
- Amount spent in the selected month
- Category limit
- Progress bar
- Over-limit color when spending is above the limit

A limited category is shown even when its spending is zero. Categories without limits do not appear in this section.

The feature does not:

- Block an expense.
- Prevent spending above the limit.
- Reject an imported expense.
- Change existing total calculations.
- Change the existing category pie chart behavior.

## 5. Data Model

### Existing Hive data remains unchanged

The existing models keep their current Hive type IDs:

- `Expense`: type ID 0
- `ExpenseCategory`: type ID 1

No fields were added to either existing model. This reduces the chance of breaking existing user data.

### New limit model

`CategoryLimitChange` is stored separately:

```text
categoryId
 effectiveYear
effectiveMonth
limit: double?
```

The `limit` value is:

- A positive number for a real limit.
- `null` for an explicit unset event.

The model uses Hive type ID 2 and is stored in the separate box:

```text
category_limit_changes
```

The key format is deterministic:

```text
categoryId|year|month
```

That means saving a new limit twice for the same category and month replaces the earlier value rather than creating duplicate active records.

## 6. Database Safety and Future Schema Changes

The new feature does not modify or recreate the existing `expenses` or `categories` boxes.

At startup Pebble now:

1. Initializes Hive.
2. Registers the existing Expense adapter.
3. Registers the existing Category adapter.
4. Registers `CategoryLimitChangeAdapter` with type ID 2.
5. Opens the existing expense box.
6. Opens the existing category box.
7. Opens the new limit-history box.

A fresh installation simply starts with an empty limit-history box. Existing expenses and categories remain available.

The startup code no longer deletes existing Hive boxes when opening fails. Deleting a box would silently destroy user data. A future schema change must use a migration or a backup/restore path instead.

Future model changes should follow these rules:

- Never reuse an existing Hive type ID.
- Never change the meaning of an existing field ID.
- Add new data in a separate model/box when it has independent lifecycle or history.
- Add a migration for incompatible data instead of deleting the box.
- Test opening an existing user database before releasing the update.

## 7. Save Flow

The save path is:

```text
CategoryLimitsScreen
  -> ExpenseCubit.setCategoryLimit()
  -> HiveExpenseRepository.setCategoryLimit()
  -> category_limit_changes Hive box
  -> flush to disk
  -> read the record back
  -> reload dashboard state
  -> refresh the limits page
```

The repository validates that the amount is greater than zero. After writing, it flushes the Hive box and reads the saved value back. If the saved record cannot be verified, the operation throws a clear error instead of pretending that the save succeeded.

The dialog flow also handles asynchronous lifecycle safely:

- The Cubit is captured before awaiting the dialog.
- The widget is checked after the dialog closes.
- The text controller is disposed exactly once.
- The limit save is awaited before refreshing the page.
- The refresh future is assigned safely through `setState`.
- Storage errors are shown to the user through a SnackBar.

## 8. Import and Export Behavior

The existing expense import/export formats remain unchanged.

Current formats continue to contain expenses and categories as before:

- CSV: `Date,Category,Amount,Note`
- JSON: existing expense array format

Category limit history is intentionally device-local in this version. Existing CSV and JSON files continue to import correctly regardless of the new Hive box and schema.

Automatic snapshots also remain expense-only. A future version can introduce a versioned backup format if limit history needs to move between devices.

Manual exports and sample files are different from automatic snapshots:

- Manual CSV and JSON exports open the native save-file picker.
- Sample CSV and JSON downloads use the same save-file picker.
- The user can choose a location such as Downloads or Documents.
- Automatic snapshots do not open a picker and are saved silently in the platform-resolved `Pebble` folder.
- On Android, the automatic folder uses external app storage when available.

## 9. File-Level Changes

### New files

#### `lib/models/category_limit_change.dart`

Adds the `CategoryLimitChange` Hive model and its manual Hive adapter.

Responsibilities:

- Store category ID and effective month.
- Store a positive limit or nullable unset marker.
- Serialize using keyed fields.
- Use new Hive type ID 2.

#### `lib/analysis/category_limit_resolver.dart`

Adds pure month-resolution logic.

Responsibilities:

- Resolve one category's effective limit for a month.
- Resolve all active category limits for a month.
- Apply historical changes in chronological order.
- Preserve prior-month behavior.
- Exclude categories whose latest event is an unset event.

Keeping this logic pure makes the most important business rules easy to test without a real device or Hive database.

#### `lib/screens/category_limits_screen.dart`

Adds the limits-only Settings page.

Responsibilities:

- Load categories and current-month limits.
- Display every category.
- Allow set, update, and explicit remove actions.
- Validate positive numeric input.
- Handle async dialog and save lifecycle safely.
- Display save/load failures clearly.

#### `test/category_limit_resolver_test.dart`

Tests the core month rules:

- No limit before the first change.
- Inheritance into later months.
- A later change does not modify an earlier month.
- Unset behavior.
- Same-month replacement behavior.
- Resolving all active limits.

### Modified files

#### `lib/main.dart`

- Imports the new limit model.
- Registers `CategoryLimitChangeAdapter`.
- Opens `category_limit_changes`.
- Passes the new box into `HiveExpenseRepository`.
- Keeps existing boxes and user data untouched.

#### `lib/data/expense_repository.dart`

- Extends `ExpenseRepository` with limit methods.
- Adds the limit-history Hive box.
- Reads effective limits through `CategoryLimitResolver`.
- Saves current-month limits.
- Saves explicit unset events.
- Flushes and verifies writes.
- Removes a deleted category's limit history.
- Keeps manual export date and automatic snapshot date separate.

#### `lib/blocs/expense/expense_state.dart`

Adds `categoryLimits` to `ExpenseLoaded` so the dashboard receives resolved limits together with expenses and category totals.

#### `lib/blocs/expense/expense_cubit.dart`

- Loads limits for the selected dashboard month.
- Adds `setCategoryLimit`.
- Adds `unsetCategoryLimit`.
- Reloads dashboard state after changes.
- Preserves the rule that limits do not participate in expense validation.

#### `lib/screens/settings_screen.dart`

Adds the `Category limits` navigation tile below theme selection and above backup/import controls.

Existing manual export and import actions remain unchanged.

#### `lib/screens/home_screen.dart`

Passes the resolved category limits into `TotalSummaryCard`.

#### `lib/widgets/total_summary_card.dart`

Adds the compact dashboard limits section. It renders all limited categories, including categories with zero spending, and highlights over-limit spending without blocking anything.

#### `lib/widgets/category_pie_chart.dart`

Remains compatible with the existing chart and legend behavior. Limit display was kept in the summary card so the chart does not become structurally overloaded.

#### `lib/export/auto_snapshot_service.dart`

Adds the earlier automatic local snapshot feature. It is separate from manual export and uses its own snapshot date. It writes the rolling local backup using a temporary file before replacement.

Automatic snapshots use `resolveExportDirectory()` and save as `pebble_auto_snapshot.csv` inside the `Pebble` folder. They never show the manual save dialog.

#### `lib/export/export_service.dart`

Manual exports write the generated filename and file bytes directly to the app's file-storage directory. They do not open a destination picker or create an export subfolder. `file_picker` remains available for importing files.

#### `lib/export/sample_export_service.dart`

Sample CSV and JSON files use the same native save picker as manual exports. Cancelling the picker does not show a false success message.

#### `lib/blocs/expense/expense_cubit.dart` and `lib/data/expense_repository.dart`

Also keep automatic snapshot tracking separate from manual export tracking. The dashboard backup indicator reads the last successful automatic snapshot date, not the last manual export date.

#### `test/import_service_test.dart`

Updates the in-memory repository fake to implement the expanded repository interface. Existing CSV and JSON import tests remain valid.

## 10. Verification Completed

The implementation was validated with:

```text
flutter analyze
flutter test
```

Result:

```text
No issues found.
All 29 tests passed.
```

The APK also built successfully for the connected Android device. A full application restart is required after adding the new Hive adapter; hot reload alone does not rerun adapter registration.

## 11. Known Scope Boundary

The current implementation intentionally keeps category limits local to the device and does not add limit data to the existing CSV/JSON contracts.

The next backup-format version should be versioned rather than changing the current legacy formats. That would allow limit history to be restored safely without breaking older Pebble imports.
