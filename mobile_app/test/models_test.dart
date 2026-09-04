import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/school_model.dart';
import 'package:mobile_app/models/attendance_model.dart';
import 'package:mobile_app/models/fee_period_model.dart';
import 'package:mobile_app/models/exam_model.dart';
import 'package:mobile_app/models/feedback_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/models/signup_model.dart';

// A simple fake DocumentSnapshot for unit testing the models
// ignore: subtype_of_sealed_class
class FakeDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Object? operator [](Object key) => _data[key];

  @override
  Map<String, dynamic> data() => _data;

  @override
  bool get exists => true;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SchoolSync Dashboard Backend Models Tests', () {
    
    test('SchoolModel - Parsing and synthetic studentCount fallback', () {
      final doc1 = FakeDocumentSnapshot('SCH001', {
        'name': 'Greenwood Public School',
        'address': 'Jaipur',
        'districtId': 'DIST001',
        'createdAt': Timestamp.fromDate(DateTime(2026, 5, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 8, 18)),
      });

      final school1 = SchoolModel.fromFirestore(doc1);
      expect(school1.schoolId, 'SCH001');
      expect(school1.name, 'Greenwood Public School');
      expect(school1.studentCount, isNotNull);
      // Check that it generates a deterministic mock count between 800 and 1600
      expect(school1.studentCount, greaterThanOrEqualTo(800));
      expect(school1.studentCount, lessThanOrEqualTo(1600));

      final doc2 = FakeDocumentSnapshot('SCH001', {
        'name': 'Greenwood Public School',
        'studentCount': 1240,
      });
      final school2 = SchoolModel.fromFirestore(doc2);
      expect(school2.studentCount, 1240); // Reads directly if present
    });

    test('AttendanceModel - Parsing attendance percentages', () {
      final doc = FakeDocumentSnapshot('2026-08-18', {
        'attendancePercentage': 94.5,
        'date': '2026-08-18',
        'status': 'submitted',
        'submittedBy': 'USR_001',
      });

      final att = AttendanceModel.fromFirestore(doc);
      expect(att.documentId, '2026-08-18');
      expect(att.attendancePercentage, 94.5);
      expect(att.date, '2026-08-18');
    });

    test('FeePeriodModel - Dues calculation and submission rate', () {
      final doc = FakeDocumentSnapshot('2026_TERM_1', {
        'totalDue': 1000000.0,
        'totalSubmitted': 800000.0,
        'status': 'active',
        'updatedBy': 'USR_001',
      });

      final fee = FeePeriodModel.fromFirestore(doc);
      expect(fee.periodId, '2026_TERM_1');
      expect(fee.pendingAmount, 200000.0); // 1,000,000 - 800,000 = 200,000
      expect(fee.submissionRate, 80.0); // (800,000 / 1,000,000) * 100 = 80%
    });

    test('ExamModel - Overdue and completed status calculation', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final futureDate = DateTime.now().add(const Duration(days: 2));

      final overdueDoc = FakeDocumentSnapshot('EXAM001', {
        'examName': 'Math Term 1',
        'status': 'scheduled',
        'scheduledDate': Timestamp.fromDate(pastDate),
      });

      final overdueExam = ExamModel.fromFirestore(overdueDoc);
      expect(overdueExam.isOverdue, isTrue);
      expect(overdueExam.isCompleted, isFalse);

      final completedDoc = FakeDocumentSnapshot('EXAM002', {
        'examName': 'Math Term 1',
        'status': 'completed',
        'scheduledDate': Timestamp.fromDate(pastDate),
      });

      final completedExam = ExamModel.fromFirestore(completedDoc);
      expect(completedExam.isOverdue, isFalse);
      expect(completedExam.isCompleted, isTrue);

      final futureDoc = FakeDocumentSnapshot('EXAM003', {
        'examName': 'Math Term 1',
        'status': 'scheduled',
        'scheduledDate': Timestamp.fromDate(futureDate),
      });

      final futureExam = ExamModel.fromFirestore(futureDoc);
      expect(futureExam.isOverdue, isFalse);
    });

    test('FeedbackModel - Parsing feedback metadata', () {
      final doc = FakeDocumentSnapshot('FB001', {
        'text': 'Good academic status',
        'symbol': 'good',
        'createdBy': 'DISTRICT_ADMIN_001',
        'createdAt': Timestamp.fromDate(DateTime(2026, 8, 18)),
      });

      final fb = FeedbackModel.fromFirestore(doc);
      expect(fb.feedbackId, 'FB001');
      expect(fb.symbol, 'good');
      expect(fb.text, 'Good academic status');
    });

    test('UserModel - Serialization, deserialization, and District Isolation mapping', () {
      final doc = FakeDocumentSnapshot('USER123', {
        'email': 'admin1@district1.com',
        'name': 'Priya Sharma',
        'role': 'district_admin',
        'districtId': 'DIST001',
      });

      final user = UserModel.fromFirestore(doc);
      expect(user.uid, 'USER123');
      expect(user.email, 'admin1@district1.com');
      expect(user.name, 'Priya Sharma');
      expect(user.role, 'district_admin');
      expect(user.districtId, 'DIST001');

      final userMap = user.toMap();
      expect(userMap['districtId'], 'DIST001');
      expect(userMap['role'], 'district_admin');

      final user2 = UserModel.fromMap('USER456', {
        'email': 'admin2@district2.com',
        'name': 'Rajesh Kumar',
        'role': 'district_admin',
        'districtId': 'DIST002',
      });
      expect(user2.districtId, 'DIST002');
      expect(user2.uid, 'USER456');
    });

    test('SignupModel - District ID validation and serialization', () {
      final validSignup = SignupModel(
        name: 'Priya Sharma',
        email: 'priya@district1.in',
        districtId: 'DIST001',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(validSignup.validate(), isNull);
      expect(validSignup.passwordsMatch, isTrue);
      expect(validSignup.district, 'DIST001');

      final map = validSignup.toMap();
      expect(map['name'], 'Priya Sharma');
      expect(map['email'], 'priya@district1.in');
      expect(map['districtId'], 'DIST001');

      final emptyDistrictSignup = SignupModel(
        name: 'Priya Sharma',
        email: 'priya@district1.in',
        districtId: '',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(emptyDistrictSignup.validate(), 'Please enter your District ID.');

      final shortDistrictSignup = SignupModel(
        name: 'Priya Sharma',
        email: 'priya@district1.in',
        districtId: 'D',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(shortDistrictSignup.validate(), 'District ID must be at least 2 characters.');

      final passwordMismatchSignup = SignupModel(
        name: 'Priya Sharma',
        email: 'priya@district1.in',
        districtId: 'DIST002',
        password: 'password123',
        confirmPassword: 'password456',
      );
      expect(passwordMismatchSignup.validate(), 'Passwords do not match.');
    });

  });
}
