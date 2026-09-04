import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/govt_inspection_station_model.dart';

final govtInspectionRepositoryProvider = Provider<GovtInspectionRepository>((ref) {
  return GovtInspectionRepository();
});

final govtStationsProvider = StateNotifierProvider<GovtStationsNotifier, List<GovtWaterInspectionStation>>((ref) {
  return GovtStationsNotifier(ref.watch(govtInspectionRepositoryProvider));
});

class GovtInspectionRepository {
  final List<GovtWaterInspectionStation> _stations = [
    GovtWaterInspectionStation(
      id: 'STN-JH-001',
      stationName: 'ESP001 Ranchi Subarnarekha Station',
      district: 'Ranchi',
      state: 'Jharkhand',
      latitude: 23.3441,
      longitude: 85.3096,
      purityScore: 94.0,
      grade: 'EXCELLENT',
      ph: 7.2,
      tds: 185.0,
      turbidity: 0.4,
      salinity: 0.15,
      temperature: 24.5,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(hours: 2)),
      inspectorNotes: 'Official BIS IS 10500 compliant. Jharkhand Water Resources Dept Certified.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-008',
      stationName: 'Barharwa Municipal Sampling Station',
      district: 'Barharwa',
      state: 'Jharkhand',
      latitude: 24.8550,
      longitude: 87.7780,
      purityScore: 86.0,
      grade: 'GOOD',
      ph: 7.3,
      tds: 195.0,
      turbidity: 0.6,
      salinity: 0.18,
      temperature: 25.2,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(hours: 1)),
      inspectorNotes: 'Barharwa ground & surface water sampling complete. BIS IS 10500 compliant.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-002',
      stationName: 'Jamshedpur Swarnarekha Confluence',
      district: 'East Singhbhum',
      state: 'Jharkhand',
      latitude: 22.8046,
      longitude: 86.2029,
      purityScore: 68.0,
      grade: 'MODERATE',
      ph: 7.8,
      tds: 410.0,
      turbidity: 3.1,
      salinity: 0.45,
      temperature: 27.2,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(hours: 8)),
      inspectorNotes: 'Industrial outflow area. Sedimentation filtration active.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-003',
      stationName: 'Dhanbad Damodar River Station',
      district: 'Dhanbad',
      state: 'Jharkhand',
      latitude: 23.7957,
      longitude: 86.4304,
      purityScore: 42.0,
      grade: 'POOR / UNSAFE',
      ph: 8.6,
      tds: 670.0,
      turbidity: 8.2,
      salinity: 1.2,
      temperature: 28.5,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(hours: 5)),
      inspectorNotes: 'Coal belt runoff detected. High turbidity & TDS. Action notice served.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-004',
      stationName: 'Bokaro Garga Reservoir Point',
      district: 'Bokaro',
      state: 'Jharkhand',
      latitude: 23.6693,
      longitude: 86.1511,
      purityScore: 88.0,
      grade: 'GOOD',
      ph: 7.3,
      tds: 220.0,
      turbidity: 0.8,
      salinity: 0.2,
      temperature: 25.0,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(days: 1)),
      inspectorNotes: 'Reservoir water within optimal BIS IS 10500 drinking standards.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-005',
      stationName: 'Hazaribagh Lake Monitoring Hub',
      district: 'Hazaribagh',
      state: 'Jharkhand',
      latitude: 23.9925,
      longitude: 85.3637,
      purityScore: 78.0,
      grade: 'GOOD',
      ph: 7.1,
      tds: 290.0,
      turbidity: 1.2,
      salinity: 0.3,
      temperature: 24.1,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(hours: 14)),
      inspectorNotes: 'Lake ecosystem sampling complete. Minor organic turbidity.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-006',
      stationName: 'Deoghar Mayurakshi Intake Station',
      district: 'Deoghar',
      state: 'Jharkhand',
      latitude: 24.4826,
      longitude: 86.6967,
      purityScore: 84.0,
      grade: 'GOOD',
      ph: 7.4,
      tds: 210.0,
      turbidity: 0.7,
      salinity: 0.18,
      temperature: 26.0,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(days: 2)),
      inspectorNotes: 'Temple city water supply verified safe for pilgrims & residents.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-JH-007',
      stationName: 'Palamu North Koel Sampling Station',
      district: 'Palamu',
      state: 'Jharkhand',
      latitude: 24.0326,
      longitude: 84.0706,
      purityScore: 35.0,
      grade: 'POOR / CRITICAL',
      ph: 8.8,
      tds: 780.0,
      turbidity: 10.5,
      salinity: 1.6,
      temperature: 29.3,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(hours: 4)),
      inspectorNotes: 'High alkalinity and mineral hardness. Immediate RO treatment required.',
    ),
  ];

  List<GovtWaterInspectionStation> getStations() {
    return List.unmodifiable(_stations);
  }
}

class GovtStationsNotifier extends StateNotifier<List<GovtWaterInspectionStation>> {
  GovtStationsNotifier(GovtInspectionRepository repository) : super(repository.getStations());

  void verifyStation(String stationId, String inspectorNotes) {
    state = [
      for (final station in state)
        if (station.id == stationId)
          station.copyWith(
            isVerifiedByGovt: true,
            lastInspected: DateTime.now(),
            inspectorNotes: inspectorNotes,
          )
        else
          station,
    ];
  }
}
