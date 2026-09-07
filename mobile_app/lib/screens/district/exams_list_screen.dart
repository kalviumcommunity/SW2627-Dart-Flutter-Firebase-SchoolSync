import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/business_rules.dart';
import '../../widgets/district_summary_banner.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/school_search_bar.dart';
import '../school_detail_screen.dart';

enum ExamStatusFilter { all, lagging, approaching, onTrack }

enum ExamSortOption { laggingFirst, onTrackFirst, name, students }

class ExamsListScreen extends StatefulWidget {
  final DistrictDashboardSummary summary;
  final VoidCallback? onRefresh;

  const ExamsListScreen({
    super.key,
    required this.summary,
    this.onRefresh,
  });

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  ExamStatusFilter _statusFilter = ExamStatusFilter.all;
  ExamSortOption _sortOption = ExamSortOption.laggingFirst;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SchoolDashboardData> _getFilteredSchools() {
    final schools = widget.summary.schoolsData;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = schools.where((s) {
      // 1. Search filter
      if (query.isNotEmpty) {
        final matchesName = s.school.name.toLowerCase().contains(query);
        final matchesId = s.school.schoolId.toLowerCase().contains(query);
        if (!matchesName && !matchesId) return false;
      }

      // 2. Status filter
      switch (_statusFilter) {
        case ExamStatusFilter.all:
          return true;
        case ExamStatusFilter.lagging:
          return s.examKPIStatus == KPIStatus.critical;
        case ExamStatusFilter.approaching:
          return s.examKPIStatus == KPIStatus.warning;
        case ExamStatusFilter.onTrack:
          return s.examKPIStatus == KPIStatus.healthy;
      }
    }).toList();

    // 3. Sorting logic
    filtered.sort((a, b) {
      final aSev = a.examKPIStatus.severity;
      final bSev = b.examKPIStatus.severity;

      switch (_sortOption) {
        case ExamSortOption.laggingFirst:
          if (aSev != bSev) return bSev.compareTo(aSev); // Highest risk first
          return a.school.name.compareTo(b.school.name);
        case ExamSortOption.onTrackFirst:
          if (aSev != bSev) return aSev.compareTo(bSev); // Lowest risk first
          return a.school.name.compareTo(b.school.name);
        case ExamSortOption.name:
          return a.school.name.compareTo(b.school.name);
        case ExamSortOption.students:
          return b.school.studentCount.compareTo(a.school.studentCount);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final schools = widget.summary.schoolsData;
    final filteredSchools = _getFilteredSchools();

    int laggingCount = 0;
    int approachingCount = 0;
    int onTrackCount = 0;
    for (final s in schools) {
      if (s.examKPIStatus == KPIStatus.critical) {
        laggingCount++;
      } else if (s.examKPIStatus == KPIStatus.warning) {
        approachingCount++;
      } else {
        onTrackCount++;
      }
    }

    final isDistrictLagging = widget.summary.examProgressStatus.toLowerCase() == 'lagging';

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
              'ACADEMIC ASSESSMENTS',
              style: TextStyle(
                color: Color(0xFFC7BDB3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'District Exam Status',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),

            // ── District Summary Banner ────────────────────────────────
            DistrictSummaryBanner(
              title: 'District Assessment Status',
              metrics: [
                DistrictSummaryMetric(
                  label: 'Overall Status',
                  value: isDistrictLagging ? 'Lagging' : 'On Track',
                  subtitle: isDistrictLagging ? 'Action required' : 'Schedules normal',
                  valueColor: isDistrictLagging ? const Color(0xFFC98591) : const Color(0xFF4A6741),
                  icon: isDistrictLagging ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'Lagging Schools',
                  value: '$laggingCount',
                  subtitle: laggingCount > 0 ? 'Overdue exams' : 'All schools current',
                  valueColor: laggingCount > 0 ? const Color(0xFFC98591) : const Color(0xFF4A6741),
                  icon: Icons.warning_amber_rounded,
                ),
                DistrictSummaryMetric(
                  label: 'On Track',
                  value: '$onTrackCount',
                  subtitle: '${schools.length} Total schools',
                  valueColor: const Color(0xFF4A6741),
                  icon: Icons.check_circle_outline_rounded,
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

            // ── Status Filter Chips ─────────────────────────────────────
            FilterChipRow<ExamStatusFilter>(
              items: [
                FilterChipItem(
                  value: ExamStatusFilter.all,
                  label: 'All Schools',
                  count: schools.length,
                ),
                FilterChipItem(
                  value: ExamStatusFilter.lagging,
                  label: 'Overdue (Critical)',
                  icon: Icons.error_outline_rounded,
                  count: laggingCount,
                ),
                FilterChipItem(
                  value: ExamStatusFilter.approaching,
                  label: 'Approaching (Warning)',
                  icon: Icons.warning_amber_rounded,
                  count: approachingCount,
                ),
                FilterChipItem(
                  value: ExamStatusFilter.onTrack,
                  label: 'On Schedule (Healthy)',
                  icon: Icons.check_circle_outline_rounded,
                  count: onTrackCount,
                ),
              ],
              selectedValue: _statusFilter,
              onSelected: (val) => setState(() => _statusFilter = val),
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
                PopupMenuButton<ExamSortOption>(
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
                    _buildSortMenuItem(ExamSortOption.laggingFirst, 'Lagging Schools First'),
                    _buildSortMenuItem(ExamSortOption.onTrackFirst, 'On Track Schools First'),
                    _buildSortMenuItem(ExamSortOption.name, 'School Name (A-Z)'),
                    _buildSortMenuItem(ExamSortOption.students, 'Student Count (High-Low)'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── School Exam Cards List / Empty State ────────────────────
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
                  return _ExamSchoolCard(
                    schoolData: schoolData,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SchoolDetailScreen(
                            schoolData: schoolData,
                            initialTabIndex: 2, // Exams tab
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

  String _getSortLabel(ExamSortOption opt) {
    switch (opt) {
      case ExamSortOption.laggingFirst:
        return 'Lagging First';
      case ExamSortOption.onTrackFirst:
        return 'On Track First';
      case ExamSortOption.name:
        return 'Name';
      case ExamSortOption.students:
        return 'Students';
    }
  }

  PopupMenuItem<ExamSortOption> _buildSortMenuItem(
    ExamSortOption value,
    String label,
  ) {
    final isSelected = _sortOption == value;
    return PopupMenuItem<ExamSortOption>(
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
              'No schools match the selected status',
              style: TextStyle(
                color: AppColors.card,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your status filter or search query.',
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
                  _statusFilter = ExamStatusFilter.all;
                  _sortOption = ExamSortOption.laggingFirst;
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

class _ExamSchoolCard extends StatelessWidget {
  final SchoolDashboardData schoolData;
  final VoidCallback onTap;

  const _ExamSchoolCard({
    required this.schoolData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final school = schoolData.school;
    final status = schoolData.examKPIStatus;

    final statusColor = status.color;
    final statusBg = status.backgroundColor;
    final statusBorder = status.borderColor;
    final statusLabel = status == KPIStatus.critical
        ? 'OVERDUE'
        : (status == KPIStatus.warning ? 'APPROACHING' : 'ON TRACK');

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
            // Top: School Info & Primary Status Pill
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.solidColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status.icon,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Middle status card banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    status == KPIStatus.critical
                        ? Icons.schedule_rounded
                        : (status == KPIStatus.warning ? Icons.alarm_rounded : Icons.event_available_rounded),
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == KPIStatus.critical
                          ? 'Assessments overdue or past deadline (Action required)'
                          : (status == KPIStatus.warning
                              ? 'Assessments approaching deadline within 3 days'
                              : 'All term assessments progressing on schedule'),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondaryText,
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Bottom metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatNumber(school.studentCount)} students enrolled',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Attendance: ${schoolData.latestAttendancePercentage.toStringAsFixed(0)}%',
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
    );
  }

  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
