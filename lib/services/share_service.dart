import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';

class ShareService {
  Future<void> shareApp() async {
    const text = 'Check out ${AppConstants.sihProjectTitle}! '
        'Monitor water pH, TDS, Turbidity, & Temperature in real-time with smart IoT automation.';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: AppConstants.appName,
      ),
    );
  }

  Future<void> shareWaterQualityReport(SensorReading reading, WaterQualityResult result) async {
    final reportText = '''
🌊 OFFICIAL WATER QUALITY TELEMETRY & ANALYTICS REPORT
-------------------------------------------------------
Device ID   : ${reading.deviceId}
Timestamp   : ${reading.timestamp.toLocal()}
Purity Score: ${result.overallScore.round()}/100 Grade: ${result.grade.name.toUpperCase()}

📊 LIVE REAL-TIME METRICS:
• pH Level   : ${reading.ph.toStringAsFixed(1)} (${result.phStatus})
• TDS Level  : ${reading.tds.toStringAsFixed(0)} ppm (${result.tdsStatus})
• Turbidity  : ${reading.turbidity.toStringAsFixed(1)} NTU (${result.turbidityStatus})
• Salinity   : ${reading.salinity.toStringAsFixed(2)} ppt (${result.salinityStatus})
• Temperature: ${reading.temperature.toStringAsFixed(1)} °C (${result.tempStatus})

📋 RECOMMENDATIONS:
• ${result.hasAlerts ? 'Alerts active: Perform filtration & sediment flushing.' : 'All water parameters optimal. Safe for drinking.'}

Certified compliant with BIS IS 10500 Drinking Water Standards.
Powered by ${AppConstants.sihProjectTitle}
''';

    await SharePlus.instance.share(
      ShareParams(
        text: reportText,
        subject: 'Water Quality Analytics Report - ${reading.deviceId}',
      ),
    );
  }
}
