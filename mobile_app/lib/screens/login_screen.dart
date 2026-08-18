import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Used to control and validate the Form.
  final _formKey = GlobalKey<FormState>();

  // Gives us access to the authentication logic.
  final _authService = AuthService();

  // Controllers allow us to read what the user typed.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // UI state.
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Always dispose controllers when the screen is removed.
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submitForm() async {
    // First validate all fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Tell Flutter that the login request has started.
    setState(() {
      _isLoading = true;
    });

    try {
      // Ask AuthService to log the user in.
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check that the screen still exists before using context.
      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Navigate to the appropriate dashboard here.
      }
    } catch (e) {
      // Display authentication errors.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Login request has finished.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Page heading.
                Text(
                  'Sign In',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Log in to use SchoolSync',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ---------------------------------------------------------
                // EMAIL
                // ---------------------------------------------------------

                TextFormField(
                  controller: _emailController,

                  keyboardType: TextInputType.emailAddress,

                  textInputAction: TextInputAction.next,

                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    final emailRegex =
                        RegExp(r'^[^@]+@[^@]+\.[^@]+');

                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ---------------------------------------------------------
                // PASSWORD
                // ---------------------------------------------------------

                TextFormField(
                  controller: _passwordController,

                  obscureText: _obscurePassword,

                  // There is no field after password.
                  textInputAction: TextInputAction.done,

                  decoration: InputDecoration(
                    labelText: 'Password',

                    prefixIcon: const Icon(Icons.lock),

                    border: const OutlineInputBorder(),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }

                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // ---------------------------------------------------------
                // LOGIN BUTTON
                // ---------------------------------------------------------

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    backgroundColor:
                        Theme.of(context).colorScheme.primary,

                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimary,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}