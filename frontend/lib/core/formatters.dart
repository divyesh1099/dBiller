String formatCurrency(double value, {String currency = 'USD'}) {
  final amount = value.toStringAsFixed(2);
  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$$amount';
    case 'EUR':
      return 'EUR $amount';
    case 'INR':
      return 'INR $amount';
    default:
      return '$currency $amount';
  }
}

String formatShortDate(DateTime? date) {
  if (date == null) return '-';
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
