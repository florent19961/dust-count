import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                S.noDataAvailable,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
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
    final colors = _getColors(entries.length);

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
    final colors = _getColors(entries.length);

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final userId = entry.value.key;
        final minutes = entry.value.value;
        final displayName = widget.memberNames[userId] ?? 'Unknown';

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
                  '(${_formatMinutes(minutes)})',
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

  /// Get color palette for chart sections
  List<Color> _getColors(int count) {
    return [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
      const Color(0xFF3B82F6), // Blue
    ];
  }

  /// Format minutes as "Xh Ym" or "Ym"
  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes > 0) {
        return '${hours}h ${remainingMinutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }
}
