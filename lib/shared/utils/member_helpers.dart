import 'package:flutter/material.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/shared/models/household.dart';

/// Resolves the display color for a given user within a household.
///
/// Looks up the member's stable `colorIndex` from [household.members]
/// and returns the corresponding [AppColors.getMemberColor]. Falls back
/// to the first member color if the user is not found.
Color getMemberColor(Household household, String userId) {
  final member = household.members
      .where((m) => m.userId == userId)
      .firstOrNull;

  return AppColors.getMemberColor(member?.colorIndex ?? 0);
}
