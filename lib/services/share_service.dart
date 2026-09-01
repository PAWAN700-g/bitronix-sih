import 'package:share_plus/share_plus.dart';
import '../core/constants/app_constants.dart';

class ShareService {
  Future<void> shareApp() async {
    const text = 'Check out ${AppConstants.sihProjectTitle}! '
        'Monitor water pH, TDS, Turbidity, & Temperature in real-time with smart IoT automation.';
    await Share.share(text, subject: AppConstants.appName);
  }
}
