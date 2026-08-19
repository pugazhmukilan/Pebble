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

String _trim(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
