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
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No historical data available')),
      );
    }

    final latestValue = extractor(readings.last);
    final previousValue = readings.length > 1 ? extractor(readings[readings.length - 2]) : latestValue;
    final isUp = latestValue >= previousValue;

    final spots = readings.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final val = extractor(entry.value);
      return FlSpot(idx, val);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    // Padding for Y axis boundaries
    final padding = (maxY - minY) * 0.2;
    minY = (minY - (padding == 0 ? 1 : padding)).clamp(0, 1000);
    maxY = maxY + (padding == 0 ? 1 : padding);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          latestValue.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: lineColors,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(unit, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ],
                ),

                Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      color: isUp ? lineColors : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUp ? 'Trending Up' : 'Trending Down',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUp ? lineColors : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxY - minY) / 3).clamp(0.1, 1000),
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
                        reservedSize: 40,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            val.toStringAsFixed(1),
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
                        reservedSize: 24,
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
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColors.withValues(alpha: 0.15),
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
