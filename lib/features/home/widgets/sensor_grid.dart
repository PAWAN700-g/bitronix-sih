import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../models/water_quality_result.dart';
import 'sensor_card.dart';

class SensorGrid extends StatelessWidget {
  final SensorReading reading;
  final WaterQualityResult result;

  const SensorGrid({
    super.key,
    required this.reading,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        // 1. pH Card
        SensorCard(
          name: 'pH Level',
          value: reading.ph.toStringAsFixed(1),
          unit: '',
          status: result.phStatus,
          icon: Icons.science_outlined,
          accentColor: AppColors.phColor,
        ),

        // 2. TDS Card
        SensorCard(
          name: 'TDS Level',
          value: reading.tds.toStringAsFixed(0),
          unit: 'ppm',
          status: result.tdsStatus,
          icon: Icons.water_outlined,
          accentColor: AppColors.tdsColor,
        ),

        // 3. Turbidity Card
        SensorCard(
          name: 'Turbidity',
          value: reading.turbidity.toStringAsFixed(1),
          unit: 'NTU',
          status: result.turbidityStatus,
          icon: Icons.invert_colors_outlined,
          accentColor: AppColors.turbidityColor,
        ),

        // 4. Temperature Card
        SensorCard(
          name: 'Temperature',
          value: reading.temperature.toStringAsFixed(1),
          unit: '°C',
          status: result.tempStatus,
          icon: Icons.thermostat_outlined,
          accentColor: AppColors.tempColor,
        ),
      ],
    );
  }
}
