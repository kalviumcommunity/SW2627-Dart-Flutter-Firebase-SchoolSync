import 'package:flutter/material.dart';
import '../screens/school_detail_screen.dart';
import '../services/dashboard_service.dart';
import '../utils/app_colors.dart';
import '../utils/business_rules.dart';

class SchoolCard extends StatelessWidget {
  final SchoolDashboardData schoolData;
  final int index;

  const SchoolCard({
    super.key,
    required this.schoolData,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final school = schoolData.school;
    final overall = schoolData.overallStatus;
    final isCritical = overall == KPIStatus.critical;
    final isWarning = overall == KPIStatus.warning;
    final isHealthy = overall == KPIStatus.healthy;

    final attStatus = schoolData.attendanceStatus;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchoolDetailScreen(schoolData: schoolData),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCritical
                ? const Color(0xFFE0BAC0)
                : (isWarning ? const Color(0xFFF0E0B0) : const Color(0xFFE2DCCE)),
            width: !isHealthy ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          school.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (!isHealthy) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: isCritical ? 'Critical Issue Detected' : 'Operational Warning',
                          child: Icon(
                            overall.icon,
                            size: 16,
                            color: overall.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatNumber(school.studentCount)} STU',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: attStatus.backgroundColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ATT ${schoolData.latestAttendancePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: attStatus.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (schoolData.feeSubmissionRate > 0 || schoolData.feesPending > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: schoolData.feeStatus.backgroundColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FEE ${schoolData.feeSubmissionRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: schoolData.feeStatus.color,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: overall.solidColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isHealthy
                        ? 'HEALTHY'
                        : (isWarning ? 'WARNING' : 'CRITICAL'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(
                  overall.icon,
                  size: 18,
                  color: overall.color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) =>
      number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

