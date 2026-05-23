import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/test_result.dart';
import '../../services/storage_service.dart';
import '../../services/gait_api_service.dart';
import '../../services/sensor_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

final gaitApiServiceProvider = Provider<GaitApiService>((ref) {
  return GaitApiService();
});

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  ref.onDispose(() => service.dispose());
  return service;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref.read(storageServiceProvider));
});

class DarkModeNotifier extends StateNotifier<bool> {
  final StorageService _storageService;

  DarkModeNotifier(this._storageService) : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    state = await _storageService.isDarkMode();
  }

  Future<void> toggle() async {
    state = !state;
    await _storageService.setDarkMode(state);
  }
}

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
      return OnboardingNotifier(ref.read(storageServiceProvider));
    });

class OnboardingNotifier extends StateNotifier<bool> {
  final StorageService _storageService;

  OnboardingNotifier(this._storageService) : super(false) {
    _loadOnboardingStatus();
  }

  Future<void> _loadOnboardingStatus() async {
    state = await _storageService.isOnboardingComplete();
  }

  Future<void> complete() async {
    state = true;
    await _storageService.setOnboardingComplete(true);
  }
}

final testHistoryProvider =
    StateNotifierProvider<TestHistoryNotifier, List<TestResult>>((ref) {
      return TestHistoryNotifier(ref.read(storageServiceProvider));
    });

class TestHistoryNotifier extends StateNotifier<List<TestResult>> {
  final StorageService _storageService;

  TestHistoryNotifier(this._storageService) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    state = await _storageService.getTestHistory();
  }

  Future<void> addResult(TestResult result) async {
    await _storageService.saveTestResult(result);
    state = [result, ...state];
  }

  Future<void> clearHistory() async {
    await _storageService.clearTestHistory();
    state = [];
  }
}

final lastTestResultProvider = Provider<TestResult?>((ref) {
  final history = ref.watch(testHistoryProvider);
  return history.isNotEmpty ? history.first : null;
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier(ref.read(storageServiceProvider));
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final StorageService _storageService;

  UserProfileNotifier(this._storageService) : super(UserProfile.empty()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storageService.getUserProfile();
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _storageService.saveUserProfile(profile);
    state = profile;
  }
}

enum WalkTestState { idle, preparing, collecting, analyzing, completed, error }

class WalkTestStatus {
  final WalkTestState state;
  final int remainingSeconds;
  final TestResult? result;
  final String? errorMessage;

  const WalkTestStatus({
    this.state = WalkTestState.idle,
    this.remainingSeconds = 30,
    this.result,
    this.errorMessage,
  });

  WalkTestStatus copyWith({
    WalkTestState? state,
    int? remainingSeconds,
    TestResult? result,
    String? errorMessage,
  }) {
    return WalkTestStatus(
      state: state ?? this.state,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final walkTestProvider =
    StateNotifierProvider<WalkTestNotifier, WalkTestStatus>((ref) {
      return WalkTestNotifier(
        sensorService: ref.read(sensorServiceProvider),
        apiService: ref.read(gaitApiServiceProvider),
        historyNotifier: ref.read(testHistoryProvider.notifier),
      );
    });

class WalkTestNotifier extends StateNotifier<WalkTestStatus> {
  final SensorService _sensorService;
  final GaitApiService _apiService;
  final TestHistoryNotifier _historyNotifier;

  WalkTestNotifier({
    required SensorService sensorService,
    required GaitApiService apiService,
    required TestHistoryNotifier historyNotifier,
  }) : _sensorService = sensorService,
       _apiService = apiService,
       _historyNotifier = historyNotifier,
       super(const WalkTestStatus());

  Future<void> startTest() async {
    state = state.copyWith(state: WalkTestState.preparing);

    await Future.delayed(const Duration(seconds: 3));

    state = state.copyWith(
      state: WalkTestState.collecting,
      remainingSeconds: 30,
    );
    _sensorService.startRecording();

    for (int i = 30; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (state.state != WalkTestState.collecting) return;
      state = state.copyWith(remainingSeconds: i - 1);
    }

    final sensorData = _sensorService.stopRecording();
    state = state.copyWith(state: WalkTestState.analyzing);

    try {
      final prediction = await _apiService.analyzeGait(sensorData);

      if (prediction.containsKey('error')) {
        state = state.copyWith(
          state: WalkTestState.error,
          errorMessage: prediction['error'] as String,
        );
        return;
      }

      final result = TestResult.fromPrediction(prediction, sensorData);
      await _historyNotifier.addResult(result);

      state = state.copyWith(state: WalkTestState.completed, result: result);
    } catch (e) {
      state = state.copyWith(
        state: WalkTestState.error,
        errorMessage: 'Failed to analyze gait data: $e',
      );
    }
  }

  void cancelTest() {
    _sensorService.stopRecording();
    state = const WalkTestStatus();
  }

  void reset() {
    state = const WalkTestStatus();
  }
}

final currentTabProvider = StateProvider<int>((ref) => 0);
