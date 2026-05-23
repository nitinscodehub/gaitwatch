class AppConstants {
  static const String appName = 'GaitWatch';
  static const String appTagline = 'Early Detection, Better Care';

  static const int walkTestDuration = 30;
  static const int onboardingSlides = 3;

  static const String riskLow = 'Low Risk';
  static const String riskModerate = 'Moderate Risk';
  static const String riskHigh = 'High Risk';
  static const String riskHealthy = 'Healthy';
  static const String riskWarning = 'Warning';
  static const String riskCritical = 'Critical';

  static const double riskScoreLow = 33.0;
  static const double riskScoreModerate = 66.0;

  static const String apiBaseUrl = 'https://api.gaitwatch.com';
  static const String predictEndpoint = '/predict';

  static const String onboardingTitle1 = 'Early Detection of Parkinson\'s';
  static const String onboardingDesc1 =
      'Detect early signs of Parkinson\'s disease through advanced gait analysis technology.';

  static const String onboardingTitle2 = 'Walk Test with Sensors';
  static const String onboardingDesc2 =
      'Simply place your phone in your pocket and walk naturally for 30 seconds.';

  static const String onboardingTitle3 = 'AI-Powered Analysis';
  static const String onboardingDesc3 =
      'Our secure AI model analyzes your gait patterns for early risk indicators.';

  static const String walkTestInstruction =
      'Place your phone in your pocket and walk naturally for 30 seconds.';
}

class StorageKeys {
  static const String onboardingComplete = 'onboarding_complete';
  static const String darkMode = 'dark_mode';
  static const String testHistory = 'test_history';
  static const String userProfile = 'user_profile';
}
