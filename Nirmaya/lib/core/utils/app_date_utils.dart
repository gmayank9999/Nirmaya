import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static const _istOffset = Duration(hours: 5, minutes: 30);
  static final _displayFormat = DateFormat('dd MMM yyyy');
  static final _displayShort = DateFormat('dd MMM');
  static final _fullFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _monthYear = DateFormat('MMM yyyy');
  static final _currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');

  static String formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = _parseBackendDateToIst(isoDate);
      return _displayFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatShortDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = _parseBackendDateToIst(isoDate);
      return _displayShort.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String formatDateTime(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = _parseBackendDateToIst(isoDate);
      return _fullFormat.format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  static String toApiDate(DateTime dt) {
    final istMidnightAsUtc =
        DateTime.utc(dt.year, dt.month, dt.day).subtract(_istOffset);
    return istMidnightAsUtc.toIso8601String();
  }

  static String formatMonthYear(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return _monthYear.format(_parseBackendDateToIst(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  static String formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final parsed = double.tryParse(amount.toString()) ?? 0;
    return '₹${_currencyFormat.format(parsed)}';
  }

  static bool isOverdue(String? isoDate) {
    if (isoDate == null) return false;
    try {
      return _parseBackendDateToIst(isoDate).isBefore(_nowIst());
    } catch (_) {
      return false;
    }
  }

  static String timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = _parseBackendDateToIst(isoDate);
      final diff = _nowIst().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return _displayFormat.format(dt);
    } catch (_) {
      return '';
    }
  }

  static DateTime _parseBackendDateToIst(String isoDate) {
    final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateOnly.hasMatch(isoDate)) {
      final parts = isoDate.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    }
    return DateTime.parse(isoDate).toUtc().add(_istOffset);
  }

  static DateTime _nowIst() => DateTime.now().toUtc().add(_istOffset);
}
