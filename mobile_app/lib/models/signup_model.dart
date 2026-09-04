class SignupModel {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String districtId;

  SignupModel({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.districtId,
  });

  /// Alias for backward compatibility
  String get district => districtId;

  bool get passwordsMatch => password == confirmPassword;

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'districtId': districtId.trim(),
    };
  }

  /// Client-side validation for signup fields
  String? validate() {
    if (name.trim().isEmpty) return 'Please enter your full name.';
    if (email.trim().isEmpty) return 'Please enter your email.';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email.trim())) return 'Please enter a valid email address.';
    if (districtId.trim().isEmpty) return 'Please enter your District ID.';
    if (districtId.trim().length < 2) return 'District ID must be at least 2 characters.';
    if (password.isEmpty) return 'Please enter a password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (!passwordsMatch) return 'Passwords do not match.';
    return null;
  }
}

// class DistrictOfficerModel {
//   final String uid;
//   final String name;
//   final String email;
//   final String phoneNumber;

//   DistrictOfficerModel({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.phoneNumber,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'name': name,
//       'email': email,
//       'phoneNumber': phoneNumber,
//     };
//   }

//   factory DistrictOfficerModel.fromMap(Map<String, dynamic> map) {
//     return DistrictOfficerModel(
//       uid: map['uid'] ?? '',
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       phoneNumber: map['phoneNumber'] ?? '',
//     );
//   }
//}