class AppConstants {
  static const String appName = 'Smart Water Monitor';
  static const String sihProjectTitle = 'Smart Water Quality Monitoring & Filtration System';
  static const String defaultDeviceId = 'SWU-001';

  // Medical Disclaimer
  static const String medicalDisclaimer =
      'Thresholds are based on WHO/BIS drinking water guidelines for demonstration purposes. '
      'This application does not provide formal medical certification.';

  // Sensor Standard Thresholds
  static const double phMinOptimal = 6.5;
  static const double phMaxOptimal = 8.5;

  static const double tdsMaxOptimal = 300.0;
  static const double tdsMaxAcceptable = 500.0;

  static const double turbidityMaxOptimal = 1.0;
  static const double turbidityMaxAcceptable = 5.0;

  static const double tempMinOptimal = 15.0;
  static const double tempMaxOptimal = 30.0;
}
