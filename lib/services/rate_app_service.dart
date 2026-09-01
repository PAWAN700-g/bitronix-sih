class RateAppService {
  Future<bool> requestReview() async {
    // In production, integrate in_app_review package.
    // For demo, return simulated success.
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
