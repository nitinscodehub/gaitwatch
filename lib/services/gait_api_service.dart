import 'dart:math';
import '../models/test_result.dart';

class GaitApiService {
  static const int minReadings = 100;
  static const double accelVarianceWeight = 0.5;
  static const double gyroVarianceWeight = 0.3;
  static const double stepIrregularityWeight = 0.2;

  Future<Map<String, dynamic>> analyzeGait(SensorData sensorData) async {
    final accel = sensorData.accelReadings;
    final gyro = sensorData.gyroReadings;

    if (accel.length < minReadings || gyro.length < minReadings) {
      return {
        'error': 'Insufficient data, please retry',
        'risk_score': 0,
        'status': 'Error',
        'confidence': 0.0,
        'dominant_factor': 'insufficient_data',
      };
    }

    final accelMagnitudes = accel.map((r) => r.magnitude).toList();
    final gyroResultants = gyro.map((r) => r.resultant).toList();

    final accelVariance = _calculateVariance(accelMagnitudes);
    final gyroVariance = _calculateVariance(gyroResultants);

    final stepCount = _countSteps(accelMagnitudes);
    final stepIrregularity = _calculateStepIrregularity(accelMagnitudes, stepCount);

    final normalizedAccelVar = _normalizeVariance(accelVariance, 0.0, 4.0);
    final normalizedGyroVar = _normalizeVariance(gyroVariance, 0.0, 2.0);
    final normalizedStepIrreg = _normalizeValue(stepIrregularity, 0.0, 1.0);

    final riskScore = (_clamp(
              normalizedAccelVar * 100 * accelVarianceWeight +
                  normalizedGyroVar * 100 * gyroVarianceWeight +
                  normalizedStepIrreg * 100 * stepIrregularityWeight,
            ) *
            100)
        .round();

    final confidence = _calculateConfidence(accel.length, gyro.length);
    final dominantFactor = _getDominantFactor(
      normalizedAccelVar,
      normalizedGyroVar,
      normalizedStepIrreg,
    );

    return {
      'risk_score': riskScore,
      'status': _getStatusFromScore(riskScore),
      'confidence': confidence,
      'dominant_factor': dominantFactor,
      'step_count': stepCount.toDouble(),
      'accel_variance': accelVariance,
      'gyro_variance': gyroVariance,
      'step_irregularity': stepIrregularity,
    };
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs =
        values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  int _countSteps(List<double> magnitudes) {
    if (magnitudes.length < 10) return 0;
    final mean =
        magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    var crossings = 0;
    var wasAbove = magnitudes[0] > mean;
    for (var i = 1; i < magnitudes.length; i++) {
      final isAbove = magnitudes[i] > mean;
      if (isAbove != wasAbove) {
        crossings++;
        wasAbove = isAbove;
      }
    }
    return (crossings / 2).floor();
  }

  double _calculateStepIrregularity(
    List<double> magnitudes,
    int stepCount,
  ) {
    if (stepCount < 3) return 1.0;
    final mean =
        magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final threshold = mean * 0.8;
    var gaitCycles = <double>[];
    var lastCrossing = -1;

    for (var i = 1; i < magnitudes.length; i++) {
      if ((magnitudes[i - 1] <= threshold && magnitudes[i] > threshold) ||
          (magnitudes[i - 1] >= threshold &&
              magnitudes[i] < threshold)) {
        if (lastCrossing >= 0) {
          gaitCycles.add((i - lastCrossing).toDouble());
        }
        lastCrossing = i;
      }
    }

    if (gaitCycles.length < 2) return 0.5;
    final cycleVariance = _calculateVariance(gaitCycles);
    final normalizedVariance = min(cycleVariance / 100.0, 1.0);
    return normalizedVariance;
  }

  double _normalizeVariance(double variance, double min, double max) {
    return _normalizeValue(sqrt(variance), min, max);
  }

  double _normalizeValue(double value, double min, double max) {
    if (value <= min) return 0.0;
    if (value >= max) return 1.0;
    return (value - min) / (max - min);
  }

  double _calculateConfidence(int accelCount, int gyroCount) {
    final total = accelCount + gyroCount;
    if (total < minReadings * 2) return 0.5;
    if (total < minReadings * 4) return 0.7;
    return 0.9;
  }

  String _getDominantFactor(
    double accelVar,
    double gyroVar,
    double stepIrreg,
  ) {
    final factors = {
      'accelerometer_variance': accelVar * accelVarianceWeight,
      'gyroscope_variance': gyroVar * gyroVarianceWeight,
      'step_irregularity': stepIrreg * stepIrregularityWeight,
    };
    return factors.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  int _clamp(double value) {
    return value.round().clamp(0, 100);
  }

  String _getStatusFromScore(int score) {
    if (score < 25) return 'Healthy';
    if (score < 45) return 'Low Risk';
    if (score < 65) return 'Moderate Risk';
    if (score < 85) return 'High Risk';
    return 'Critical';
  }
}
