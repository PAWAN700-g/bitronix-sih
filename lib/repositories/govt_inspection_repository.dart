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
      id: 'STN-001',
      stationName: 'ESP001 SIH Smart Water Hub',
      district: 'Central Delhi',
      state: 'Delhi NCR',
      latitude: 28.6139,
      longitude: 77.2090,
      purityScore: 94.0,
      grade: 'EXCELLENT',
      ph: 7.2,
      tds: 185.0,
      turbidity: 0.4,
      salinity: 0.15,
      temperature: 24.5,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(hours: 2)),
      inspectorNotes: 'Official BIS IS 10500 compliant. Jal Shakti Certificate Issued.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-002',
      stationName: 'Yamuna River Monitoring Point #04',
      district: 'North East Delhi',
      state: 'Delhi',
      latitude: 28.6920,
      longitude: 77.2600,
      purityScore: 42.0,
      grade: 'POOR / UNSAFE',
      ph: 8.7,
      tds: 680.0,
      turbidity: 8.5,
      salinity: 1.4,
      temperature: 28.0,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(hours: 12)),
      inspectorNotes: 'High turbidity & elevated TDS detected. Filtration team dispatched.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-003',
      stationName: 'Mumbai Central Municipal Intake',
      district: 'Mumbai City',
      state: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
      purityScore: 82.0,
      grade: 'GOOD',
      ph: 7.4,
      tds: 240.0,
      turbidity: 0.9,
      salinity: 0.3,
      temperature: 26.2,
      isVerifiedByGovt: true,
      lastInspected: DateTime.now().subtract(const Duration(days: 1)),
      inspectorNotes: 'Standard municipal supply within BIS IS 10500 limits.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-004',
      stationName: 'Varanasi Ganga Ghat Sampling Hub',
      district: 'Varanasi',
      state: 'Uttar Pradesh',
      latitude: 25.3176,
      longitude: 82.9739,
      purityScore: 61.0,
      grade: 'MODERATE',
      ph: 7.9,
      tds: 420.0,
      turbidity: 3.2,
      salinity: 0.6,
      temperature: 27.5,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(days: 2)),
      inspectorNotes: 'Moderate organic suspended solids. Sediment filtration active.',
    ),
    GovtWaterInspectionStation(
      id: 'STN-005',
      stationName: 'Bengaluru Bellandur Outflow Station',
      district: 'Bengaluru Urban',
      state: 'Karnataka',
      latitude: 12.9352,
      longitude: 77.6670,
      purityScore: 38.0,
      grade: 'POOR / CRITICAL',
      ph: 8.9,
      tds: 790.0,
      turbidity: 11.2,
      salinity: 1.8,
      temperature: 29.1,
      isVerifiedByGovt: false,
      lastInspected: DateTime.now().subtract(const Duration(hours: 6)),
      inspectorNotes: 'Critical chemical oxygen demand breach. Action notice served.',
    ),
  ];

  List<GovtWaterInspectionStation> getStations() {
    return List.unmodifiable(_stations);
  }
}

class GovtStationsNotifier extends StateNotifier<List<GovtWaterInspectionStation>> {
  final GovtInspectionRepository _repository;

  GovtStationsNotifier(this._repository) : super(_repository.getStations());

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
