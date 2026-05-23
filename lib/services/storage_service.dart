import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/test_result.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<bool> isOnboardingComplete() async {
    return _prefs.getBool(StorageKeys.onboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(StorageKeys.onboardingComplete, value);
  }

  Future<bool> isDarkMode() async {
    return _prefs.getBool(StorageKeys.darkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(StorageKeys.darkMode, value);
  }

  Future<List<TestResult>> getTestHistory() async {
    final String? historyJson = _prefs.getString(StorageKeys.testHistory);
    if (historyJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded
          .map((json) => TestResult.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTestResult(TestResult result) async {
    final history = await getTestHistory();
    history.insert(0, result);

    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final encoded = jsonEncode(history.map((r) => r.toJson()).toList());
    await _prefs.setString(StorageKeys.testHistory, encoded);
  }

  Future<void> clearTestHistory() async {
    await _prefs.remove(StorageKeys.testHistory);
  }

  Future<UserProfile?> getUserProfile() async {
    final String? profileJson = _prefs.getString(StorageKeys.userProfile);
    if (profileJson == null) return null;

    try {
      return UserProfile.fromJson(jsonDecode(profileJson));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final encoded = jsonEncode(profile.toJson());
    await _prefs.setString(StorageKeys.userProfile, encoded);
  }

  Future<TestResult?> getLastTestResult() async {
    final history = await getTestHistory();
    return history.isNotEmpty ? history.first : null;
  }
}
