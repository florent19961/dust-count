import 'package:flutter/material.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/shared/utils/string_helpers.dart';

/// Reusable member avatar widget showing initials in a colored circle.
///
/// Uses the stable [colorIndex] (persisted in Firestore) to pick a color
/// from [AppColors.memberColors], consistent with the rest of the app.
class MemberAvatar extends StatelessWidget {
  final String displayName;
  final int colorIndex;
  final double size;

  const MemberAvatar({
    super.key,
    required this.displayName,
    required this.colorIndex,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(displayName);
    final backgroundColor = AppColors.getMemberColor(colorIndex);
    final luminance = backgroundColor.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
