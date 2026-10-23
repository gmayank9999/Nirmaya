import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/patient_card.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _searchCtrl = TextEditingController();
  final _pendingAmountCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;
  String? _gender;
  bool? _hasIdProof;
  bool? _hasCghs;
  bool? _hasEchs;
  double? _minPending;
  bool _highestPendingFirst = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetFiltersAndReload();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _pendingAmountCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      context.read<PatientProvider>().loadMore();
    }
  }

  Future<void> _openPatientRoute(String route) async {
    await context.push(route);
    if (mounted) await _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patients',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: 'Filter Patients',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPatientRoute('/add-patient'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _applyFilters();
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  hintStyle:
                      const TextStyle(color: AppColors.textLight, fontSize: 15),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            _applyFilters();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_minPending != null || _highestPendingFirst)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_minPending != null)
                      Chip(
                          label: Text(_minPending == 0
                              ? 'Any pending payment'
                              : 'Pending above ${AppDateUtils.formatCurrency(_minPending)}')),
                    if (_highestPendingFirst)
                      const Chip(label: Text('Highest pending first')),
                  ],
                ),
              ),
            ),
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_activeFilterCount filter(s) applied',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.isLoading && provider.patients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null && provider.patients.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error loading patients: ${provider.error}\n\nPlease try again.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      )
                    : provider.patients.isEmpty
                        ? EmptyStateWidget(
                            title: 'No patients found',
                            subtitle: _searchCtrl.text.trim().isNotEmpty ||
                                    _activeFilterCount > 0
                                ? 'Try a different search or clear your filters'
                                : 'Add your first patient to get started',
                            icon: Icons.people_outline,
                            action: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Patient'),
                              onPressed: () =>
                                  _openPatientRoute('/add-patient'),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _applyFilters,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  16, 4, 16, 88), // Extra padding for FAB
                              itemCount: provider.patients.length +
                                  (provider.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                if (i == provider.patients.length) {
                                  if (!provider.isLoadingMore) {
                                    return TextButton(
                                      onPressed: provider.loadMore,
                                      child: Text(provider.error != null
                                          ? 'Retry loading more patients'
                                          : 'Load more patients'),
                                    );
                                  }
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return PatientCard(
                                  patient: provider.patients[i],
                                  onTap: () => _openPatientRoute(
                                      '/patients/${provider.patients[i].id}'),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount =>
      [_gender, _hasIdProof, _hasCghs, _hasEchs, _minPending]
          .where((v) => v != null)
          .length +
      (_highestPendingFirst ? 1 : 0);

  Future<void> _applyFilters() {
    _debounce?.cancel();
    return context.read<PatientProvider>().loadPatients(
          search: _searchCtrl.text.trim(),
          gender: _gender,
          hasIdProof: _hasIdProof,
          hasCghs: _hasCghs,
          hasEchs: _hasEchs,
          minPending: _minPending,
          highestPendingFirst: _highestPendingFirst,
          refresh: true,
          filtersChanged: true,
        );
  }

  void _clearFilters() {
    setState(() {
      _gender = null;
      _hasIdProof = null;
      _hasCghs = null;
      _hasEchs = null;
      _minPending = null;
      _highestPendingFirst = false;
    });
    _applyFilters();
  }

  void _resetFiltersAndReload() {
    if (_searchCtrl.text.isNotEmpty) {
      _searchCtrl.clear();
    }
    setState(() {
      _gender = null;
      _hasIdProof = null;
      _hasCghs = null;
      _hasEchs = null;
      _minPending = null;
      _highestPendingFirst = false;
    });
    _applyFilters();
  }

  Future<void> _showFilters() async {
    var gender = _gender;
    var hasIdProof = _hasIdProof;
    var hasCghs = _hasCghs;
    var hasEchs = _hasEchs;
    var paymentFilter = _minPending == null
        ? 'all'
        : _minPending == 0
            ? 'pending'
            : 'above';
    var highestPendingFirst = _highestPendingFirst;
    final amountController = _pendingAmountCtrl;
    amountController.text = _minPending != null && _minPending! > 0
        ? _minPending!.toStringAsFixed(2)
        : '';
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('payment-filter'),
                      initialValue: paymentFilter,
                      decoration:
                          const InputDecoration(labelText: 'Pending payment'),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All patients')),
                        DropdownMenuItem(
                            value: 'pending',
                            child: Text('Any pending payment')),
                        DropdownMenuItem(
                            value: 'above',
                            child: Text('Pending above amount')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => paymentFilter = value!),
                    ),
                    if (paymentFilter == 'above') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('pending-threshold'),
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Pending above',
                          prefixText: '₹ ',
                          helperText: 'Only amounts greater than this value',
                        ),
                        validator: (value) {
                          if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$')
                              .hasMatch(value?.trim() ?? '')) {
                            return 'Enter a valid amount (up to 2 decimals)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final amount in [5000, 10000, 25000])
                            ActionChip(
                              label: Text(AppDateUtils.formatCurrency(amount)),
                              onPressed: () {
                                amountController.text = '$amount';
                              },
                            ),
                        ],
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Highest pending first'),
                      value: highestPendingFirst,
                      onChanged: (value) =>
                          setSheetState(() => highestPendingFirst = value),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem<String>(
                            value: null, child: Text('Any gender')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setSheetState(() => gender = v),
                    ),
                    const SizedBox(height: 12),
                    _BoolFilter(
                      label: 'ID proof',
                      value: hasIdProof,
                      onChanged: (v) => setSheetState(() => hasIdProof = v),
                    ),
                    _BoolFilter(
                      label: 'CGHS',
                      value: hasCghs,
                      onChanged: (v) => setSheetState(() => hasCghs = v),
                    ),
                    _BoolFilter(
                      label: 'ECHS',
                      value: hasEchs,
                      onChanged: (v) => setSheetState(() => hasEchs = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          setState(() {
                            _gender = gender;
                            _hasIdProof = hasIdProof;
                            _hasCghs = hasCghs;
                            _hasEchs = hasEchs;
                            _minPending = paymentFilter == 'all'
                                ? null
                                : paymentFilter == 'pending'
                                    ? 0
                                    : double.parse(
                                        amountController.text.trim());
                            _highestPendingFirst = highestPendingFirst;
                          });
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BoolFilter extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _BoolFilter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = value == null ? 'any' : (value! ? 'yes' : 'no');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'any', label: Text(label)),
          const ButtonSegment(value: 'yes', label: Text('Yes')),
          const ButtonSegment(value: 'no', label: Text('No')),
        ],
        selected: {selectedValue},
        onSelectionChanged: (selection) {
          final selected = selection.first;
          onChanged(selected == 'any' ? null : selected == 'yes');
        },
        showSelectedIcon: false,
      ),
    );
  }
}
