import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/app/theme/app_colors.dart';
import 'package:dust_count/shared/widgets/chart_empty_state.dart';

/// Pie chart showing time distribution across household members
class TimeDistributionChart extends ConsumerStatefulWidget {
  final Map<String, int> minutesPerMember;
  final Map<String, String> memberNames;

  const TimeDistributionChart({
    super.key,
    required this.minutesPerMember,
    required this.memberNames,
  });

  @override
  ConsumerState<TimeDistributionChart> createState() =>
      _TimeDistributionChartState();
}

class _TimeDistributionChartState
    extends ConsumerState<TimeDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.minutesPerMember.isEmpty) {
      return const ChartEmptyState(icon: Icons.pie_chart_outline);
    }

    final totalMinutes = widget.minutesPerMember.values.fold<int>(
      0,
      (sum, minutes) => sum + minutes,
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _buildSections(totalMinutes),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(theme),
      ],
    );
  }

  /// Build pie chart sections
  List<PieChartSectionData> _buildSections(int totalMinutes) {
    final entries = widget.minutesPerMember.entries.toList();
    final colors = AppColors.chartColors;

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final minutes = entry.value.value;
      final isTouched = index == touchedIndex;

      final percentage = (minutes / totalMinutes * 100);
      final radius = isTouched ? 70.0 : 60.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      return PieChartSectionData(
        color: colors[index],
        value: minutes.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  /// Build legend showing members and their totals
  Widget _buildLegend(ThemeData theme) {
    final entries = widget.minutesPerMember.entries.toList();
    final colors = AppColors.chartColors;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final userId = entry.value.key;
        final minutes = entry.value.value;
        final displayName = widget.memberNames[userId] ?? S.unknownMember;

        return InkWell(
          onTap: () {
            setState(() {
              touchedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: touchedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${S.formatMinutes(minutes)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }


}
