import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String? districtId;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.userName,
    this.districtId,
    this.onLogout,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = userName.length >= 2
        ? userName.substring(0, 2).toUpperCase()
        : (userName.isNotEmpty ? userName.toUpperCase() : 'PN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Sync Badge & District Admin Label Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              districtId != null && districtId!.isNotEmpty
                  ? 'DISTRICT ADMINISTRATOR · ${districtId!.toUpperCase()}'
                  : 'DISTRICT ADMINISTRATOR',
              style: const TextStyle(
                color: Color(0xFFC7BDB3),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x33000000),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x44FFFFFF), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF66BB6A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live Sync',
                        style: TextStyle(
                          color: AppColors.card,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onLogout != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.card, size: 20),
                    onPressed: onLogout,
                    tooltip: 'Sign Out',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Welcome Greeting & Profile Avatar Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Good morning, $userName',
                style: const TextStyle(
                  color: AppColors.card,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onProfileTap,
              child: Tooltip(
                message: 'View Profile',
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.yellow,
                    border: Border.all(color: AppColors.card, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials == 'PR' ? 'PN' : initials,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}