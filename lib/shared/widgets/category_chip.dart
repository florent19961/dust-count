import 'package:flutter/material.dart';
import 'package:dust_count/shared/models/household_category.dart';

/// Chip widget displaying task category with icon and label
class CategoryChip extends StatelessWidget {
  /// Task category
  final HouseholdCategory category;

  /// Optional compact mode (icon only)
  final bool compact;

  /// Optional selected state
  final bool selected;

  /// Optional tap callback
  final VoidCallback? onTap;

  const CategoryChip({
    required this.category,
    this.compact = false,
    this.selected = false,
    this.onTap,
    super.key,
  });

  Widget _buildCategoryVisual({
    required double size,
    required Color color,
    required Color fallbackColor,
  }) {
    if (category.hasEmoji) {
      return Text(category.emoji!, style: TextStyle(fontSize: size));
    }
    return Icon(category.icon, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: _buildCategoryVisual(
            size: category.hasEmoji ? 18 : 20,
            color: selected ? color : colorScheme.onSurfaceVariant,
            fallbackColor: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return FilterChip(
      avatar: _buildCategoryVisual(
        size: category.hasEmoji ? 16 : 18,
        color: selected ? color : colorScheme.onSurfaceVariant,
        fallbackColor: colorScheme.onSurfaceVariant,
      ),
      label: Text(category.labelFr),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? color : colorScheme.outlineVariant,
        width: selected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
