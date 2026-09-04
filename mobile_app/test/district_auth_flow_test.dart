import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:mobile_app/models/school_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/screens/signup_screen.dart';
import 'package:mobile_app/services/dashboard_service.dart';
import 'package:mobile_app/widgets/dashboard_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('District ID Signup & Auth Flow Tests', () {
    testWidgets('SignUpScreen renders District ID field correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      // Verify header and form labels
      expect(find.text('Register an account'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('DISTRICT OFFICE EMAIL'), findsOneWidget);
      expect(find.text('DISTRICT ID'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('SignUpScreen validates District ID field when empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      final formFields = find.byType(TextFormField);
      expect(formFields, findsNWidgets(5));

      // Field 0: Full name
      await tester.enterText(formFields.at(0), 'Priya Sharma');
      // Field 1: Email
      await tester.enterText(formFields.at(1), 'priya@district.in');
      // Field 2: District ID left empty
      await tester.enterText(formFields.at(2), '');
      // Field 3: Password
      await tester.enterText(formFields.at(3), 'password123');
      // Field 4: Confirm Password
      await tester.enterText(formFields.at(4), 'password123');

      // Scroll to button if offscreen and tap
      final buttonFinder = find.text('Create account');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Please enter your District ID.'), findsOneWidget);
    });

    testWidgets('SignUpScreen validates District ID field when too short',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );

      // Fill in all text form fields
      final formFields = find.byType(TextFormField);
      expect(formFields, findsNWidgets(5));

      // Field 0: Full name
      await tester.enterText(formFields.at(0), 'Priya Sharma');
      // Field 1: Email
      await tester.enterText(formFields.at(1), 'priya@district.in');
      // Field 2: District ID (too short - 1 char)
      await tester.enterText(formFields.at(2), 'D');
      // Field 3: Password
      await tester.enterText(formFields.at(3), 'password123');
      // Field 4: Confirm Password
      await tester.enterText(formFields.at(4), 'password123');

      final buttonFinder = find.text('Create account');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(
          find.text('District ID must be at least 2 characters.'), findsOneWidget);
    });

    test('UserModel preserves distinct District IDs without fallback', () {
      final user1 = UserModel.fromMap('uid_1', {
        'email': 'admin1@dist1.gov',
        'name': 'Admin One',
        'role': 'district_admin',
        'districtId': 'DIST001',
      });
      expect(user1.districtId, 'DIST001');

      final user2 = UserModel.fromMap('uid_2', {
        'email': 'admin2@dist2.gov',
        'name': 'Admin Two',
        'role': 'district_admin',
        'districtId': 'DIST002',
      });
      expect(user2.districtId, 'DIST002');

      final userEmpty = UserModel.fromMap('uid_3', {
        'email': 'admin3@dist3.gov',
        'name': 'Admin Three',
        'role': 'district_admin',
      });
      // Should NOT fall back to 'DIST001'
      expect(userEmpty.districtId, '');
    });

    testWidgets('DashboardHeader displays dynamic District ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardHeader(
              userName: 'Priya Sharma',
              districtId: 'DIST002',
            ),
          ),
        ),
      );

      expect(find.text('DISTRICT ADMINISTRATOR · DIST002'), findsOneWidget);
      expect(find.text('Good morning, Priya Sharma'), findsOneWidget);
    });

    test('Multi-district isolation: Two distinct district accounts load distinct datasets', () {
      // Simulate schools database
      final List<SchoolModel> allSchools = [
        // District 1 (Jaipur)
        SchoolModel(
          schoolId: 'SCH001',
          name: 'Jaipur School 01',
          address: 'Jaipur',
          districtId: 'DIST001',
          studentCount: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SchoolModel(
          schoolId: 'SCH002',
          name: 'Jaipur School 02',
          address: 'Jaipur',
          districtId: 'DIST001',
          studentCount: 1200,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // District 2 (Gurugram)
        SchoolModel(
          schoolId: 'SCH011',
          name: 'Gurugram School 11',
          address: 'Gurugram',
          districtId: 'DIST002',
          studentCount: 900,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SchoolModel(
          schoolId: 'SCH012',
          name: 'Gurugram School 12',
          address: 'Gurugram',
          districtId: 'DIST002',
          studentCount: 1100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Admin 1 (DIST001)
      final admin1 = UserModel(
        uid: 'user_dist1',
        email: 'admin@jaipur.gov',
        name: 'Jaipur Admin',
        role: 'district_admin',
        districtId: 'DIST001',
      );

      final admin1Schools = allSchools
          .where((s) => s.districtId == admin1.districtId)
          .toList();

      expect(admin1Schools.length, 2);
      expect(admin1Schools.every((s) => s.districtId == 'DIST001'), isTrue);
      expect(admin1Schools.map((s) => s.schoolId), containsAll(['SCH001', 'SCH002']));
      expect(admin1Schools.map((s) => s.schoolId), isNot(contains('SCH011')));

      // Admin 2 (DIST002)
      final admin2 = UserModel(
        uid: 'user_dist2',
        email: 'admin@gurugram.gov',
        name: 'Gurugram Admin',
        role: 'district_admin',
        districtId: 'DIST002',
      );

      final admin2Schools = allSchools
          .where((s) => s.districtId == admin2.districtId)
          .toList();

      expect(admin2Schools.length, 2);
      expect(admin2Schools.every((s) => s.districtId == 'DIST002'), isTrue);
      expect(admin2Schools.map((s) => s.schoolId), containsAll(['SCH011', 'SCH012']));
      expect(admin2Schools.map((s) => s.schoolId), isNot(contains('SCH001')));

      // Summary contains correct districtId
      final summary1 = DistrictDashboardSummary(
        districtId: admin1.districtId,
        averageAttendanceToday: 92.5,
        totalFeesCollected: 500000,
        totalFeesPending: 100000,
        weeklyExamsCount: 4,
        examProgressStatus: 'On track',
        schoolsData: [],
      );
      expect(summary1.districtId, 'DIST001');

      final summary2 = DistrictDashboardSummary(
        districtId: admin2.districtId,
        averageAttendanceToday: 88.0,
        totalFeesCollected: 350000,
        totalFeesPending: 150000,
        weeklyExamsCount: 2,
        examProgressStatus: 'Lagging',
        schoolsData: [],
      );
      expect(summary2.districtId, 'DIST002');
    });
  });
}
