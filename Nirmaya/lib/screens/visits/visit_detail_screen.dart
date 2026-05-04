import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/visit_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state_widget.dart';

class VisitDetailScreen extends StatefulWidget {
  final String visitId;
  const VisitDetailScreen({super.key, required this.visitId});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().loadVisitDetail(widget.visitId);
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitProvider>();
    final data = provider.selectedVisitDetail;
    final visit = data?['visit'] as Map<String, dynamic>?;
    final treatment = data?['treatment'] as Map<String, dynamic>?;
    final patient = data?['patient'] as Map<String, dynamic>?;
    final documents = data?['documents'] as List<dynamic>? ?? const [];
    final transactions = data?['transactions'] as List<dynamic>? ?? const [];
    final payment = data?['paymentSummary'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Visit Details')),
      body: provider.isLoading && data == null
          ? const Center(child: CircularProgressIndicator())
          : visit == null
              ? const EmptyStateWidget(
                  title: 'Visit not found',
                  icon: Icons.event_busy_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => context
                      .read<VisitProvider>()
                      .loadVisitDetail(widget.visitId),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _InfoCard(
                        title: AppDateUtils.formatDateWithOptionalTime(
                            visit['visitDate']?.toString()),
                        subtitle:
                            treatment?['title']?.toString() ?? 'Treatment',
                        trailing: patient?['name']?.toString(),
                      ),
                      if ((visit['notes']?.toString().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 12),
                        _TextCard(
                            title: 'Notes', text: visit['notes'].toString()),
                      ],
                      if (payment != null && treatment != null) ...[
                        const SizedBox(height: 12),
                        BalanceCard(
                          finalFee: double.tryParse(
                                  '${payment['treatmentFinalFee']}') ??
                              0,
                          paidAmount: double.tryParse(
                                  '${payment['treatmentPaidAmount']}') ??
                              0,
                          balance: double.tryParse(
                                  '${payment['treatmentBalance']}') ??
                              0,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionTitle('Payments'),
                      if (transactions.isEmpty)
                        const _MutedText('No payment linked to this visit')
                      else
                        ...transactions.map((tx) {
                          final item = tx as Map<String, dynamic>;
                          return _ListTileCard(
                            icon: Icons.currency_rupee,
                            title: AppDateUtils.formatCurrency(item['amount']),
                            subtitle:
                                '${item['paymentMode'] ?? '-'} · ${AppDateUtils.formatDateTime(item['createdAt']?.toString())}',
                          );
                        }),
                      const SizedBox(height: 20),
                      _SectionTitle('Reports & Prescriptions'),
                      if (documents.isEmpty)
                        const _MutedText('No reports or prescriptions uploaded')
                      else
                        ...documents.map((doc) {
                          final item = doc as Map<String, dynamic>;
                          return _ListTileCard(
                            icon: Icons.description_outlined,
                            title: item['name']?.toString() ??
                                item['fileName']?.toString() ??
                                item['category']?.toString() ??
                                'Document',
                            subtitle: item['category']?.toString() ?? '',
                            onTap: () =>
                                _openUrl(item['fileUrl']?.toString() ?? ''),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  const _InfoCard({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String title;
  final String text;
  const _TextCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ListTileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.open_in_new),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;
  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
