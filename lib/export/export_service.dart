import 'dart:io';

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

/// Saves a manually requested file using the platform's normal file-save
/// implementation. The picker opens in Downloads by default, while the user
/// can navigate to any other permitted location.
Future<String?> saveToStorage({
  required String content,
  required String fileName,
  required String extension,
}) async {
  final bytes = utf8.encode(content);
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save $extension file',
    fileName: fileName,
    initialDirectory: Platform.isAndroid
        ? '/storage/emulated/0/Download'
        : null,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
  );
  if (path == null) return null;

  // Android's Storage Access Framework returns a document-provider path,
  // not a filesystem path that dart:io can open. The plugin has already
  // written the bytes through the provider, so do not write it again.
  if (Platform.isAndroid) return path;

  // Some desktop platforms return the selected path without writing bytes.
  final file = File(path);
  if (!await file.exists() || await file.length() == 0) {
    await file.writeAsBytes(bytes, flush: true);
  }
  return path;
}

/// Resolves the private app storage folder used by automatic snapshots.
Future<Directory> resolveSnapshotDirectory() async {
  final base = Platform.isAndroid
      ? (await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory()
      : await getApplicationDocumentsDirectory();
  final directory = Directory('${base.path}${Platform.pathSeparator}Pebble');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

/// Writes manual exports to app file storage.
class ExportService {
  ExportService(this._repository);

  final ExpenseRepository _repository;

  /// Returns the path the user saved to, or `null` if cancelled.
  Future<String?> export(ExportFormatter formatter) async {
    final expenses = await _repository.getAllExpenses();
    final categories = await _repository.getCategories();
    final content = formatter.formatToString(expenses, categories);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'pebble_export_$timestamp.${formatter.fileExtension}';

    final path = await saveToStorage(
      content: content,
      fileName: fileName,
      extension: formatter.fileExtension,
    );

    if (path != null) {
      await _repository.setLastExportDate(DateTime.now());
    }
    return path;
  }
}
