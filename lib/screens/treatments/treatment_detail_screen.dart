import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/installment_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/visit_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_chip.dart';

class TreatmentDetailScreen extends StatefulWidget {
  final String treatmentId;
  const TreatmentDetailScreen({super.key, required this.treatmentId});

  @override
  State<TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<TreatmentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _tabIndex = _tabCtrl.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<TreatmentProvider>().loadTreatmentDetail(widget.treatmentId);
    context
        .read<InstallmentProvider>()
        .loadInstallments(treatmentId: widget.treatmentId);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TreatmentProvider>();
    final treatment = tp.selectedTreatment;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(treatment?.title ?? 'Treatment'),
        actions: [
          if (treatment != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/add-treatment', extra: {
                'patientId': treatment.patientId,
                'patientName': '',
                'editTreatment': treatment,
              }),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white, 
          unselectedLabelColor: Colors.white70, 
          tabs: const [
            Tab(text: 'Visits'),
            Tab(text: 'Payments'),
            Tab(text: 'Docs'),
          ],
        ),
      ),
      body: tp.isLoading && treatment == null
          ? const Center(child: CircularProgressIndicator())
          : treatment == null
              ? const EmptyStateWidget(
                  title: 'Treatment not found',
                  icon: Icons.medical_services_outlined)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          BalanceCard(
                            finalFee: treatment.finalFee,
                            paidAmount: tp.paidAmount,
                            balance: tp.balance,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              StatusChip.treatmentStatus(treatment.status),
                              const SizedBox(width: 8),
                              Text(
                                'Started: ${AppDateUtils.formatDate(treatment.startDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _VisitsTab(treatmentId: widget.treatmentId),
                          _PaymentsTab(
                              treatmentId: widget.treatmentId,
                              treatment: treatment),
                          const _DocumentsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      // Hide FAB on Docs tab (index 2) since docs are linked to visits
      floatingActionButton: treatment != null && _tabIndex != 2
          ? FloatingActionButton(
              onPressed: () {
                if (_tabIndex == 0) {
                  context.push('/add-visit', extra: {
                    'treatmentId': treatment.id,
                    'treatmentTitle': treatment.title,
                    'remainingAmount': treatment.balanceDouble,
                  });
                } else if (_tabIndex == 1) {
                  context.push('/add-transaction', extra: {
                    'treatmentId': treatment.id,
                    'patientId': treatment.patientId,
                    'treatmentTitle': treatment.title,
                  });
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _VisitsTab extends StatefulWidget {
  final String treatmentId;
  const _VisitsTab({required this.treatmentId});

  @override
  State<_VisitsTab> createState() => _VisitsTabState();
}

class _VisitsTabState extends State<_VisitsTab> {
  Future<void> _deleteVisit(String id, String dateStr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Visit?'),
        content: Text('Remove the visit on $dateStr? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context.read<TreatmentProvider>().removeVisitFromDetail(id);
    context.read<VisitProvider>().deleteVisit(id);
  }

  @override
  Widget build(BuildContext context) {
    final visits = context.watch<TreatmentProvider>().treatmentVisits;

    if (visits.isEmpty) {
      return EmptyStateWidget(
        title: 'No visits yet',
        icon: Icons.event_outlined,
        action: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Visit'),
          onPressed: () {
            final t = context.read<TreatmentProvider>().selectedTreatment;
            if (t != null) {
              context.push('/add-visit', extra: {
                'treatmentId': t.id,
                'treatmentTitle': t.title,
                'remainingAmount': t.balanceDouble,
              });
            }
          },
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final v = visits[i];
        final dateStr = AppDateUtils.formatDateWithOptionalTime(v.visitDate);
        return Dismissible(
          key: Key(v.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            await _deleteVisit(v.id, dateStr);
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
          ),
          child: InkWell(
            onTap: () => context.push('/visits/${v.id}'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (v.notes != null && v.notes!.isNotEmpty)
                          Text(
                            v.notes!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends StatefulWidget {
  final String treatmentId;
  final dynamic treatment;
  const _PaymentsTab({required this.treatmentId, required this.treatment});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final Set<String> _selected = {};
  bool get _isSelecting => _selected.isNotEmpty;

  void _toggleSelect(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      });

  void _clearSelection() => setState(() => _selected.clear());

  Future<void> _deleteSingle(String txId, String amountStr) async {
    final ok = await _confirmDelete(
      context,
      'Remove the $amountStr payment? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    context.read<TreatmentProvider>().removeTransactionFromDetail(txId);
    context.read<TransactionProvider>().deleteTransaction(txId);
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final ok = await _confirmDelete(
      context,
      'Delete $count payment${count > 1 ? 's' : ''}? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    final ids = List<String>.from(_selected);
    final tp = context.read<TreatmentProvider>();
    final txp = context.read<TransactionProvider>();
    for (final id in ids) {
      tp.removeTransactionFromDetail(id);
      txp.deleteTransaction(id);
    }
    _clearSelection();
  }

  Future<bool> _confirmDelete(BuildContext ctx, String message) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (d) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Payment?'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final transactions =
        context.watch<TreatmentProvider>().treatmentTransactions;

    if (transactions.isEmpty) {
      return EmptyStateWidget(
        title: 'No payments yet',
        icon: Icons.payments_outlined,
        action: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Record Payment'),
          onPressed: () => context.push('/add-transaction', extra: {
            'treatmentId': widget.treatment.id,
            'patientId': widget.treatment.patientId ?? '',
            'treatmentTitle': widget.treatment.title ?? '',
          }),
        ),
      );
    }

    return Stack(
      children: [
        // ── Payment list ─────────────────────────────────────────────────
        ListView.separated(
          padding: EdgeInsets.fromLTRB(
              16, _isSelecting ? 48 : 16, 16, _isSelecting ? 100 : 88),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = transactions[i];
            final amountStr = AppDateUtils.formatCurrency(t.amountDouble);
            final isSelected = _selected.contains(t.id);

            return GestureDetector(
              onLongPress: () => _toggleSelect(t.id),
              onTap: _isSelecting ? () => _toggleSelect(t.id) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Dismissible(
                  key: Key(t.id),
                  direction: _isSelecting
                      ? DismissDirection.none
                      : DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _deleteSingle(t.id, amountStr);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Rupee icon or animated checkbox
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: _isSelecting
                              ? Container(
                                  key: const ValueKey('cb'),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFD1D5DB),
                                    ),
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check
                                        : Icons.check_box_outline_blank,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textLight,
                                    size: 20,
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('rupee'),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.currency_rupee,
                                      color: AppColors.success, size: 22),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                amountStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${t.paymentModeDisplay} · ${AppDateUtils.formatDateTime(t.transactionDate)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              if (t.notes != null && t.notes!.isNotEmpty)
                                Text(
                                  t.notes!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Edit button (hidden in selection mode)
                        if (!_isSelecting)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textSecondary),
                            onPressed: () => context.push(
                              '/add-transaction',
                              extra: {
                                'treatmentId': widget.treatmentId,
                                'patientId':
                                    widget.treatment.patientId ?? '',
                                'treatmentTitle':
                                    widget.treatment.title ?? '',
                                'editTransaction': t,
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // ── Top hint badge (shows count + X to cancel) ───────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          top: _isSelecting ? 8 : -48,
          right: 16,
          child: GestureDetector(
            onTap: _clearSelection,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '${_selected.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom delete action bar ──────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          bottom: _isSelecting ? 0 : -100,
          left: 0,
          right: 0,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textSecondary),
                    onPressed: _clearSelection,
                    tooltip: 'Cancel selection',
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_selected.length} payment${_selected.length > 1 ? 's' : ''} selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete',
                        style:
                            TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _DocumentsTab extends StatelessWidget {
  const _DocumentsTab();

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<TreatmentProvider>().treatmentDocuments;

    if (documents.isEmpty) {
      return const EmptyStateWidget(
        title: 'No documents yet',
        icon: Icons.description_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final doc = documents[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            onTap: () => _open(doc.fileUrl),
            leading: const Icon(Icons.description_outlined,
                color: AppColors.primary),
            title: Text(
              (doc.name?.trim().isNotEmpty ?? false)
                  ? doc.name!
                  : (doc.fileName.isEmpty ? doc.categoryDisplay : doc.fileName),
            ),
            subtitle: Text('${doc.categoryDisplay} · ${doc.fileSizeDisplay}'),
            trailing: const Icon(Icons.open_in_new),
          ),
        );
      },
    );
  }
}

// ignore: unused_element — kept for future Installments tab re-enable
class _InstallmentsTab extends StatelessWidget {
  final String treatmentId;
  const _InstallmentsTab({required this.treatmentId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstallmentProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.installments.isEmpty) {
      return EmptyStateWidget(
        title: 'No installment plan',
        icon: Icons.calendar_today_outlined,
        action: TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Create Plan'),
          onPressed: () {
            final t = context.read<TreatmentProvider>().selectedTreatment;
            if (t != null) {
              context.push('/add-installment', extra: {
                'treatmentId': t.id,
                'treatmentTitle': t.title,
              });
            }
          },
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.installments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final inst = provider.installments[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installment ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Due: ${AppDateUtils.formatDate(inst.dueDate)} · ${AppDateUtils.formatCurrency(inst.installmentAmountDouble)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip.installmentStatus(inst.status),
              if (inst.status == 'pending') ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      context.read<InstallmentProvider>().markAsPaid(inst.id),
                  child: const Text('Mark Paid'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
