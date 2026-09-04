import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
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
  final MapController _mapController = MapController();
  String _selectedFilter = 'All'; // 'All', 'District', 'Town', 'Village'
  int _selectedTileIndex = 0;

  static const List<Map<String, String>> _tileProviders = [
    {
      'name': 'CARTO Voyager (Recommended)',
      'url': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      'subdomains': 'a,b,c,d',
    },
    {
      'name': 'Esri World Street Map',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      'subdomains': '',
    },
    {
      'name': 'OpenStreetMap Standard',
      'url': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      'subdomains': 'a,b,c',
    },
    {
      'name': 'CARTO Positron Light',
      'url': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
      'subdomains': 'a,b,c,d',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allStations = ref.watch(govtStationsProvider);

    final filteredStations = _selectedFilter == 'All'
        ? allStations
        : allStations.where((s) => s.areaLevel == _selectedFilter).toList();

    final verifiedCount = allStations.where((s) => s.isVerifiedByGovt).length;
    final unsafeCount = allStations.where((s) => s.purityScore < 50).length;

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
                'JHARKHAND WATER AUTHORITY PORTAL',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              'JHARKHAND GOVT / SIH',
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
                  _buildStatTile('Jharkhand Hubs', '${allStations.length}', Icons.sensors_outlined, theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  _buildStatTile('Verified 🟢', '$verifiedCount', Icons.verified_rounded, AppColors.excellent),
                  const SizedBox(width: 8),
                  _buildStatTile('Unsafe 🔴', '$unsafeCount', Icons.warning_rounded, AppColors.poor),
                ],
              ),
            ),

            // Category Level Selector Chips (District, Town, Village)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All (${allStations.length})', 'All', Icons.map_rounded),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Districts (${allStations.where((s) => s.areaLevel == 'District').length})',
                      'District',
                      Icons.location_city_rounded,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Towns (${allStations.where((s) => s.areaLevel == 'Town').length})',
                      'Town',
                      Icons.holiday_village_rounded,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Villages (${allStations.where((s) => s.areaLevel == 'Village').length})',
                      'Village',
                      Icons.home_work_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // OpenStreetMap Spatial GIS Container (Jharkhand Focus)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(23.6102, 85.2799),
                          initialZoom: 7.5,
                          minZoom: 6.0,
                          maxZoom: 18.0,
                          onTap: (_, _) {
                            setState(() {
                              _selectedStation = null;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: _tileProviders[_selectedTileIndex]['url']!,
                            subdomains: _tileProviders[_selectedTileIndex]['subdomains']!.isNotEmpty
                                ? _tileProviders[_selectedTileIndex]['subdomains']!.split(',')
                                : const [],
                            tileProvider: NetworkTileProvider(
                              headers: {
                                'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                              },
                            ),
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: _buildFlutterMapMarkers(filteredStations, theme),
                          ),
                        ],
                      ),

                      // Map Header Title overlay
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${_tileProviders[_selectedTileIndex]['name']} (Jharkhand)',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Map Layer Selector Button (Top Right)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: PopupMenuButton<int>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.layers_rounded, size: 18, color: AppColors.primary),
                          ),
                          tooltip: 'Switch Map Tile Provider',
                          initialValue: _selectedTileIndex,
                          onSelected: (index) {
                            setState(() {
                              _selectedTileIndex = index;
                            });
                          },
                          itemBuilder: (context) => List.generate(
                            _tileProviders.length,
                            (index) => PopupMenuItem<int>(
                              value: index,
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedTileIndex == index
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 16,
                                    color: _selectedTileIndex == index ? AppColors.primary : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _tileProviders[index]['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: _selectedTileIndex == index ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

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
                                    'Tap any District, Town, or Village marker to view purity scores & issue Jal Shakti certificates.',
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
            ),

            // Station Details Inspection Card Bottom Drawer
            if (_selectedStation != null)
              _buildInspectionDetailCard(context, _selectedStation!, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            _selectedStation = null;
          });
        }
      },
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

  void _onSelectStation(GovtWaterInspectionStation station) {
    setState(() {
      _selectedStation = station;
    });
    _mapController.move(
      LatLng(station.latitude, station.longitude),
      11.5,
    );
  }

  List<Marker> _buildFlutterMapMarkers(List<GovtWaterInspectionStation> stations, ThemeData theme) {
    return stations.map((station) {
      final pinColor = _getPinColor(station.purityScore);
      final isSelected = _selectedStation?.id == station.id;

      IconData levelIcon;
      switch (station.areaLevel) {
        case 'District':
          levelIcon = Icons.location_city_rounded;
          break;
        case 'Town':
          levelIcon = Icons.holiday_village_rounded;
          break;
        case 'Village':
        default:
          levelIcon = Icons.home_work_rounded;
          break;
      }

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: isSelected ? 120 : 90,
        height: isSelected ? 54 : 44,
        child: GestureDetector(
          onTap: () => _onSelectStation(station),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? pinColor : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pinColor, width: isSelected ? 2.5 : 1.5),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: isSelected ? 0.5 : 0.2),
                  blurRadius: isSelected ? 8 : 4,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: pinColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    levelIcon,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.district,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        '${station.purityScore.round()}% Purity',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : pinColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${station.areaLevel.toUpperCase()} LEVEL',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          station.category,
                          style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.stationName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'District: ${station.district}, ${station.state} • Lat: ${station.latitude}, Long: ${station.longitude}',
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
                            'Verified by Jharkhand Water Resources Dept. Compliant with BIS IS 10500 standards.',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Jharkhand Govt Approval Certificate issued for ${station.stationName}!'),
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
                    ? 'VERIFIED & CERTIFIED BY JHARKHAND GOVT 🟢'
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
