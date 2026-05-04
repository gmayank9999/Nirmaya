import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/installment_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
            // Tab(text: 'Installments'),
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
                            paidAmount: treatment.paidAmountDouble,
                            balance: treatment.balanceDouble,
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
                          _InstallmentsTab(treatmentId: widget.treatmentId),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: treatment != null
          ? FloatingActionButton(
              onPressed: () {
                final tab = _tabCtrl.index;
                if (tab == 0) {
                  context.push('/add-visit', extra: {
                    'treatmentId': treatment.id,
                    'treatmentTitle': treatment.title,
                    'remainingAmount': treatment.balanceDouble,
                  });
                } else if (tab == 1) {
                  context.push('/add-transaction', extra: {
                    'treatmentId': treatment.id,
                    'patientId': treatment.patientId,
                    'treatmentTitle': treatment.title,
                  });
                } else if (tab == 3) {
                  context.push('/add-installment', extra: {
                    'treatmentId': treatment.id,
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

class _VisitsTab extends StatelessWidget {
  final String treatmentId;
  const _VisitsTab({required this.treatmentId});

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
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final v = visits[i];
        return InkWell(
          onTap: () => context.push('/visits/${v.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                        AppDateUtils.formatDateWithOptionalTime(v.visitDate),
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
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final String treatmentId;
  final dynamic treatment;
  const _PaymentsTab({required this.treatmentId, required this.treatment});

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
            'treatmentId': treatment.id,
            'patientId': treatment.patientId ?? '',
            'treatmentTitle': treatment.treatmentTitle,
          }),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = transactions[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_rupee,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.formatCurrency(t.amountDouble),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      '${t.paymentModeDisplay} · ${AppDateUtils.formatDateWithOptionalTime(t.transactionDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
