import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  final _repo = AppointmentRepository();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  String? _error;

  // Remembered so the calendar can reload after create/update.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _doctorId;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get month => _month;
  String? get doctorId => _doctorId;

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Appointments on [day] (local calendar date), earliest first.
  List<AppointmentModel> forDay(DateTime day) {
    final key = _fmt(day);
    return _appointments.where((a) => a.appointmentDate == key).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Number of still-scheduled appointments on [day].
  int pendingCount(DateTime day) =>
      forDay(day).where((a) => a.isScheduled).length;

  /// Loads the month containing [month] (or the current one). Pass
  /// [keepDoctor] to reload without touching the doctor filter.
  Future<void> load({
    DateTime? month,
    String? doctorId,
    bool keepDoctor = false,
  }) async {
    if (month != null) _month = DateTime(month.year, month.month);
    if (!keepDoctor) _doctorId = doctorId;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _appointments = await _repo.list(
        doctorId: _doctorId,
        from: _fmt(DateTime(_month.year, _month.month, 1)),
        to: _fmt(DateTime(_month.year, _month.month + 1, 0)),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> body) =>
      _mutate(() => _repo.create(body));

  Future<bool> update(String id, Map<String, dynamic> body) =>
      _mutate(() => _repo.update(id, body));

  Future<bool> _mutate(Future<AppointmentModel> Function() action) async {
    _error = null;
    try {
      await action();
      await load(keepDoctor: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
