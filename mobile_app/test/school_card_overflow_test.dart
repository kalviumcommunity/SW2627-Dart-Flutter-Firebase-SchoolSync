import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/school_model.dart';
import 'package:mobile_app/services/dashboard_service.dart';
import 'package:mobile_app/widgets/school_card.dart';

void main() {
  testWidgets('SchoolCard renders student count and KPI badges without overflow in narrow constraints',
      (WidgetTester tester) async {
    final school = SchoolModel(
      schoolId: 'SCH001',
      name: 'Adarsh Senior Secondary School',
      address: 'Jaipur, Rajasthan',
      districtId: 'DIST001',
      studentCount: 1148,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final schoolData = SchoolDashboardData(
      school: school,
      latestAttendancePercentage: 5.0,
      weeklyAttendancePercentage: 10.0,
      monthlyAttendancePercentage: 15.0,
      feeSubmissionRate: 75.0,
      feesCollected: 75000,
      feesPending: 25000,
      examStatus: 'Lagging',
      feedbackStatus: 'Requires Review',
    );

    // Render inside a tight width constraint (150px) typical of half a mobile screen in 2-column grid
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 200,
            child: SchoolCard(
              schoolData: schoolData,
              index: 0,
            ),
          ),
        ),
      ),
    );

    // Verify elements are present
    expect(find.text('1,148 STU'), findsOneWidget);
    expect(find.text('ATT 5%'), findsOneWidget);
    expect(find.text('FEE 75%'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);

    // Verify no RenderFlex overflow exception occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('SchoolCard renders without overflow in very narrow 135px constraint',
      (WidgetTester tester) async {
    final school = SchoolModel(
      schoolId: 'SCH002',
      name: 'Government Higher Secondary School',
      address: 'Jaipur, Rajasthan',
      districtId: 'DIST001',
      studentCount: 1496,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final schoolData = SchoolDashboardData(
      school: school,
      latestAttendancePercentage: 85.0,
      weeklyAttendancePercentage: 85.0,
      monthlyAttendancePercentage: 85.0,
      feeSubmissionRate: 98.0,
      feesCollected: 98000,
      feesPending: 2000,
      examStatus: 'On track',
      feedbackStatus: 'Good',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 135,
            height: 165,
            child: SchoolCard(
              schoolData: schoolData,
              index: 0,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1,496 STU'), findsOneWidget);
    expect(find.text('ATT 85%'), findsOneWidget);
    expect(find.text('FEE 98%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
