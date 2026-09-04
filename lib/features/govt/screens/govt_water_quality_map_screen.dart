import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/govt_inspection_station_model.dart';
import '../../../repositories/govt_inspection_repository.dart';

class GovtWaterQualityMapScreen extends ConsumerStatefulWidget {
  const GovtWaterQualityMapScreen({super.key});

  @override
  ConsumerState<GovtWaterQualityMapScreen> createState() => _GovtWaterQualityMapScreenState();
}

class _GovtWaterQualityMapScreenState extends ConsumerState<GovtWaterQualityMapScreen> {
  GovtWaterInspectionStation? _selectedStation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stations = ref.watch(govtStationsProvider);
    final verifiedCount = stations.where((s) => s.isVerifiedByGovt).length;
    final unsafeCount = stations.where((s) => s.purityScore < 50).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'GOVT WATER AUTHORITY PORTAL',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'JAL SHAKTI / SIH INSPECTOR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Cards
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildStatTile('Total Stations', '${stations.length}', Icons.sensors_outlined, theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  _buildStatTile('Verified 🟢', '$verifiedCount', Icons.verified_rounded, AppColors.excellent),
                  const SizedBox(width: 8),
                  _buildStatTile('Unsafe 🔴', '$unsafeCount', Icons.warning_rounded, AppColors.poor),
                ],
              ),
            ),

            // Spatial GIS Map View Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Stack(
                  children: [
                    // Grid / Topo Map Background Pattern
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: MapGridPainter(
                            gridColor: theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ),

                    // Map Title overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'National GIS Water Quality Monitoring Map',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Simulated India Map Coordinates Pin Overlay
                    ...stations.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final station = entry.value;

                      // Map layout positioning coordinates
                      final topOffsets = [100.0, 180.0, 310.0, 210.0, 360.0];
                      final leftOffsets = [120.0, 220.0, 60.0, 210.0, 140.0];

                      final top = topOffsets[idx % topOffsets.length];
                      final left = leftOffsets[idx % leftOffsets.length];
                      final pinColor = _getPinColor(station.purityScore);

                      final isSelected = _selectedStation?.id == station.id;

                      return Positioned(
                        top: top,
                        left: left,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedStation = station;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: pinColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: pinColor.withValues(alpha: 0.5),
                                      blurRadius: isSelected ? 12 : 6,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  station.isVerifiedByGovt ? Icons.verified : Icons.water_drop,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: pinColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  station.stationName.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: pinColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    if (_selectedStation == null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tap any map station pin above to inspect regional water metrics & verify Jal Shakti compliance.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Station Details Inspection Card Bottom Drawer
            if (_selectedStation != null)
              _buildInspectionDetailCard(context, _selectedStation!, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPinColor(double score) {
    if (score >= 80) return AppColors.excellent;
    if (score >= 50) return AppColors.moderate;
    return AppColors.poor;
  }

  Widget _buildInspectionDetailCard(
    BuildContext context,
    GovtWaterInspectionStation station,
    ThemeData theme,
  ) {
    final statusColor = _getPinColor(station.purityScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.stationName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${station.district}, ${station.state} • Lat: ${station.latitude}, Long: ${station.longitude}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _selectedStation = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Parameter grid metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricBadge('Score', '${station.purityScore.round()}/100', statusColor),
              _buildMetricBadge('pH', '${station.ph}', AppColors.excellent),
              _buildMetricBadge('TDS', '${station.tds.round()} ppm', AppColors.excellent),
              _buildMetricBadge('Turbidity', '${station.turbidity} NTU', AppColors.excellent),
              _buildMetricBadge('Salinity', '${station.salinity} ppt', AppColors.excellent),
            ],
          ),
          const SizedBox(height: 12),

          // Inspector notes
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.notes_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Inspector Notes: ${station.inspectorNotes}',
                    style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Verification Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: station.isVerifiedByGovt
                  ? null
                  : () {
                      ref.read(govtStationsProvider.notifier).verifyStation(
                            station.id,
                            'Verified by Official Govt Inspector. Compliant with BIS IS 10500 standards.',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Jal Shakti Official Certificate issued for ${station.stationName}!'),
                          backgroundColor: AppColors.excellent,
                        ),
                      );
                      setState(() {
                        _selectedStation = station.copyWith(isVerifiedByGovt: true);
                      });
                    },
              icon: Icon(
                station.isVerifiedByGovt ? Icons.check_circle_rounded : Icons.verified_user_outlined,
                size: 18,
              ),
              label: Text(
                station.isVerifiedByGovt
                    ? 'VERIFIED & CERTIFIED BY GOVT AUTHORITY 🟢'
                    : 'Verify Station & Issue Official Certificate',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: station.isVerifiedByGovt ? AppColors.excellent : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 1),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  final Color gridColor;

  MapGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
