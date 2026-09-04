class GovtWaterInspectionStation {
  final String id;
  final String stationName;
  final String district;
  final String state;
  final double latitude;
  final double longitude;
  final double purityScore;
  final String grade;
  final double ph;
  final double tds;
  final double turbidity;
  final double salinity;
  final double temperature;
  final bool isVerifiedByGovt;
  final DateTime lastInspected;
  final String inspectorNotes;
  final String category; // 'District HQ', 'Town Hub', 'Village Panchayat'
  final String areaLevel; // 'District', 'Town', 'Village'

  const GovtWaterInspectionStation({
    required this.id,
    required this.stationName,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.purityScore,
    required this.grade,
    required this.ph,
    required this.tds,
    required this.turbidity,
    required this.salinity,
    required this.temperature,
    required this.isVerifiedByGovt,
    required this.lastInspected,
    required this.inspectorNotes,
    this.category = 'District HQ',
    this.areaLevel = 'District',
  });

  GovtWaterInspectionStation copyWith({
    bool? isVerifiedByGovt,
    DateTime? lastInspected,
    String? inspectorNotes,
    String? category,
    String? areaLevel,
  }) {
    return GovtWaterInspectionStation(
      id: id,
      stationName: stationName,
      district: district,
      state: state,
      latitude: latitude,
      longitude: longitude,
      purityScore: purityScore,
      grade: grade,
      ph: ph,
      tds: tds,
      turbidity: turbidity,
      salinity: salinity,
      temperature: temperature,
      isVerifiedByGovt: isVerifiedByGovt ?? this.isVerifiedByGovt,
      lastInspected: lastInspected ?? this.lastInspected,
      inspectorNotes: inspectorNotes ?? this.inspectorNotes,
      category: category ?? this.category,
      areaLevel: areaLevel ?? this.areaLevel,
    );
  }
}
