import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model representing a document stored in Firestore `users/{uid}`.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'district_admin' or 'school_staff'
  final String districtId; // e.g. 'DIST001', 'DIST002'
  final String? schoolId; // e.g. 'SCH001' (if assigned to a specific school)

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.districtId,
    this.schoolId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'district_admin',
      districtId: data['districtId'] as String? ?? '',
      schoolId: data['schoolId'] as String?,
    );
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? 'district_admin',
      districtId: map['districtId'] as String? ?? '',
      schoolId: map['schoolId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'districtId': districtId,
      if (schoolId != null) 'schoolId': schoolId,
    };
  }
}
