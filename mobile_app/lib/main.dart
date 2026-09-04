import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error catching to prevent red-screen crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('💥 [FlutterError]: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F1B2D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFC98591), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC7BDB3), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('🔥 Firebase initialized successfully');

    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Firebase initialization failed:\n\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SchoolSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A80F0),
          brightness: Brightness.dark,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F1B2D),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4A80F0)),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
