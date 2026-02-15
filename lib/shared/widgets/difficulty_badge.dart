import 'package:flutter/material.dart';
import 'package:dust_count/core/constants/app_constants.dart';


/// Badge widget displaying task difficulty with emoji and colored background
class DifficultyBadge extends StatelessWidget {
  /// Task difficulty level
  final TaskDifficulty difficulty;

  /// Optional compact mode (smaller size)
  final bool compact;

  const DifficultyBadge({
    required this.difficulty,
    this.compact = false,
    super.key,
  });

  String get _emoji => AppConstants.difficultyEmojis[difficulty]!;
  String get _label => AppConstants.difficultyLabels[difficulty]!;

  /// Background color for difficulty badge (dark theme tints)
  static final _backgroundColors = {
    TaskDifficulty.plaisir: const Color(0xFF1B5E20),
    TaskDifficulty.reloo: const Color(0xFFE65100).withOpacity(0.25),
    TaskDifficulty.infernal: const Color(0xFFB71C1C).withOpacity(0.25),
  };

  Color get _backgroundColor => _backgroundColors[difficulty]!;

  /// Text color for difficulty badge (dark theme)
  static const _textColors = {
    TaskDifficulty.plaisir: Color(0xFFA5D6A7),
    TaskDifficulty.reloo: Color(0xFFFFCC80),
    TaskDifficulty.infernal: Color(0xFFEF9A9A),
  };

  Color get _textColor => _textColors[difficulty]!;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _emoji,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    return Chip(
      avatar: Text(
        _emoji,
        style: const TextStyle(fontSize: 16),
      ),
      label: Text(
        _label,
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      backgroundColor: _backgroundColor,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
