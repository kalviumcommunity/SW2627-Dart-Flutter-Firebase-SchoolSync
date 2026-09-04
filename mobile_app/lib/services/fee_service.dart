import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_period_model.dart';

class FeeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches fee periods/dues for a specific school strictly from Cloud Firestore.
  Future<List<FeePeriodModel>> getSchoolFeePeriods(String schoolId) async {
    try {
      final snap = await _db
          .collection('schools')
          .doc(schoolId)
          .collection('feePeriods')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));

      return snap.docs.map((d) => FeePeriodModel.fromFirestore(d)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Updates or inserts a fee period document in Cloud Firestore under `schools/{schoolId}/feePeriods/{feePeriodId}`.
  Future<void> updateFeePeriod({
    required String schoolId,
    required String feePeriodId,
    required double totalSubmitted,
    required double pendingAmount,
    double? totalDue,
    String? status,
  }) async {
    try {
      final due = totalDue ?? (totalSubmitted + pendingAmount);
      final rate = due > 0 ? (totalSubmitted / due) * 100 : 0.0;

      await _db
          .collection('schools')
          .doc(schoolId)
          .collection('feePeriods')
          .doc(feePeriodId)
          .set({
        'id': feePeriodId,
        'schoolId': schoolId,
        'totalSubmitted': totalSubmitted,
        'pendingAmount': pendingAmount,
        'totalDue': due,
        'submissionRate': rate,
        if (status != null) 'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
