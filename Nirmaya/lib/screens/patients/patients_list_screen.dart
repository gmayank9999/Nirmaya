import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/patient_card.dart';
import '../../router/route_observer.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen>
    with RouteAware {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _gender;
  bool? _hasIdProof;
  bool? _hasCghs;
  bool? _hasEchs;
  bool _isRouteSubscribed = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isRouteSubscribed) return;
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _resetFiltersAndReload();
  }

  @override
  void didPush() {
    _resetFiltersAndReload();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 100) {
      context.read<PatientProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/add-patient'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() {});
                context
                    .read<PatientProvider>()
                    .loadPatients(search: v, refresh: true);
              },
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context
                              .read<PatientProvider>()
                              .loadPatients(refresh: true);
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Text(
                    '$_activeFilterCount filter(s) applied',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
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
                : provider.patients.isEmpty
                    ? EmptyStateWidget(
                        title: 'No patients found',
                        subtitle: 'Add your first patient to get started',
                        icon: Icons.people_outline,
                        action: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Patient'),
                          onPressed: () => context.push('/add-patient'),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context
                            .read<PatientProvider>()
                            .loadPatients(refresh: true),
                        child: ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.patients.length +
                              (provider.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            if (i == provider.patients.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return PatientCard(patient: provider.patients[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount =>
      [_gender, _hasIdProof, _hasCghs, _hasEchs].where((v) => v != null).length;

  void _applyFilters() {
    context.read<PatientProvider>().loadPatients(
          search: _searchCtrl.text.trim(),
          gender: _gender,
          hasIdProof: _hasIdProof,
          hasCghs: _hasCghs,
          hasEchs: _hasEchs,
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
    });
    context.read<PatientProvider>().loadPatients(refresh: true);
  }

  Future<void> _showFilters() async {
    var gender = _gender;
    var hasIdProof = _hasIdProof;
    var hasCghs = _hasCghs;
    var hasEchs = _hasEchs;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
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
                        setState(() {
                          _gender = gender;
                          _hasIdProof = hasIdProof;
                          _hasCghs = hasCghs;
                          _hasEchs = hasEchs;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
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
