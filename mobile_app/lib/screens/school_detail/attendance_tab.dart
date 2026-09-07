import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../services/attendance_service.dart';
import '../../services/dashboard_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/attendance_calculator.dart';
import '../../widgets/firebase_error_view.dart';
import '../../widgets/school_detail/attendance_gauge.dart';
import '../../widgets/school_detail/pill_toggle.dart';
import '../../widgets/school_detail/section_header.dart';
import '../../widgets/school_detail/week_calendar_row.dart';

/// Attendance tab shown inside SchoolDetailScreen.
/// Fetches the full attendance history and lets the user switch between
/// Daily, Weekly, and Monthly views — each updating the gauge and sub-text.
class AttendanceTab extends StatefulWidget {
  final SchoolDashboardData schoolData;

  const AttendanceTab({super.key, required this.schoolData});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  final AttendanceService _attendanceService = AttendanceService();
  late Future<List<AttendanceModel>> _future;
  int _modeIndex = 0; // 0=Daily, 1=Weekly, 2=Monthly

  @override
  void initState() {
    super.initState();
    _future = _attendanceService
        .getSchoolAttendanceHistory(widget.schoolData.school.schoolId);
  }

  // ── Derived values ──────────────────────────────────────────────────────────

  double _computePercentage(List<AttendanceModel> records) {
    if (records.isEmpty) return 0.0;
    switch (_modeIndex) {
      case 0: // Daily — today or most recent record
        return AttendanceCalculator.getDailyAttendance(records);
      case 1: // Weekly — strictly Monday 00:00 to Sunday 23:59
        return AttendanceCalculator.calculateWeeklyAttendance(records);
      case 2: // Monthly — strictly 1st day to last day of current month
        return AttendanceCalculator.calculateMonthlyAttendance(records);
      default:
        return AttendanceCalculator.getDailyAttendance(records);
    }
  }

  String _subLabel(List<AttendanceModel> records, double pct) {
    final studentCount = widget.schoolData.school.studentCount;
    final presentCount = (pct / 100 * studentCount).round();
    final formatted = _formatNumber(studentCount);
    final formattedPresent = _formatNumber(presentCount);

    switch (_modeIndex) {
      case 0:
        return '$formattedPresent of $formatted students present today';
      case 1:
        final count = AttendanceCalculator.getWeeklyRecordCount(records);
        if (count == 0) return 'No attendance submitted this week';
        return '$formattedPresent of $formatted students avg ($count ${count == 1 ? 'day' : 'days'} this week)';
      case 2:
        final count = AttendanceCalculator.getMonthlyRecordCount(records);
        if (count == 0) return 'No attendance submitted this month';
        return '$formattedPresent of $formatted students avg ($count ${count == 1 ? 'day' : 'days'} this month)';
      default:
        return '$formattedPresent of $formatted students present today';
    }
  }

  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AttendanceModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.text),
          );
        }
        if (snapshot.hasError) {
          return FirebaseErrorView(
            title: 'Unable to Load Attendance',
            message: snapshot.error.toString().replaceAll('Exception: ', ''),
            onRetry: () => setState(() => _future = _attendanceService.getSchoolAttendanceHistory(widget.schoolData.school.schoolId)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyState(
            message: 'No attendance records found in Cloud Firestore.',
          );
        }

        final records = snapshot.data!;
        final pct = _computePercentage(records);
        final label = _subLabel(records, pct);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Gauge card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                    // Gauge
                    AttendanceGauge(percentage: pct, size: 210),

                    const SizedBox(height: 12),

                    // Percentage label
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Sub-label
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daily / Weekly / Monthly toggle
                    PillToggle(
                      options: const ['Daily', 'Weekly', 'Monthly'],
                      selectedIndex: _modeIndex,
                      onChanged: (i) => setState(() => _modeIndex = i),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Weekly calendar row ─────────────────────────────────────
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
                    const SectionHeader(text: 'This Week'),
                    const SizedBox(height: 16),
                    WeekCalendarRow(attendanceRecords: records),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent history list ─────────────────────────────────────
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
                    const SectionHeader(text: 'Recent Records'),
                    const SizedBox(height: 12),
                    ...records.take(14).map((r) => _AttendanceRow(record: r)),
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

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _AttendanceRow extends StatelessWidget {
  final AttendanceModel record;

  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isGood = record.attendancePercentage >= 75;
    final dotColor =
        isGood ? const Color(0xFF4A6741) : const Color(0xFFC98591);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.date,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${record.attendancePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: dotColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
        ),
      ),
    );
  }
}
