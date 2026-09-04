import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/widgets/dashboard_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('ProfileScreen Widget Tests', () {
    final testProfile = UserModel(
      uid: 'test_uid_123',
      email: 'priya.sharma@district.in',
      name: 'Priya Sharma',
      role: 'district_admin',
      districtId: 'DIST001',
    );

    testWidgets('ProfileScreen renders user details, badges, and sections correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userProfile: testProfile,
          ),
        ),
      );

      // Check header and user details
      expect(find.text('Account Profile'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsWidgets);
      expect(find.text('priya.sharma@district.in'), findsWidgets);
      expect(find.text('District Administrator'), findsWidgets);
      expect(find.text('Active Live Sync'), findsOneWidget);

      // Check sections
      expect(find.text('DISTRICT ASSIGNMENT'), findsOneWidget);
      expect(find.text('ACCOUNT CREDENTIALS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('DIST001'), findsOneWidget);
      expect(find.text('Log Out of Account'), findsOneWidget);
    });

    testWidgets('Tapping Log Out opens confirmation dialog and invokes onLogout on confirm',
        (WidgetTester tester) async {
      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userProfile: testProfile,
            onLogout: () {
              logoutCalled = true;
            },
          ),
        ),
      );

      final logoutButtonFinder = find.text('Log Out of Account');
      await tester.ensureVisible(logoutButtonFinder);
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle();

      // Check confirmation dialog appears
      expect(find.text('Sign Out'), findsWidgets);
      expect(
        find.text(
          'Are you sure you want to sign out of your SchoolSync district administrator account?',
        ),
        findsOneWidget,
      );

      // Confirm sign out in dialog
      final confirmButtonFinder = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmButtonFinder, findsOneWidget);
      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });

    testWidgets('Tapping AppBar back button invokes onBack callback',
        (WidgetTester tester) async {
      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            userProfile: testProfile,
            onBack: () {
              backCalled = true;
            },
          ),
        ),
      );

      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });
  });

  group('DashboardBottomNav with Profile Tab', () {
    testWidgets('DashboardBottomNav displays 5 navigation tabs including Profile',
        (WidgetTester tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DashboardBottomNav(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Board'), findsOneWidget);
      expect(find.text('Attend.'), findsOneWidget);
      expect(find.text('Fees'), findsOneWidget);
      expect(find.text('Exams'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(tappedIndex, 4);
    });
  });
}
