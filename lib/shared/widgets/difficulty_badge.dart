import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

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

  /// Get emoji for difficulty level
  String get _emoji {
    switch (difficulty) {
      case TaskDifficulty.plaisir:
        return '😊';
      case TaskDifficulty.reloo:
        return '😐';
      case TaskDifficulty.infernal:
        return '😩';
    }
  }

  /// Get label for difficulty level
  String get _label {
    switch (difficulty) {
      case TaskDifficulty.plaisir:
        return 'Plaisir';
      case TaskDifficulty.reloo:
        return 'Relou';
      case TaskDifficulty.infernal:
        return 'Infernal';
    }
  }

  /// Get background color for difficulty level (dark theme)
  Color get _backgroundColor {
    switch (difficulty) {
      case TaskDifficulty.plaisir:
        return const Color(0xFF1B5E20);
      case TaskDifficulty.reloo:
        return const Color(0xFFE65100).withOpacity(0.25);
      case TaskDifficulty.infernal:
        return const Color(0xFFB71C1C).withOpacity(0.25);
    }
  }

  /// Get text color for difficulty level (dark theme)
  Color get _textColor {
    switch (difficulty) {
      case TaskDifficulty.plaisir:
        return const Color(0xFFA5D6A7);
      case TaskDifficulty.reloo:
        return const Color(0xFFFFCC80);
      case TaskDifficulty.infernal:
        return const Color(0xFFEF9A9A);
    }
  }

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
