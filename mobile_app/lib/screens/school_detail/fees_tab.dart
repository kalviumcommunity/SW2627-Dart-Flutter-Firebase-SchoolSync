import 'package:flutter/material.dart';
import '../../models/fee_period_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/fee_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/firebase_error_view.dart';
import '../../widgets/school_detail/attendance_gauge.dart';
import '../../widgets/school_detail/section_header.dart';

/// Fees tab shown inside SchoolDetailScreen.
/// Displays fee collection rate via gauge, collected vs pending amounts,
/// and a scrollable history of all fee periods.
class FeesTab extends StatefulWidget {
  final SchoolDashboardData schoolData;

  const FeesTab({super.key, required this.schoolData});

  @override
  State<FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<FeesTab> {
  final FeeService _service = FeeService();
  late Future<List<FeePeriodModel>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        _service.getSchoolFeePeriods(widget.schoolData.school.schoolId);
  }

  FeePeriodModel? _activePeriod(List<FeePeriodModel> periods) {
    if (periods.isEmpty) return null;
    final active = periods.where((p) => p.status == 'active');
    if (active.isNotEmpty) return active.first;
    return periods.first; // latest by createdAt (already ordered desc)
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(2)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _showUpdateFeeDialog(FeePeriodModel active) async {
    final schoolId = widget.schoolData.school.schoolId;
    final submittedController =
        TextEditingController(text: active.totalSubmitted.toStringAsFixed(0));
    final pendingController =
        TextEditingController(text: active.pendingAmount.toStringAsFixed(0));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Fees for ${widget.schoolData.school.name}',
          style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: submittedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Collected / Submitted (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pendingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pending Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
            ),
            onPressed: () async {
              final submitted = double.tryParse(submittedController.text.trim()) ?? 0.0;
              final pending = double.tryParse(pendingController.text.trim()) ?? 0.0;
              if (submitted >= 0 && pending >= 0) {
                Navigator.pop(ctx);
                await _service.updateFeePeriod(
                  schoolId: schoolId,
                  feePeriodId: active.periodId,
                  totalSubmitted: submitted,
                  pendingAmount: pending,
                );
                if (mounted) {
                  setState(() {
                    _future = _service.getSchoolFeePeriods(schoolId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fees updated: Collected ${_formatCurrency(submitted)}, Pending ${_formatCurrency(pending)}!'),
                      backgroundColor: const Color(0xFF4A6741),
                    ),
                  );
                }
              }
            },
            child: const Text('Save to Firestore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeePeriodModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.text));
        }
        if (snapshot.hasError) {
          return FirebaseErrorView(
            title: 'Unable to Load Fee Records',
            message: snapshot.error.toString().replaceAll('Exception: ', ''),
            onRetry: () => setState(() => _future = _service.getSchoolFeePeriods(widget.schoolData.school.schoolId)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No fee records found in Cloud Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.secondaryText, fontSize: 14),
              ),
            ),
          );
        }

        final periods = snapshot.data!;
        final active = _activePeriod(periods)!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Active period gauge card ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2DCCE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AttendanceGauge(
                      percentage: active.submissionRate,
                      fillColor: const Color(0xFF4A6741),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${active.submissionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fee Submission Rate',
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Collected vs Pending tiles
                    Row(
                      children: [
                        _StatTile(
                          label: 'Collected',
                          value: _formatCurrency(active.totalSubmitted),
                          color: const Color(0xFF4A6741),
                          bgColor: const Color(0xFFE8F0E5),
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Pending',
                          value: _formatCurrency(active.pendingAmount),
                          color: const Color(0xFFC98591),
                          bgColor: const Color(0xFFFAEAED),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Update Fee Collection Button
                    ElevatedButton.icon(
                      onPressed: () => _showUpdateFeeDialog(active),
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Update Fee Collection',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── All periods list ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2DCCE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(text: 'All Fee Periods'),
                    const SizedBox(height: 12),
                    ...periods.map(
                      (p) => _FeePeriodRow(
                          period: p, formatCurrency: _formatCurrency),
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color.withAlpha(180),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeePeriodRow extends StatelessWidget {
  final FeePeriodModel period;
  final String Function(double) formatCurrency;

  const _FeePeriodRow(
      {required this.period, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    final isActive = period.status == 'active';
    final statusColor =
        isActive ? const Color(0xFF4A6741) : AppColors.secondaryText;
    final statusBg =
        isActive ? const Color(0xFFE8F0E5) : const Color(0xFFF0EDE8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.createdAt.year.toString(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrency(period.totalSubmitted)} / ${formatCurrency(period.totalDue)}',
                  style: const TextStyle(
                      color: AppColors.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              period.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
