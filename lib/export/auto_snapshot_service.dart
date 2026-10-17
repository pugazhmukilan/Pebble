import 'dart:io';

import '../data/expense_repository.dart';
import 'export_service.dart';

/// Creates the rolling local safety snapshot independently of manual exports.
class AutoSnapshotService {
  AutoSnapshotService(this._repository);

  static const _snapshotFileName = 'pebble_auto_snapshot.csv';
  static const _snapshotInterval = Duration(days: 7);

  final ExpenseRepository _repository;

  /// Creates a snapshot when the previous successful snapshot is older than a
  /// week, or when the snapshot file is missing.
  Future<bool> createIfDue() async {
    final lastSnapshot = await _repository.getLastSnapshotDate();
    final snapshotDirectory = await resolveSnapshotDirectory();
    final snapshotFile = File(
      '${snapshotDirectory.path}${Platform.pathSeparator}$_snapshotFileName',
    );
    final isDue =
        lastSnapshot == null ||
        DateTime.now().difference(lastSnapshot) >= _snapshotInterval ||
        !await snapshotFile.exists();

    if (!isDue) return false;

    final expenses = await _repository.getAllExpenses();
    final categories = await _repository.getCategories();
    final content = CsvExportFormatter().formatToString(expenses, categories);

    final snapshot = File(
      '${snapshotDirectory.path}${Platform.pathSeparator}$_snapshotFileName',
    );
    final temporaryFile = File('${snapshot.path}.tmp');
    await temporaryFile.writeAsString(content, flush: true);
    if (await snapshot.exists()) {
      await snapshot.delete();
    }
    await temporaryFile.rename(snapshot.path);
    await _repository.setLastSnapshotDate(DateTime.now());
    return true;
  }
}
