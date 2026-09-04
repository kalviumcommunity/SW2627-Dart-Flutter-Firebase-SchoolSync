import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';

class ExamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches scheduled exams for a specific school strictly from Cloud Firestore.
  Future<List<ExamModel>> getSchoolExams(String schoolId) async {
    try {
      final snap = await _db
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .orderBy('scheduledDate', descending: false)
          .get()
          .timeout(const Duration(seconds: 8));

      return snap.docs.map((d) => ExamModel.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates status of an exam in Cloud Firestore under `schools/{schoolId}/exams/{examId}`.
  Future<void> updateExamStatus({
    required String schoolId,
    required String examId,
    required String newStatus,
  }) async {
    try {
      await _db
          .collection('schools')
          .doc(schoolId)
          .collection('exams')
          .doc(examId)
          .set({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
