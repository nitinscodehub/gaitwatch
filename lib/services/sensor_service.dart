import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/test_result.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final List<AccelReading> _accelReadings = [];
  final List<GyroReading> _gyroReadings = [];

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  void startRecording() {
    if (_isRecording) return;
    _accelReadings.clear();
    _gyroReadings.clear();
    _isRecording = true;

    _accelSub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((AccelerometerEvent event) {
          if (!_isRecording) return;
          _accelReadings.add(
            AccelReading(
              x: event.x,
              y: event.y,
              z: event.z,
              timestamp: DateTime.now(),
            ),
          );
        });

    _gyroSub =
        gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 20),
        ).listen((GyroscopeEvent event) {
          if (!_isRecording) return;
          _gyroReadings.add(
            GyroReading(
              x: event.x,
              y: event.y,
              z: event.z,
              timestamp: DateTime.now(),
            ),
          );
        });
  }

  SensorData stopRecording() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;

    final data = SensorData(
      accelReadings: List<AccelReading>.from(_accelReadings),
      gyroReadings: List<GyroReading>.from(_gyroReadings),
    );

    _accelReadings.clear();
    _gyroReadings.clear();

    return data;
  }

  void dispose() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _accelReadings.clear();
    _gyroReadings.clear();
  }

  int get accelCount => _accelReadings.length;
  int get gyroCount => _gyroReadings.length;
}
