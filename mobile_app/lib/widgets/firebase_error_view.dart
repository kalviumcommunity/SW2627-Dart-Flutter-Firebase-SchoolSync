import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FirebaseErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;

  const FirebaseErrorView({
    super.key,
    this.title = 'No Firestore Data Available',
    required this.message,
    this.onRetry,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0x26C98591),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 38,
                  color: AppColors.pink,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // Actionable Tips Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAE1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x338C847A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.text),
                        SizedBox(width: 6),
                        Text(
                          'Troubleshooting Tips',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Ensure Firestore Security Rules in Firebase Console allow read access.\n'
                      '• Verify that data has been seeded to your database collections.',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              if (onRetry != null) ...[
                const SizedBox(height: 24),

                // Retry Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      'Retry Connection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
              if (onLogout != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.text),
                    label: const Text(
                      'Sign Out / Switch Account',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBC5B8), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
