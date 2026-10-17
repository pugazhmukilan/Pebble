import 'export_service.dart';

/// Provides hardcoded sample import files through app file storage.
///
/// The service is stateless and never reads from the repository.
class SampleExportService {
  const SampleExportService();

  static const _sampleCsv =
      'Date,Category,Amount,Note\n'
      '2025-01-05,Food,120.50,Lunch at office\n'
      '2025-01-07,Transport,45.00,Auto rickshaw\n'
      '2025-01-10,Shopping,899.00,New earphones\n'
      '2025-01-15,Food,60.00,Evening snacks\n'
      '2025-01-20,Utilities,350.00,Electricity bill\n';

  static const _sampleJson =
      '[\n'
      '  {"date":"2025-01-05","category":"Food","amount":120.50,"note":"Lunch at office"},\n'
      '  {"date":"2025-01-07","category":"Transport","amount":45.00,"note":"Auto rickshaw"},\n'
      '  {"date":"2025-01-10","category":"Shopping","amount":899.00,"note":"New earphones"},\n'
      '  {"date":"2025-01-15","category":"Food","amount":60.00,"note":"Evening snacks"},\n'
      '  {"date":"2025-01-20","category":"Utilities","amount":350.00,"note":"Electricity bill"}\n'
      ']\n';

  /// Saves the sample CSV to device storage and returns the saved file path.
  Future<String?> saveSampleCsv() => _save(_sampleCsv, 'csv');

  /// Saves the sample JSON to device storage and returns the saved file path.
  Future<String?> saveSampleJson() => _save(_sampleJson, 'json');

  Future<String?> _save(String content, String extension) {
    return saveToStorage(
      content: content,
      fileName: 'pebble_sample_format.$extension',
      extension: extension,
    );
  }
}

/// Returns a user-friendly display path (just the last two path segments).
///
/// e.g.  /storage/emulated/0/Android/data/com.pebble/files/Pebble/file.csv
///       →  Pebble/file.csv
String friendlyFilePath(String fullPath) {
  final parts = fullPath.replaceAll('\\', '/').split('/');
  if (parts.length >= 2) {
    return '${parts[parts.length - 2]}/${parts.last}';
  }
  return parts.last;
}
