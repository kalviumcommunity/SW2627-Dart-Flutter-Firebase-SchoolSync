import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/business_rules.dart';
import '../../widgets/district_summary_banner.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/school_search_bar.dart';
import '../school_detail_screen.dart';

enum AttendancePeriod { daily, weekly, monthly }

enum AttendanceThresholdFilter { all, critical, moderate, good }

enum AttendanceSortOption { highest, lowest, name, students }

class AttendanceListScreen extends StatefulWidget {
  final DistrictDashboardSummary summary;
  final VoidCallback? onRefresh;

  const AttendanceListScreen({
    super.key,
    required this.summary,
    this.onRefresh,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  AttendancePeriod _period = AttendancePeriod.daily;
  AttendanceThresholdFilter _thresholdFilter = AttendanceThresholdFilter.all;
  AttendanceSortOption _sortOption = AttendanceSortOption.highest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _getSchoolAttendance(SchoolDashboardData school, AttendancePeriod period) {
    switch (period) {
      case AttendancePeriod.daily:
        return school.latestAttendancePercentage;
      case AttendancePeriod.weekly:
        return school.weeklyAttendancePercentage;
      case AttendancePeriod.monthly:
        return school.monthlyAttendancePercentage;
    }
  }

  List<SchoolDashboardData> _getFilteredSchools() {
    final schools = widget.summary.schoolsData;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = schools.where((s) {
      // 1. Search Query filter
      if (query.isNotEmpty) {
        final matchesName = s.school.name.toLowerCase().contains(query);
        final matchesId = s.school.schoolId.toLowerCase().contains(query);
        if (!matchesName && !matchesId) return false;
      }

      // 2. Attendance threshold filter using business rules
      final att = _getSchoolAttendance(s, _period);
      final status = ThresholdRules.evaluateAttendance(att);
      switch (_thresholdFilter) {
        case AttendanceThresholdFilter.all:
          return true;
        case AttendanceThresholdFilter.critical:
          return status == KPIStatus.critical;
        case AttendanceThresholdFilter.moderate:
          return status == KPIStatus.warning;
        case AttendanceThresholdFilter.good:
          return status == KPIStatus.healthy;
      }
    }).toList();

    // 3. Sorting logic
    filtered.sort((a, b) {
      final attA = _getSchoolAttendance(a, _period);
      final attB = _getSchoolAttendance(b, _period);

      switch (_sortOption) {
        case AttendanceSortOption.highest:
          return attB.compareTo(attA);
        case AttendanceSortOption.lowest:
          return attA.compareTo(attB);
        case AttendanceSortOption.name:
          return a.school.name.compareTo(b.school.name);
        case AttendanceSortOption.students:
          return b.school.studentCount.compareTo(a.school.studentCount);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final schools = widget.summary.schoolsData;
    final filteredSchools = _getFilteredSchools();

    // Calculate dynamic stats based on current period
    double periodAvg = 0.0;
    int criticalCount = 0;
    int warningCount = 0;
    int goodCount = 0;

    if (schools.isNotEmpty) {
      double sum = 0.0;
      for (final s in schools) {
        final att = _getSchoolAttendance(s, _period);
        sum += att;
        final status = ThresholdRules.evaluateAttendance(att);
        if (status == KPIStatus.critical) criticalCount++;
        if (status == KPIStatus.warning) warningCount++;
        if (status == KPIStatus.healthy) goodCount++;
      }
      periodAvg = sum / schools.length;
    }

    final periodTitle = _period == AttendancePeriod.daily
        ? 'Today'
        : (_period == AttendancePeriod.weekly ? 'Weekly Avg' : 'Monthly Avg');

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
              'ATTENDANCE MONITORING',
              style: TextStyle(
                color: Color(0xFFC7BDB3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'District Schools Attendance',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            // ── District Summary Banner ────────────────────────────────
            DistrictSummaryBanner(
              title: 'District Overview ($periodTitle)',
              metrics: [
                DistrictSummaryMetric(
                  label: 'Average Rate',
                  value: '${periodAvg.toStringAsFixed(1)}%',
                  subtitle: '$goodCount / ${schools.length} On Target',
                  valueColor: periodAvg >= 80 ? const Color(0xFF4A6741) : const Color(0xFFC98591),
                  icon: Icons.pie_chart_outline_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'Critical Schools',
                  value: '$criticalCount',
                  subtitle: criticalCount > 0 ? '< 70% Attendance' : 'None below 70%',
                  valueColor: criticalCount > 0 ? const Color(0xFFC98591) : const Color(0xFF4A6741),
                  icon: criticalCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'Total Monitored',
                  value: '${schools.length}',
                  subtitle: widget.summary.districtId.isNotEmpty
                      ? '${widget.summary.districtId} District'
                      : 'District Schools',
                  icon: Icons.account_balance_rounded,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Period Toggle Chips ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x22000000),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x2AFFFFFF)),
              ),
              child: Row(
                children: [
                  _buildPeriodButton('Daily', AttendancePeriod.daily),
                  _buildPeriodButton('Weekly', AttendancePeriod.weekly),
                  _buildPeriodButton('Monthly', AttendancePeriod.monthly),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Search Bar ──────────────────────────────────────────────
            SchoolSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: (q) => setState(() => _searchQuery = q),
              hintText: 'Filter by school name or ID…',
            ),

            const SizedBox(height: 16),

            // ── Threshold Filter Chips ──────────────────────────────────
            FilterChipRow<AttendanceThresholdFilter>(
              items: [
                FilterChipItem(
                  value: AttendanceThresholdFilter.all,
                  label: 'All Schools',
                  count: schools.length,
                ),
                FilterChipItem(
                  value: AttendanceThresholdFilter.critical,
                  label: 'Critical (<75%)',
                  icon: Icons.error_outline_rounded,
                  count: criticalCount,
                ),
                FilterChipItem(
                  value: AttendanceThresholdFilter.moderate,
                  label: 'Warning (75-84.9%)',
                  icon: Icons.warning_amber_rounded,
                  count: warningCount,
                ),
                FilterChipItem(
                  value: AttendanceThresholdFilter.good,
                  label: 'Healthy (≥85%)',
                  icon: Icons.check_circle_outline_rounded,
                  count: goodCount,
                ),
              ],
              selectedValue: _thresholdFilter,
              onSelected: (val) => setState(() => _thresholdFilter = val),
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
                PopupMenuButton<AttendanceSortOption>(
                  initialValue: _sortOption,
                  onSelected: (val) => setState(() => _sortOption = val),
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, color: AppColors.card, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _getSortLabel(_sortOption),
                          style: const TextStyle(
                            color: AppColors.card,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.card, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: AttendanceSortOption.highest,
                      child: Text('Highest Attendance First'),
                    ),
                    const PopupMenuItem(
                      value: AttendanceSortOption.lowest,
                      child: Text('Lowest Attendance First'),
                    ),
                    const PopupMenuItem(
                      value: AttendanceSortOption.name,
                      child: Text('School Name (A-Z)'),
                    ),
                    const PopupMenuItem(
                      value: AttendanceSortOption.students,
                      child: Text('Student Count (High-Low)'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── School Attendance List / Empty State ────────────────────
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
                  final att = _getSchoolAttendance(schoolData, _period);
                  return _AttendanceSchoolCard(
                    schoolData: schoolData,
                    attendancePercentage: att,
                    periodLabel: periodTitle,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SchoolDetailScreen(
                            schoolData: schoolData,
                            initialTabIndex: 0, // Attendance tab
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

  Widget _buildPeriodButton(String label, AttendancePeriod period) {
    final isSelected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.text : const Color(0xFFC7BDB3),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel(AttendanceSortOption opt) {
    switch (opt) {
      case AttendanceSortOption.highest:
        return 'Highest %';
      case AttendanceSortOption.lowest:
        return 'Lowest %';
      case AttendanceSortOption.name:
        return 'Name';
      case AttendanceSortOption.students:
        return 'Students';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const Icon(
              Icons.filter_list_off_rounded,
              color: Color(0xFFC7BDB3),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'No schools match the selected criteria',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your filter threshold or search query.',
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
                  _thresholdFilter = AttendanceThresholdFilter.all;
                  _sortOption = AttendanceSortOption.highest;
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

class _AttendanceSchoolCard extends StatelessWidget {
  final SchoolDashboardData schoolData;
  final double attendancePercentage;
  final String periodLabel;
  final VoidCallback onTap;

  const _AttendanceSchoolCard({
    required this.schoolData,
    required this.attendancePercentage,
    required this.periodLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final school = schoolData.school;
    final status = ThresholdRules.evaluateAttendance(attendancePercentage);

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
            // Top Row: School Name & Status Pill
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

            // Middle: Progress bar + Percentage display
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (attendancePercentage / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2DCCE),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$periodLabel attendance',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_formatNumber(school.studentCount)} Enrolled',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${attendancePercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 26,
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

  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
