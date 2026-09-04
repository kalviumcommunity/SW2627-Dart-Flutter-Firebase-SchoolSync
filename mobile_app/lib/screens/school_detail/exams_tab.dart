import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/exam_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/business_rules.dart';
import '../../widgets/firebase_error_view.dart';
import '../../widgets/school_detail/section_header.dart';

/// Exams tab shown inside SchoolDetailScreen.
/// Groups exams into Upcoming, Overdue, and Completed sections.
class ExamsTab extends StatefulWidget {
  final SchoolDashboardData schoolData;

  const ExamsTab({super.key, required this.schoolData});

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  final ExamService _service = ExamService();
  late Future<List<ExamModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSchoolExams(widget.schoolData.school.schoolId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ExamModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.text));
        }
        if (snapshot.hasError) {
          return FirebaseErrorView(
            title: 'Unable to Load Exam Schedule',
            message: snapshot.error.toString().replaceAll('Exception: ', ''),
            onRetry: () => setState(() => _future = _service.getSchoolExams(widget.schoolData.school.schoolId)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No exam records found in Cloud Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.secondaryText, fontSize: 14),
              ),
            ),
          );
        }

        final exams = snapshot.data!;
        final overdue =
            exams.where((e) => e.isOverdue).toList();
        final upcoming = exams
            .where((e) => e.status == 'scheduled' && !e.isOverdue)
            .toList();
        final completed =
            exams.where((e) => e.isCompleted).toList();
        final cancelled =
            exams.where((e) => e.isCancelled).toList();

        final eval = ThresholdRules.evaluateExams(exams);
        final status = eval.status;
        final isLagging = status == KPIStatus.critical;
        final isApproaching = status == KPIStatus.warning;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status banner ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status.icon,
                      color: status.color,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isLagging
                            ? '${overdue.length} exam${overdue.length > 1 ? 's' : ''} overdue (Action required)'
                            : (isApproaching
                                ? '${eval.approachingCount} exam${eval.approachingCount > 1 ? 's' : ''} approaching deadline within 3 days'
                                : 'All exams on schedule'),
                        style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (overdue.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(
                    text: 'Overdue',
                    color: Color(0xFFC98591)),
                const SizedBox(height: 10),
                ...overdue.map((e) => _ExamCard(
                      exam: e,
                      onStatusChanged: (status) => _handleStatusChange(e, status),
                    )),
              ],

              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(text: 'Upcoming'),
                const SizedBox(height: 10),
                ...upcoming.map((e) => _ExamCard(
                      exam: e,
                      onStatusChanged: (status) => _handleStatusChange(e, status),
                    )),
              ],

              if (completed.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(text: 'Completed'),
                const SizedBox(height: 10),
                ...completed.map((e) => _ExamCard(
                      exam: e,
                      onStatusChanged: (status) => _handleStatusChange(e, status),
                    )),
              ],

              if (cancelled.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeader(text: 'Cancelled'),
                const SizedBox(height: 10),
                ...cancelled.map((e) => _ExamCard(
                      exam: e,
                      onStatusChanged: (status) => _handleStatusChange(e, status),
                    )),
              ],

              if (exams.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No exams scheduled.',
                      style: TextStyle(
                          color: AppColors.secondaryText, fontSize: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleStatusChange(ExamModel exam, String newStatus) async {
    final schoolId = widget.schoolData.school.schoolId;
    await _service.updateExamStatus(
      schoolId: schoolId,
      examId: exam.examId,
      newStatus: newStatus,
    );
    if (mounted) {
      setState(() {
        _future = _service.getSchoolExams(schoolId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${exam.examName}" status to $newStatus in Firestore!'),
          backgroundColor: const Color(0xFF4A6741),
        ),
      );
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final ValueChanged<String>? onStatusChanged;

  const _ExamCard({required this.exam, this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    if (exam.isOverdue) {
      statusColor = const Color(0xFFC98591);
      statusBg = const Color(0xFFFAEAED);
      statusLabel = 'OVERDUE';
      statusIcon = Icons.warning_amber_rounded;
    } else if (exam.isCompleted) {
      statusColor = const Color(0xFF4A6741);
      statusBg = const Color(0xFFE8F0E5);
      statusLabel = 'DONE';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (exam.isCancelled) {
      statusColor = AppColors.secondaryText;
      statusBg = const Color(0xFFF0EDE8);
      statusLabel = 'CANCELLED';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = const Color(0xFF6B7F99);
      statusBg = const Color(0xFFE8EDF3);
      statusLabel = 'SCHEDULED';
      statusIcon = Icons.calendar_today_outlined;
    }

    final dateStr =
        '${exam.scheduledDate.day.toString().padLeft(2, '0')} ${_month(exam.scheduledDate.month)} ${exam.scheduledDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2DCCE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Subject chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),

          const SizedBox(width: 12),

          // Name, subject, date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.examName,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exam.subject}  ·  Class ${exam.classNumber}  ·  $dateStr',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Interactive Status badge with menu dropdown
          PopupMenuButton<String>(
            onSelected: (val) => onStatusChanged?.call(val),
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'completed',
                child: Text('✅ Mark Done'),
              ),
              PopupMenuItem(
                value: 'scheduled',
                child: Text('📅 Mark Scheduled'),
              ),
              PopupMenuItem(
                value: 'cancelled',
                child: Text('🚫 Cancel Exam'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, color: statusColor, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
