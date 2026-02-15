/// DateTime extensions for date manipulation and formatting
extension DateTimeExtensions on DateTime {
  /// Get the start of the day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get the end of the day (23:59:59.999)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get the start of the week (Monday at 00:00:00)
  DateTime get startOfWeek {
    final daysFromMonday = weekday - DateTime.monday;
    return subtract(Duration(days: daysFromMonday)).startOfDay;
  }

  /// Get the end of the week (Sunday at 23:59:59.999)
  DateTime get endOfWeek {
    final daysToSunday = DateTime.sunday - weekday;
    return add(Duration(days: daysToSunday)).endOfDay;
  }

  /// Get the start of the month (1st day at 00:00:00)
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Get the end of the month (last day at 23:59:59.999)
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Check if this date is on the same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Format date as dd/MM
  String formatShort() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';
  }

  /// Format date as dd/MM/yyyy
  String formatFull() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Format date as YYYY-MM-DD for consistent map keys
  String toDateKey() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
