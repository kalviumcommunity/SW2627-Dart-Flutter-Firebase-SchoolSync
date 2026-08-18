class SignupModel {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  SignupModel({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  bool get passwordsMatch => password == confirmPassword;
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