import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      const _NavItemData(label: 'Board', icon: Icons.home_outlined, activeIcon: Icons.home),
      const _NavItemData(label: 'Attend.', icon: Icons.check_box_outlined, activeIcon: Icons.check_box),
      const _NavItemData(label: 'Fees', icon: Icons.monetization_on_outlined, activeIcon: Icons.monetization_on),
      const _NavItemData(label: 'Exams', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
      const _NavItemData(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D000000),
            offset: Offset(0, 6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = index == currentIndex;
          final item = navItems[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active pink indicator dot above selected item
                  Container(
                    height: 6,
                    width: 6,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFFC77885) : Colors.transparent,
                    ),
                  ),

                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 24,
                    color: isSelected ? AppColors.text : AppColors.secondaryText,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.text : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
