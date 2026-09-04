import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/signup_model.dart';
import '../models/login_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Verifies if a given district ID exists in Firestore by checking the schools collection.
  Future<bool> checkDistrictExists(String districtId) async {
    final cleanId = districtId.trim().toUpperCase();
    if (cleanId.isEmpty) return false;
    try {
      final snap = await _db
          .collection('schools')
          .where('districtId', isEqualTo: cleanId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      return snap.docs.isNotEmpty;
    } catch (e) {
      // If network fails or timeout, rethrow so caller knows
      rethrow;
    }
  }

  Future<User?> signUp(SignupModel signupData) async {
    final districtId = signupData.districtId.trim().toUpperCase();

    // 1. Verify district exists BEFORE creating Firebase Auth user
    final exists = await checkDistrictExists(districtId);
    if (!exists) {
      throw Exception('District ID "$districtId" does not exist in the district registry.');
    }

    try {
      final UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: signupData.email,
        password: signupData.password,
      );

      final User? user = result.user;

      if (user != null) {
        await user.updateDisplayName(signupData.name);
        await user.reload();

        // Create user profile document in Firestore users/{uid}
        await UserService().saveUserProfile(
          UserModel(
            uid: user.uid,
            email: user.email ?? signupData.email,
            name: signupData.name,
            role: 'district_admin',
            districtId: districtId,
          ),
        );

        return _auth.currentUser;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<User?> signIn(LoginModel loginData) async {
    try {
      final UserCredential result =
          await _auth.signInWithEmailAndPassword(
        // EmailIdentifier is the public getter that normalises the email
        // for consistent backend searching/lookup.
        email: loginData.emailIdentifier,
        password: loginData.password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign In with Email and Password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Translate Firebase codes into readable messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak (minimum 6 characters).';

      case 'email-already-in-use':
        return 'An account already exists for that email.';

      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/Password auth is not enabled in Firebase Console.';

      // Login-specific codes
      case 'user-not-found':
        return 'No account found for that email address.';

      case 'wrong-password':
        return 'Incorrect password. Please try again.';

      case 'user-disabled':
        return 'This account has been disabled. Contact support.';

      case 'too-many-requests':
        return 'Too many failed attempts. Please wait and try again.';

      case 'invalid-credential':
        return 'Invalid email or password.';

      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}