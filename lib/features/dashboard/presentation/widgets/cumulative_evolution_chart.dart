import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/app/theme/app_colors.dart';

/// Line chart showing cumulative minutes over time per member
class CumulativeEvolutionChart extends ConsumerWidget {
  final Map<String, Map<String, int>> dailyCumulativeData;
  final Map<String, String> memberNames;
  final DateTime startDate;
  final DateTime endDate;

  const CumulativeEvolutionChart({
    super.key,
    required this.dailyCumulativeData,
    required this.memberNames,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (dailyCumulativeData.isEmpty ||
        dailyCumulativeData.values.every((data) => data.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart,
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

    final allDates = _getAllDates();
    final maxY = _getMaxY();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 5 : 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          S.formatMinutes(value.toInt()),
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: _getBottomInterval(allDates.length),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= allDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = allDates[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            S.formatDateShort(date),
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    bottom: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                ),
                minX: 0,
                maxX: (allDates.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: _buildLineBars(allDates, theme),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final userId = dailyCumulativeData.keys.elementAt(
                          spot.barIndex,
                        );
                        final displayName = memberNames[userId] ?? 'Unknown';
                        return LineTooltipItem(
                          '$displayName\n${S.formatMinutes(spot.y.toInt())}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(theme),
      ],
    );
  }

  /// Build line bars for each member
  List<LineChartBarData> _buildLineBars(
    List<DateTime> allDates,
    ThemeData theme,
  ) {
    final colors = AppColors.chartColors;
    final members = dailyCumulativeData.keys.toList();

    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final userId = entry.value;
      final userData = dailyCumulativeData[userId]!;

      final spots = <FlSpot>[];
      for (int i = 0; i < allDates.length; i++) {
        final dateKey = _formatDateKey(allDates[i]);
        final minutes = userData[dateKey] ?? (i > 0 && spots.isNotEmpty ? spots.last.y : 0);
        spots.add(FlSpot(i.toDouble(), minutes.toDouble()));
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: colors[index],
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 3,
              color: colors[entry.key],
              strokeWidth: 0,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colors[index].withOpacity(0.1),
        ),
      );
    }).toList();
  }

  /// Build legend showing members
  Widget _buildLegend(ThemeData theme) {
    final colors = AppColors.chartColors;
    final members = dailyCumulativeData.keys.toList();

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: members.asMap().entries.map((entry) {
        final index = entry.key;
        final userId = entry.value;
        final displayName = memberNames[userId] ?? 'Unknown';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Get all dates in the range
  List<DateTime> _getAllDates() {
    final dates = <DateTime>[];
    DateTime current = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    while (current.isBefore(end.add(const Duration(days: 1)))) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get maximum Y value for chart scaling
  double _getMaxY() {
    double max = 0;
    for (final userData in dailyCumulativeData.values) {
      for (final minutes in userData.values) {
        if (minutes > max) {
          max = minutes.toDouble();
        }
      }
    }
    return max > 0 ? max : 100;
  }

  /// Get interval for bottom axis labels
  double _getBottomInterval(int dateCount) {
    if (dateCount <= 7) return 1;
    if (dateCount <= 14) return 2;
    if (dateCount <= 30) return 5;
    return 7;
  }

  /// Format date as YYYY-MM-DD for consistent keys
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

}
