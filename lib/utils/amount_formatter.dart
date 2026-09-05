import 'package:intl/intl.dart';

/// Placeholder shown in place of amounts when the "obscure" privacy toggle
/// is on, e.g. `₹••••••`.
const String kObscuredAmount = '••••••';

/// Compact rupee-amount formatting for space-constrained UI.
///
/// Large amounts are shortened so long numbers don't squeeze out the
/// category label in expense rows, e.g. `23535.5` → `23.5k`.
/// Uses Indian units: k (thousand), L (lakh), Cr (crore).
String formatCompactAmount(num amount) {
  final value = amount.toDouble();
  if (value.abs() >= 10000000) {
    return '${_trim(value / 10000000)}Cr';
  }
  if (value.abs() >= 100000) {
    return '${_trim(value / 100000)}L';
  }
  if (value.abs() >= 1000) {
    return '${_trim(value / 1000)}k';
  }
  return _trim(value);
}

/// Full rupee-amount formatting with Indian digit grouping.
///
/// Shows the complete amount instead of compact suffixes, e.g. `12345` →
/// `12,345`. Trailing zeros are dropped for whole amounts.
String formatFullAmount(num amount) {
  final nf = NumberFormat('##,##,##0.00', 'en_IN');
  var formatted = nf.format(amount.toDouble().abs());
  if (formatted.endsWith('.00')) {
    formatted = formatted.substring(0, formatted.length - 3);
  }
  return amount.toDouble() < 0 ? '-$formatted' : formatted;
}

String _trim(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

/// Percentage formatting that shows one decimal place only when needed,
/// e.g. `50` → `"50%"`, `33.333` → `"33.3%"`. Handles negatives.
String formatPercent(double value) {
  if (value == value.roundToDouble()) return '${value.round()}%';
  return '${value.toStringAsFixed(1)}%';
}
