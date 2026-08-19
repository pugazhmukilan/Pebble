import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/expense_repository.dart';
import '../models/category.dart';
import '../models/expense.dart';

/// Format contract — extensible without editing existing classes (OCP, §14).
abstract class ExportFormatter {
  String get fileExtension;
  String formatToString(
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  );
}

/// CSV export formatter.
class CsvExportFormatter implements ExportFormatter {
  @override
  String get fileExtension => 'csv';

  @override
  String formatToString(
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final buffer = StringBuffer()..writeln('Date,Category,Amount,Note');
    for (final e in expenses) {
      final date = dateFormat.format(e.date);
      final categoryName =
          categories
              .where((c) => c.id == e.categoryId)
              .map((c) => c.label)
              .firstOrNull ??
          e.categoryId;
      // Escape commas and newlines in note field
      final note = (e.note ?? '').replaceAll(',', ';').replaceAll('\n', ' ');
      buffer.writeln(
        '$date,$categoryName,${e.amount.toStringAsFixed(2)},$note',
      );
    }
    return buffer.toString();
  }
}

/// JSON export formatter.
class JsonExportFormatter implements ExportFormatter {
  @override
  String get fileExtension => 'json';

  @override
  String formatToString(
    List<Expense> expenses,
    List<ExpenseCategory> categories,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final entries = expenses.map((e) {
      final categoryName =
          categories
              .where((c) => c.id == e.categoryId)
              .map((c) => c.label)
              .firstOrNull ??
          e.categoryId;
      final noteStr = e.note != null
          ? '"${e.note!.replaceAll('"', '\\"')}"'
          : 'null';
      return '  {'
          '"date":"${dateFormat.format(e.date)}",'
          '"category":"$categoryName",'
          '"amount":${e.amount.toStringAsFixed(2)},'
          '"note":$noteStr'
          '}';
    });
    return '[\n${entries.join(',\n')}\n]';
  }
}

/// Writes an export file and shares it via the native share sheet.
/// Never touches UI — only formats, writes, and shares (SRP, §14).
class ExportService {
  ExportService(this._repository);

  final ExpenseRepository _repository;

  Future<void> export(ExportFormatter formatter) async {
    final expenses = await _repository.getAllExpenses();
    final categories = await _repository.getCategories();
    final content = formatter.formatToString(expenses, categories);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${dir.path}/pebble_export_$timestamp.${formatter.fileExtension}',
    );
    await file.writeAsString(content);
    await _repository.setLastExportDate(DateTime.now());
    await Share.shareXFiles([XFile(file.path)]);
  }
}
