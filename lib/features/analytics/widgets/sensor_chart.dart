import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sensor_reading.dart';

class SensorChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<SensorReading> readings;
  final double Function(SensorReading) extractor;
  final Color lineColors;

  const SensorChart({
    super.key,
    required this.title,
    required this.unit,
    required this.readings,
    required this.extractor,
    required this.lineColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (readings.isEmpty) {
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: const SizedBox(
          height: 220,
          child: Center(child: Text('No historical sensor data for this range')),
        ),
      );
    }

    final latestValue = extractor(readings.last);

    final spots = readings.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final val = extractor(entry.value);
      return FlSpot(idx, val);
    }).toList();

    final actualMin = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final actualMax = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final avg = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    // Bounds for chart display
    final range = actualMax - actualMin;
    final padding = range == 0 ? (actualMax == 0 ? 1.0 : actualMax * 0.1) : range * 0.2;
    final displayMin = (actualMin - padding).clamp(0.0, 10000.0);
    final displayMax = actualMax + padding;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title, Current Value, and Stats Strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          latestValue.toStringAsFixed(1),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: lineColors,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Statistics Summary (Min / Avg / Max)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Min: ${actualMin.toStringAsFixed(1)} | Max: ${actualMax.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Avg: ${avg.toStringAsFixed(1)} $unit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: lineColors,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Line Chart
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minY: displayMin,
                  maxY: displayMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((displayMax - displayMin) / 3).clamp(0.1, 1000),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            val.toStringAsFixed(val >= 100 ? 0 : 1),
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (readings.length / 4).clamp(1, 100).toDouble(),
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < readings.length) {
                            final dt = readings[idx].timestamp;
                            return Text(
                              DateFormat('HH:mm').format(dt),
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColors,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColors.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
