import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches historical attendance list for a specific school strictly from Cloud Firestore.
  Future<List<AttendanceModel>> getSchoolAttendanceHistory(
      String schoolId) async {
    try {
      final snap = await _db
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));

      return snap.docs.map((d) => AttendanceModel.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Saves or updates an attendance record in Cloud Firestore under `schools/{schoolId}/attendance/{date}`.
  Future<void> saveAttendanceRecord({
    required String schoolId,
    required String date,
    required double attendancePercentage,
    int? totalStudents,
    int? presentStudents,
  }) async {
    try {
      await _db
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .doc(date)
          .set({
        'id': date,
        'schoolId': schoolId,
        'date': date,
        'attendancePercentage': attendancePercentage,
        if (totalStudents != null) 'totalStudents': totalStudents,
        if (presentStudents != null) 'presentStudents': presentStudents,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
