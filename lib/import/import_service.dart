import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../constants/category_colors.dart';
import '../data/expense_repository.dart';
import '../models/category.dart';
import '../models/expense.dart';

/// Outcome of an import — surfaced to the UI as a status message.
class ImportResult {
  const ImportResult({
    required this.importedExpenses,
    required this.createdCategories,
    this.skipped = 0,
    this.error,
  });

  final int importedExpenses;
  final int createdCategories;

  /// Rows that could not be parsed (bad date/amount, malformed line).
  final int skipped;

  /// Set when the whole payload could not be read (e.g. invalid JSON).
  final String? error;

  bool get hasError => error != null;
}

/// One normalized expense row parsed from either format.
class _ImportRecord {
  _ImportRecord({
    required this.date,
    required this.category,
    required this.amount,
    this.note,
  });

  final DateTime date;
  final String category;
  final double amount;
  final String? note;
}

class _ParseResult {
  _ParseResult(this.records, this.skipped);
  final List<_ImportRecord> records;
  final int skipped;
}

/// Reads an export file and writes its rows back into the repository.
///
/// Mirrors the two [ExportFormatter] contracts exactly so a file produced by
/// export can always be re-imported. Category names are matched (case
/// insensitively) to existing categories; a name with no match is created as
/// a new category so migrating to a new phone never silently drops data.
class ImportService {
  ImportService(this._repository);

  final ExpenseRepository _repository;
  static const _uuid = Uuid();

  /// Import from CSV — same layout as [CsvExportFormatter]
  /// (`Date,Category,Amount,Note`, one row per expense).
  Future<ImportResult> importCsv(String content) async {
    final parsed = _parseCsv(content);
    return _persist(parsed);
  }

  /// Import from JSON — same shape as [JsonExportFormatter]
  /// (array of `{date, category, amount, note}` objects).
  Future<ImportResult> importJson(String content) async {
    final parsed = _parseJson(content);
    return _persist(parsed);
  }

  /// Resolve categories and persist the parsed rows.
  Future<ImportResult> _persist(_ParseResult parsed) async {
    final categories = await _repository.getCategories();
    final byLabel = <String, ExpenseCategory>{};
    for (final c in categories) {
      byLabel[c.label.trim().toLowerCase()] = c;
    }
    final usedValues = categories.map((c) => c.colorValue).toList();

    var imported = 0;
    var created = 0;

    for (final rec in parsed.records) {
      final key = rec.category.trim().toLowerCase();
      var match = byLabel[key];

      if (match == null) {
        // Unknown category → create it; don't lose the data on phone migration.
        final label = rec.category.trim().isEmpty ? 'Other' : rec.category.trim();
        final idx = allocateColorIndex(usedValues);
        final colorValue = idx != null
            ? poolColorValue(idx)
            : kOtherColorLight.toARGB32();
        if (idx != null) usedValues.add(poolColorValue(idx));

        match = ExpenseCategory(
          id: _uuid.v4(),
          label: label,
          iconCodePoint: 0,
          colorValue: colorValue,
        );
        await _repository.addCategory(match);
        byLabel[label.toLowerCase()] = match;
        created++;
      }

      final note =
          rec.note?.trim().isEmpty == true ? null : rec.note?.trim();
      await _repository.addExpense(
        Expense(
          amount: rec.amount,
          categoryId: match.id,
          date: rec.date,
          createdAt: rec.date,
          note: note,
        ),
      );
      imported++;
    }

    return ImportResult(
      importedExpenses: imported,
      createdCategories: created,
      skipped: parsed.skipped,
    );
  }

  _ParseResult _parseCsv(String content) {
    final records = <_ImportRecord>[];
    var skipped = 0;

    final lines = content.split(RegExp(r'\r\n|\n|\r'));
    final dateFormat = _dateFormat;
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;

      // Skip the header row (it never parses as a date).
      if (i == 0 && raw.toLowerCase().startsWith('date')) continue;

      // Note is the last field and was comma-escaped on export.
      final parts = raw.split(',');
      if (parts.length < 3) {
        skipped++;
        continue;
      }
      final date = dateFormat.tryParse(parts[0].trim());
      final category = parts[1].trim();
      final amount = double.tryParse(parts[2].trim());
      if (date == null || amount == null) {
        skipped++;
        continue;
      }
      final note = parts.length > 3
          ? parts.sublist(3).join(',').replaceAll(';', ',').trim()
          : null;

      records.add(_ImportRecord(
        date: date,
        category: category,
        amount: amount,
        note: note,
      ));
    }

    return _ParseResult(records, skipped);
  }

  _ParseResult _parseJson(String content) {
    final records = <_ImportRecord>[];
    var skipped = 0;

    late final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (e) {
      return _ParseResult(records, skipped);
    }
    if (decoded is! List) return _ParseResult(records, skipped);

    final dateFormat = _dateFormat;
    for (final item in decoded) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      final dateRaw = item['date'];
      final categoryRaw = item['category'];
      final amountRaw = item['amount'];
      if (dateRaw is! String || categoryRaw is! String) {
        skipped++;
        continue;
      }
      final date = dateFormat.tryParse(dateRaw.trim());
      final amount = amountRaw is num ? amountRaw.toDouble() : null;
      if (date == null || amount == null) {
        skipped++;
        continue;
      }
      final noteRaw = item['note'];
      final note = noteRaw is String ? noteRaw : null;

      records.add(_ImportRecord(
        date: date,
        category: categoryRaw,
        amount: amount,
        note: note,
      ));
    }

    return _ParseResult(records, skipped);
  }

  static final _dateFormat = DateFormat('yyyy-MM-dd');
}
