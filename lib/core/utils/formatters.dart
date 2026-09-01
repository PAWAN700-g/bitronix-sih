import 'package:intl/intl.dart';

class Formatters {
  static String formatTimestamp(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, hh:mm a').format(dateTime);
  }

  static String formatNumber(double value, {int decimalPlaces = 1}) {
    return value.toStringAsFixed(decimalPlaces);
  }
}
