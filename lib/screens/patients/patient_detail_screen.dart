import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/followup_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_chip.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    // ── STALE STATE FIX ──────────────────────────────────────────────────────
    // Clear ALL providers synchronously so the screen never renders any
    // previous patient's data. Loading spinners show until fresh data arrives.
    context.read<PatientProvider>().clearSelected();
    context.read<TreatmentProvider>().clearSelected();
    // ─────────────────────────────────────────────────────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<PatientProvider>().loadPatient(widget.patientId);
    context.read<TreatmentProvider>().loadTreatments(
          patientId: widget.patientId,
          refresh: true,
        );
    context.read<FollowupProvider>().loadFollowups(patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final treatmentProvider = context.watch<TreatmentProvider>();
    final patient = patientProvider.selectedPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient?.name ?? 'Patient'),
        actions: [
          if (patient != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/add-patient', extra: patient),
            ),
        ],
      ),
      body: patientProvider.isLoading && patient == null
          ? const Center(child: CircularProgressIndicator())
          : patient == null
              ? const EmptyStateWidget(
                  title: 'Patient not found', icon: Icons.person_off)
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Profile card ─────────────────────────────────────
                      _ProfileCard(patient: patient),
                      const SizedBox(height: 14),

                      // ── Documents section (only if any doc exists) ────────
                      if (patient.hasIdProof ||
                          patient.hasCghs ||
                          patient.hasEchs) ...[
                        _DocumentsSection(patient: patient),
                        const SizedBox(height: 14),
                      ],

                      // ── Treatments ───────────────────────────────────────
                      _SectionHeader(
                        title: 'Treatments',
                        action: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: () =>
                              context.push('/add-treatment', extra: {
                            'patientId': patient.id,
                            'patientName': patient.name,
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (treatmentProvider.isLoading &&
                          treatmentProvider.treatments.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (treatmentProvider.treatments.isEmpty)
                        EmptyStateWidget(
                          title: 'No treatments yet',
                          icon: Icons.medical_services_outlined,
                          action: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Treatment'),
                            onPressed: () =>
                                context.push('/add-treatment', extra: {
                              'patientId': patient.id,
                              'patientName': patient.name,
                            }),
                          ),
                        )
                      else
                        ...treatmentProvider.treatments.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TreatmentTile(
                                title: t.title,
                                status: t.status,
                                finalFee: t.finalFee,
                                balance: t.balanceDouble,
                                onTap: () =>
                                    context.push('/treatments/${t.id}'),
                              ),
                            )),
                      const SizedBox(height: 90), // FAB clearance
                    ],
                  ),
                ),
      floatingActionButton: patient != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-treatment', extra: {
                'patientId': patient.id,
                'patientName': patient.name,
              }),
              icon: const Icon(Icons.add),
              label: const Text('Add Treatment'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final PatientModel patient;
  const _ProfileCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    // Short patient ID for display: first 8 chars of UUID
    final shortId = patient.id.length >= 8 ? patient.id.substring(0, 8) : patient.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top gradient banner + avatar ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      patient.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            patient.phone,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      if (patient.email != null &&
                          patient.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                patient.email!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Info chips pulled up over the banner ─────────────────────────
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoChip(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: patient.age != null
                          ? '${patient.age} yrs'
                          : '—',
                    ),
                    _Divider(),
                    _InfoChip(
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: patient.gender != null
                          ? patient.genderDisplay
                          : '—',
                    ),
                    _Divider(),
                    _InfoChip(
                      icon: Icons.tag_outlined,
                      label: 'Patient ID',
                      value: shortId.toUpperCase(),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: patient.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Patient ID copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 2),
            const Icon(Icons.copy_outlined,
                size: 10, color: AppColors.textLight),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFEEEEEE),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Documents Section
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentsSection extends StatelessWidget {
  final PatientModel patient;
  const _DocumentsSection({required this.patient});

  @override
  Widget build(BuildContext context) {
    final docs = <_DocEntry>[
      if (patient.hasIdProof)
        _DocEntry(
          label: 'ID Proof',
          icon: Icons.badge_outlined,
          url: patient.idProofFileUrl,
        ),
      if (patient.hasCghs)
        _DocEntry(
          label: 'CGHS',
          icon: Icons.local_hospital_outlined,
          url: patient.cghsFileUrl,
        ),
      if (patient.hasEchs)
        _DocEntry(
          label: 'ECHS',
          icon: Icons.military_tech_outlined,
          url: patient.echsFileUrl,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_outlined,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...docs.map((doc) => _DocTile(doc: doc)),
        ],
      ),
    );
  }
}

class _DocEntry {
  final String label;
  final IconData icon;
  final String? url;
  const _DocEntry({required this.label, required this.icon, this.url});
}

class _DocTile extends StatelessWidget {
  final _DocEntry doc;
  const _DocTile({required this.doc});

  Future<void> _open(BuildContext context) async {
    if (doc.url == null || doc.url!.isEmpty) return;
    final uri = Uri.parse(doc.url!);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document. No app found to handle this URL.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = doc.url != null && doc.url!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: hasUrl ? () => _open(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUrl
                    ? AppColors.success.withValues(alpha: 0.3)
                    : const Color(0xFFEEEEEE),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    doc.icon,
                    size: 18,
                    color: hasUrl ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        hasUrl ? 'Tap to view' : 'Uploaded (no URL)',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUrl
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasUrl)
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Treatment Tile
// ─────────────────────────────────────────────────────────────────────────────
class _TreatmentTile extends StatelessWidget {
  final String title;
  final String status;
  final double finalFee;
  final double balance;
  final VoidCallback onTap;

  const _TreatmentTile({
    required this.title,
    required this.status,
    required this.finalFee,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusChip.treatmentStatus(status),
                      const SizedBox(width: 8),
                      Text(
                        'Fee: ${AppDateUtils.formatCurrency(finalFee)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bal: ${AppDateUtils.formatCurrency(balance)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: balance > 0 ? AppColors.warning : AppColors.success,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
