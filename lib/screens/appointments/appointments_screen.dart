import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_chip.dart';

/// Month calendar of appointments, filterable by doctor, with the selected
/// day's schedule underneath. Opens on today.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late DateTime _selected = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadDoctors();
      context.read<AppointmentProvider>().load(month: _selected);
    });
  }

  void _changeMonth(int delta) {
    final m = context.read<AppointmentProvider>().month;
    final next = DateTime(m.year, m.month + delta);
    setState(() => _selected = DateTime(next.year, next.month,
        (next.year == DateTime.now().year && next.month == DateTime.now().month)
            ? DateTime.now().day
            : 1));
    context.read<AppointmentProvider>().load(month: next, keepDoctor: true);
  }

  void _selectDoctor(String? id) {
    context.read<AppointmentProvider>().load(
          month: context.read<AppointmentProvider>().month,
          doctorId: id,
        );
  }

  Future<void> _book() async {
    await context.push('/add-appointment', extra: {
      'initialDate': _selected,
      'initialDoctorId': context.read<AppointmentProvider>().doctorId,
    });
  }

  Future<void> _setStatus(AppointmentModel a, String status) async {
    final provider = context.read<AppointmentProvider>();
    final ok = await provider.update(a.id, {'status': status});
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to update'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showActions(AppointmentModel a) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        Widget action(IconData icon, String label, VoidCallback onTap,
            {Color? color}) {
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(label, style: TextStyle(color: color)),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              onTap();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(a.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([
                  if (a.patientPhone?.isNotEmpty == true) a.patientPhone!,
                  if (a.reason?.isNotEmpty == true) a.reason!,
                ].join(' • ')),
              ),
              const Divider(height: 1),
              action(Icons.edit_calendar_outlined, 'Edit / Reschedule', () {
                context.push('/add-appointment', extra: {'edit': a});
              }),
              if (!a.isScheduled)
                action(Icons.restore, 'Mark as scheduled',
                    () => _setStatus(a, 'scheduled')),
              if (a.status != 'completed')
                action(Icons.check_circle_outline, 'Mark completed',
                    () => _setStatus(a, 'completed'),
                    color: AppColors.success),
              if (a.status != 'no_show')
                action(Icons.person_off_outlined, 'Mark no-show',
                    () => _setStatus(a, 'no_show'),
                    color: AppColors.warning),
              if (a.status != 'cancelled')
                action(Icons.cancel_outlined, 'Cancel appointment',
                    () => _setStatus(a, 'cancelled'),
                    color: AppColors.error),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final doctors = context.watch<DoctorProvider>().activeDoctors;
    final dayItems = provider.forDay(_selected);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Appointments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _book,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: Column(
        children: [
          if (doctors.length > 1)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _DoctorChip(
                    label: 'All doctors',
                    selected: provider.doctorId == null,
                    onTap: () => _selectDoctor(null),
                  ),
                  for (final d in doctors)
                    _DoctorChip(
                      label: d.name,
                      selected: provider.doctorId == d.id,
                      onTap: () => _selectDoctor(d.id),
                    ),
                ],
              ),
            ),
          _MonthGrid(
            month: provider.month,
            selected: _selected,
            countFor: provider.pendingCount,
            onSelect: (d) => setState(() => _selected = d),
            onPrev: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(_selected),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text('${dayItems.where((a) => a.isScheduled).length} scheduled',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.appointments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : dayItems.isEmpty
                    ? const EmptyStateWidget(
                        title: 'No appointments',
                        subtitle: 'Nothing booked for this day',
                        icon: Icons.event_available_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.load(keepDoctor: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: dayItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _AppointmentTile(
                            appointment: dayItems[i],
                            showDoctor: doctors.length > 1,
                            onTap: () => _showActions(dayItems[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DoctorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DoctorChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final int Function(DateTime) countFor;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.countFor,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday-first
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              IconButton(
                  onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Row(
            children: [
              for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(child: _cell(r * 7 + c - leading + 1, daysInMonth, today)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, int daysInMonth, DateTime today) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);
    final date = DateTime(month.year, month.month, day);
    final isSelected = date == selected;
    final isToday = date == today;
    final count = countFor(date);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelect(date),
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : null,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primary)
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showDoctor;
  final VoidCallback onTap;
  const _AppointmentTile({
    required this.appointment,
    required this.showDoctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final dimmed = !a.isScheduled;
    final (color, bg) = switch (a.status) {
      'completed' => (AppColors.success, const Color(0xFFE8F5E9)),
      'cancelled' => (AppColors.error, const Color(0xFFFFEBEE)),
      'no_show' => (AppColors.warning, const Color(0xFFFFF3E0)),
      _ => (AppColors.info, const Color(0xFFE3F2FD)),
    };

    return Opacity(
      opacity: a.status == 'cancelled' ? 0.6 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Text(
                        a.time.format(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13),
                      ),
                      Text('${a.durationMinutes} min',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.textLight.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration:
                              dimmed && a.status == 'cancelled'
                                  ? TextDecoration.lineThrough
                                  : null,
                        ),
                      ),
                      if (showDoctor && a.doctorName != null)
                        Text(a.doctorName!,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      if (a.reason?.isNotEmpty == true)
                        Text(a.reason!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                StatusChip.custom(
                    label: a.statusDisplay, color: color, background: bg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
