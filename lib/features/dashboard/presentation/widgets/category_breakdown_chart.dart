import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dust_count/shared/strings.dart';
import 'package:dust_count/shared/models/household_category.dart';
import 'package:dust_count/shared/utils/category_helpers.dart';
import 'package:dust_count/features/dashboard/data/dashboard_repository.dart';

/// Toggle mode for the category breakdown chart
enum _ViewMode { minutes, count }

/// Stacked vertical bar chart showing per-category breakdown per member
class CategoryBreakdownChart extends StatefulWidget {
  final List<CategoryBreakdownEntry> entries;
  final List<HouseholdCategory> customCategories;

  const CategoryBreakdownChart({
    super.key,
    required this.entries,
    required this.customCategories,
  });

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  _ViewMode _viewMode = _ViewMode.minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
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

    final allCategoryIds = _getAllCategoryIds();

    return Column(
      children: [
        // Toggle minutes / count
        SegmentedButton<_ViewMode>(
          segments: [
            ButtonSegment(
              value: _ViewMode.minutes,
              label: Text(S.viewMinutes),
            ),
            ButtonSegment(
              value: _ViewMode.count,
              label: Text(S.viewTaskCount),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (selected) {
            setState(() {
              _viewMode = selected.first;
            });
          },
        ),
        const SizedBox(height: 20),
        // Chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxValue(allCategoryIds),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = widget.entries[group.x];
                    final lines = <String>[entry.displayName];
                    for (final catId in allCategoryIds) {
                      final value = _viewMode == _ViewMode.minutes
                          ? entry.minutesPerCategory[catId] ?? 0
                          : entry.countPerCategory[catId] ?? 0;
                      if (value > 0) {
                        final emoji = getCategoryEmoji(catId, widget.customCategories) ?? '';
                        final label = getCategoryLabel(catId, widget.customCategories);
                        final formatted = _viewMode == _ViewMode.minutes
                            ? S.formatMinutes(value)
                            : '$value';
                        lines.add('$emoji $label : $formatted');
                      }
                    }
                    return BarTooltipItem(
                      lines.join('\n'),
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= widget.entries.length) {
                        return const SizedBox.shrink();
                      }
                      final name = widget.entries[index].displayName;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          name.length > 10 ? '${name.substring(0, 10)}…' : name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _buildBarGroups(allCategoryIds),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        _buildLegend(theme, allCategoryIds),
      ],
    );
  }

  /// Collect all unique category IDs across all entries, in a stable order
  List<String> _getAllCategoryIds() {
    final ids = <String>{};
    for (final entry in widget.entries) {
      ids.addAll(entry.minutesPerCategory.keys);
      ids.addAll(entry.countPerCategory.keys);
    }
    // Order: built-in first (in their canonical order), then custom
    final builtInOrder = builtInCategories.map((c) => c.id).toList();
    final sorted = <String>[];
    for (final id in builtInOrder) {
      if (ids.contains(id)) sorted.add(id);
    }
    for (final id in ids) {
      if (!sorted.contains(id)) sorted.add(id);
    }
    return sorted;
  }

  double _getMaxValue(List<String> categoryIds) {
    double max = 0;
    for (final entry in widget.entries) {
      double total = 0;
      final data = _viewMode == _ViewMode.minutes
          ? entry.minutesPerCategory
          : entry.countPerCategory;
      for (final id in categoryIds) {
        total += (data[id] ?? 0).toDouble();
      }
      if (total > max) max = total;
    }
    return max > 0 ? max * 1.05 : 10;
  }

  List<BarChartGroupData> _buildBarGroups(List<String> categoryIds) {
    return widget.entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final data = _viewMode == _ViewMode.minutes
          ? entry.minutesPerCategory
          : entry.countPerCategory;

      double cumulative = 0;
      final rodStackItems = <BarChartRodStackItem>[];
      for (final categoryId in categoryIds) {
        final value = (data[categoryId] ?? 0).toDouble();
        if (value > 0) {
          final color = getCategoryColor(categoryId, widget.customCategories);
          rodStackItems.add(BarChartRodStackItem(
            cumulative,
            cumulative + value,
            color,
          ));
          cumulative += value;
        }
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: cumulative,
            rodStackItems: rodStackItems,
            width: 24,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildLegend(ThemeData theme, List<String> categoryIds) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categoryIds.map((categoryId) {
        final color = getCategoryColor(categoryId, widget.customCategories);
        final label = getCategoryLabel(categoryId, widget.customCategories);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
