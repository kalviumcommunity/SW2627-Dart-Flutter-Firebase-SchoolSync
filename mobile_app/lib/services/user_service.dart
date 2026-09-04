import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches the user profile from Cloud Firestore `users/{uid}`.
  Future<UserModel> getUserProfile(
    String uid, {
    String? defaultEmail,
    String? defaultName,
    String? defaultDistrictId,
  }) async {
    try {
      final docSnap = await _db.collection('users').doc(uid).get();

      if (docSnap.exists && docSnap.data() != null) {
        return UserModel.fromFirestore(docSnap);
      }

      if (defaultDistrictId != null && defaultDistrictId.isNotEmpty) {
        final profile = UserModel(
          uid: uid,
          email: defaultEmail ?? '',
          name: defaultName ?? 'District Admin',
          role: 'district_admin',
          districtId: defaultDistrictId,
        );
        await saveUserProfile(profile);
        return profile;
      }

      throw Exception(
        'User profile not found for uid "$uid". Please ensure you have signed up with a valid District ID.',
      );
    } catch (e) {
      debugPrint('⚠️ [UserService] Error fetching user profile for $uid: $e');
      rethrow;
    }
  }

  /// Writes or updates a user profile document in `users/{uid}`.
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
      debugPrint('✅ [UserService] Profile saved successfully for ${user.uid}');
    } catch (e) {
      debugPrint('❌ [UserService] Failed to save user profile: $e');
      rethrow;
    }
  }
}
