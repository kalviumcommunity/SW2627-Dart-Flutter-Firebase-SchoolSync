import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/signup_model.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _districtIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _districtIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final signupData = SignupModel(
      name: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      districtId: _districtIdController.text.trim().toUpperCase(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    final validationError = signupData.validate();
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final districtId = signupData.districtId;
      final districtExists = await _authService.checkDistrictExists(districtId);
      if (!districtExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          await _showInvalidDistrictDialog(districtId);
        }
        return;
      }

      final user = await _authService.signUp(signupData);

      if (user != null && mounted) {
        _showMessage('Account created successfully for ${user.displayName ?? user.email}! 🎉');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        if (errorMsg.contains('does not exist in the district registry')) {
          await _showInvalidDistrictDialog(signupData.districtId);
        } else {
          _showMessage(errorMsg, isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showInvalidDistrictDialog(String districtId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2DCCE), width: 1.5),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0x26C98591),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.domain_disabled_rounded,
                  color: AppColors.pink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Invalid District ID',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'The District ID '),
                    TextSpan(
                      text: '"$districtId"',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' does not exist in the district schools registry.\n\n'
                          'Please verify with your district administrator or use a registered District ID (e.g. ',
                    ),
                    const TextSpan(
                      text: 'DIST001, DIST002, DIST003, DIST004, DIST005',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ').'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFC98591) : const Color(0xFF8FA57C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // ── Tilted Noticeboard Paper Card ─────────────────────────
                Transform.rotate(
                  angle: 0.015,
                  child: Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          // ── Title & Description ────────────────────────
                          const Text(
                            'Register an account',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Create administrator access for your district office.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Full Name Field ────────────────────────────
                          _buildLabel('FULL NAME'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _fullNameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _inputDecoration(
                              hint: 'Priya Nair',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Email Field ────────────────────────────────
                          _buildLabel('DISTRICT OFFICE EMAIL'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _inputDecoration(
                              hint: 'you@districtschools.in',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email.';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── District ID Field ──────────────────────────
                          _buildLabel('DISTRICT ID'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _districtIdController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _inputDecoration(
                              hint: 'e.g. DIST001, DIST002',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your District ID.';
                              }
                              if (value.trim().length < 2) {
                                return 'District ID must be at least 2 characters.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // ── Password Field ─────────────────────────────
                          _buildLabel('PASSWORD'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _inputDecoration(
                              hint: 'Set a password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.secondaryText,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password.';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'At least 6 characters.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Confirm Password Field ─────────────────────
                          _buildLabel('CONFIRM PASSWORD'),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitForm(),
                            style: const TextStyle(color: AppColors.text, fontSize: 15),
                            decoration: _inputDecoration(
                              hint: 'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.secondaryText,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── Create Account Pill Button ────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.text,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.text.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Sign In Redirect Link ─────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already registered? ',
                                style: TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign in instead',
                                  style: TextStyle(
                                    color: Color(0xFF5A7949),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF5A7949),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Top Right Decorative Striped Tape ────────────────────
                Positioned(
                  top: 0,
                  right: 20,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 72,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4BDC4).withValues(alpha: 0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Top Center Metallic Pushpin ───────────────────────────
                Positioned(
                  top: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFFD4DEC9), Color(0xFF7A8C70), Color(0xFF2C3A25)],
                        center: Alignment(-0.3, -0.3),
                        radius: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: Offset(1, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFC4BCB0), fontSize: 15),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      isDense: true,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFDDD5C6), width: 1.5),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFDDD5C6), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.text, width: 2.0),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFC98591), width: 1.5),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFC98591), width: 2.0),
      ),
    );
  }
}


