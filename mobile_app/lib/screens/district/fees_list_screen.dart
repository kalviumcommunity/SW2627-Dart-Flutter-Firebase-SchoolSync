import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/business_rules.dart';
import '../../widgets/district_summary_banner.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/school_search_bar.dart';
import '../school_detail_screen.dart';

enum FeesRateFilter { all, low, moderate, high }

enum FeesSortOption { highestRate, lowestRate, pendingAmount, collectedAmount, name }

class FeesListScreen extends StatefulWidget {
  final DistrictDashboardSummary summary;
  final VoidCallback? onRefresh;

  const FeesListScreen({
    super.key,
    required this.summary,
    this.onRefresh,
  });

  @override
  State<FeesListScreen> createState() => _FeesListScreenState();
}

class _FeesListScreenState extends State<FeesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  FeesRateFilter _rateFilter = FeesRateFilter.all;
  FeesSortOption _sortOption = FeesSortOption.highestRate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SchoolDashboardData> _getFilteredSchools() {
    final schools = widget.summary.schoolsData;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = schools.where((s) {
      // 1. Search query filter
      if (query.isNotEmpty) {
        final matchesName = s.school.name.toLowerCase().contains(query);
        final matchesId = s.school.schoolId.toLowerCase().contains(query);
        if (!matchesName && !matchesId) return false;
      }

      // 2. Fee rate filter using business rules
      final rate = s.feeSubmissionRate;
      final status = ThresholdRules.evaluateFees(rate);
      switch (_rateFilter) {
        case FeesRateFilter.all:
          return true;
        case FeesRateFilter.low:
          return status == KPIStatus.critical;
        case FeesRateFilter.moderate:
          return status == KPIStatus.warning;
        case FeesRateFilter.high:
          return status == KPIStatus.healthy;
      }
    }).toList();

    // 3. Sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case FeesSortOption.highestRate:
          return b.feeSubmissionRate.compareTo(a.feeSubmissionRate);
        case FeesSortOption.lowestRate:
          return a.feeSubmissionRate.compareTo(b.feeSubmissionRate);
        case FeesSortOption.pendingAmount:
          return b.feesPending.compareTo(a.feesPending);
        case FeesSortOption.collectedAmount:
          return b.feesCollected.compareTo(a.feesCollected);
        case FeesSortOption.name:
          return a.school.name.compareTo(b.school.name);
      }
    });

    return filtered;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final schools = widget.summary.schoolsData;
    final filteredSchools = _getFilteredSchools();

    final totalCollected = widget.summary.totalFeesCollected;
    final totalPending = widget.summary.totalFeesPending;
    final totalDue = totalCollected + totalPending;
    final districtRate = totalDue > 0 ? (totalCollected / totalDue) * 100.0 : 0.0;

    int lowCount = 0;
    int warningCount = 0;
    int highCount = 0;
    for (final s in schools) {
      final status = ThresholdRules.evaluateFees(s.feeSubmissionRate);
      if (status == KPIStatus.critical) lowCount++;
      if (status == KPIStatus.warning) warningCount++;
      if (status == KPIStatus.healthy) highCount++;
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ──────────────────────────────────────────
            const Text(
              'FINANCIAL OVERVIEW',
              style: TextStyle(
                color: Color(0xFFC7BDB3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'District Fee Collections',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            // ── District Summary Banner ────────────────────────────────
            DistrictSummaryBanner(
              title: 'District Fees Overview',
              metrics: [
                DistrictSummaryMetric(
                  label: 'Total Collected',
                  value: _formatCurrency(totalCollected),
                  subtitle: '${districtRate.toStringAsFixed(1)}% of total due',
                  valueColor: const Color(0xFF4A6741),
                  icon: Icons.check_circle_outline_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'Total Pending',
                  value: _formatCurrency(totalPending),
                  subtitle: '${schools.length} Schools reporting',
                  valueColor: const Color(0xFFC98591),
                  icon: Icons.pending_actions_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'Avg Collection',
                  value: '${districtRate.toStringAsFixed(0)}%',
                  subtitle: '$highCount Top Performing',
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Search Bar ──────────────────────────────────────────────
            SchoolSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (q) => setState(() => _searchQuery = q),
              hintText: 'Filter by school name or ID…',
            ),

            const SizedBox(height: 16),

            // ── Rate Filter Chips ───────────────────────────────────────
            FilterChipRow<FeesRateFilter>(
              items: [
                FilterChipItem(
                  value: FeesRateFilter.all,
                  label: 'All Schools',
                  count: schools.length,
                ),
                FilterChipItem(
                  value: FeesRateFilter.high,
                  label: 'Healthy (≥90%)',
                  icon: Icons.trending_up_rounded,
                  count: highCount,
                ),
                FilterChipItem(
                  value: FeesRateFilter.moderate,
                  label: 'Warning (75-89.9%)',
                  icon: Icons.warning_amber_rounded,
                  count: warningCount,
                ),
                FilterChipItem(
                  value: FeesRateFilter.low,
                  label: 'Critical (<75%)',
                  icon: Icons.error_outline_rounded,
                  count: lowCount,
                ),
              ],
              selectedValue: _rateFilter,
              onSelected: (val) => setState(() => _rateFilter = val),
            ),

            const SizedBox(height: 14),

            // ── Sort / Results Count Bar ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredSchools.length} OF ${schools.length} SCHOOLS',
                  style: const TextStyle(
                    color: Color(0xFFC7BDB3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                PopupMenuButton<FeesSortOption>(
                  initialValue: _sortOption,
                  onSelected: (val) => setState(() => _sortOption = val),
                  color: AppColors.card,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFDCD4C4), width: 1.5),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCD4C4), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.text, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          _getSortLabel(_sortOption),
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.text, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    _buildSortMenuItem(FeesSortOption.highestRate, 'Highest Collection Rate (%)'),
                    _buildSortMenuItem(FeesSortOption.lowestRate, 'Lowest Collection Rate (%)'),
                    _buildSortMenuItem(FeesSortOption.pendingAmount, 'Highest Pending Amount (₹)'),
                    _buildSortMenuItem(FeesSortOption.collectedAmount, 'Highest Collected Amount (₹)'),
                    _buildSortMenuItem(FeesSortOption.name, 'School Name (A-Z)'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── School Fee Cards List / Empty State ─────────────────────
            if (filteredSchools.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSchools.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final schoolData = filteredSchools[index];
                  return _FeesSchoolCard(
                    schoolData: schoolData,
                    formatCurrency: _formatCurrency,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SchoolDetailScreen(
                            schoolData: schoolData,
                            initialTabIndex: 1, // Fees tab
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(FeesSortOption opt) {
    switch (opt) {
      case FeesSortOption.highestRate:
        return 'Rate (High)';
      case FeesSortOption.lowestRate:
        return 'Rate (Low)';
      case FeesSortOption.pendingAmount:
        return 'Pending (₹)';
      case FeesSortOption.collectedAmount:
        return 'Collected (₹)';
      case FeesSortOption.name:
        return 'Name';
    }
  }

  PopupMenuItem<FeesSortOption> _buildSortMenuItem(
    FeesSortOption value,
    String label,
  ) {
    final isSelected = _sortOption == value;
    return PopupMenuItem<FeesSortOption>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            size: 16,
            color: isSelected ? const Color(0xFF6B472E) : const Color(0xFF8C847A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF22160E),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFFC7BDB3),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'No schools match the selected fee criteria',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your collection rate filter or search query.',
              style: TextStyle(
                color: Color(0xFFC7BDB3),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _rateFilter = FeesRateFilter.all;
                  _sortOption = FeesSortOption.highestRate;
                });
              },
              icon: const Icon(Icons.refresh_rounded, color: AppColors.card, size: 16),
              label: const Text(
                'Reset Filters',
                style: TextStyle(color: AppColors.card, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x66FFFFFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeesSchoolCard extends StatelessWidget {
  final SchoolDashboardData schoolData;
  final String Function(double) formatCurrency;
  final VoidCallback onTap;

  const _FeesSchoolCard({
    required this.schoolData,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final school = schoolData.school;
    final rate = schoolData.feeSubmissionRate;
    final status = ThresholdRules.evaluateFees(rate);

    final statusColor = status.color;
    final statusBg = status.backgroundColor;
    final statusText = status.label.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2DCCE), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: School Info & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${school.schoolId}  ·  ${school.address}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(100), width: 0.8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Financial breakdown row (Collected vs Pending)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'COLLECTED',
                          style: TextStyle(
                            color: Color(0xFF4A6741),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(schoolData.feesCollected),
                          style: const TextStyle(
                            color: Color(0xFF4A6741),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAEAED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Color(0xFFC98591),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(schoolData.feesPending),
                          style: const TextStyle(
                            color: Color(0xFFC98591),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom row: Rate progress bar & percentage
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (rate / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2DCCE),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fee collection rate',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
