import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:mobile_app/models/school_model.dart';
import 'package:mobile_app/services/dashboard_service.dart';
import 'package:mobile_app/screens/school_detail/attendance_tab.dart';
import 'package:mobile_app/screens/school_detail/fees_tab.dart';
import 'package:mobile_app/screens/school_detail/exams_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  final dummySchool = SchoolModel(
    schoolId: 'SCH-TEST-001',
    name: 'Government Model High School',
    districtId: 'DIST-TEST',
    address: 'Sector 4, Central District',
    studentCount: 500,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  final dummySchoolData = SchoolDashboardData(
    school: dummySchool,
    latestAttendancePercentage: 88.0,
    weeklyAttendancePercentage: 86.5,
    monthlyAttendancePercentage: 85.0,
    feeSubmissionRate: 92.0,
    feesCollected: 460000.0,
    feesPending: 40000.0,
    examStatus: 'On track',
    feedbackStatus: 'good',
  );

  group('School Detail Read-Only Tabs Verification', () {
    testWidgets('AttendanceTab does not contain manual update/log button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceTab(schoolData: dummySchoolData),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 10));

      // Verify no "Update / Log Attendance" button is present in the UI hierarchy
      expect(find.text('Update / Log Attendance'), findsNothing);
      expect(find.byIcon(Icons.edit_calendar_rounded), findsNothing);
    });

    testWidgets('FeesTab does not contain manual update fee collection button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeesTab(schoolData: dummySchoolData),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 10));

      // Verify no "Update Fee Collection" button is present in the UI hierarchy
      expect(find.text('Update Fee Collection'), findsNothing);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);
    });

    testWidgets('ExamsTab renders read-only status and no PopupMenuButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamsTab(schoolData: dummySchoolData),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 10));

      // Verify no interactive status change dropdowns
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
