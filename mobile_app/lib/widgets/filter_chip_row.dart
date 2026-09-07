import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FilterChipItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final int? count;

  const FilterChipItem({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });
}

class FilterChipRow<T> extends StatelessWidget {
  final List<FilterChipItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const FilterChipRow({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelected(item.value),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.card : const Color(0x24000000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.card
                        : const Color(0x33FFFFFF),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x26000000),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 14,
                        color: isSelected ? const Color(0xFF22160E) : const Color(0xFFE2DCCE),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF22160E) : const Color(0xFFFAF7EF),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (item.count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF22160E).withAlpha(25)
                              : const Color(0x44FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.count}',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF22160E) : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
