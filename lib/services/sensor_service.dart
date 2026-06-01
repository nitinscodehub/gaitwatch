import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  final List<AccelReading> _accelReadings = [];
  final List<GyroReading> _gyroReadings = [];

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  DateTime? _startTime;

  static const Duration SAMPLING_PERIOD = Duration(milliseconds: 10);

  void startRecording() {
    if (_isRecording) return;
    _accelReadings.clear();
    _gyroReadings.clear();
    _isRecording = true;
    _startTime = DateTime.now();

    _accelSub = accelerometerEventStream(
      samplingPeriod: SAMPLING_PERIOD,
    ).listen(
      (AccelerometerEvent event) {
        if (!_isRecording) return;
        _accelReadings.add(AccelReading(
          x: event.x,
          y: event.y,
          z: event.z,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ));
      },
      onError: (error) => print('[ERROR] Accelerometer: $error'),
      cancelOnError: false,
    );

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SAMPLING_PERIOD,
    ).listen(
      (GyroscopeEvent event) {
        if (!_isRecording) return;
        _gyroReadings.add(GyroReading(
          x: event.x,
          y: event.y,
          z: event.z,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ));
      },
      onError: (error) => print('[ERROR] Gyroscope: $error'),
      cancelOnError: false,
    );
  }

  SensorData stopRecording() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;

    final now = DateTime.now();
    final data = SensorData(
      accelReadings: List.from(_accelReadings),
      gyroReadings: List.from(_gyroReadings),
      startTime: _startTime ?? now,
      endTime: now,
    );

    _accelReadings.clear();
    _gyroReadings.clear();
    return data;
  }

  void dispose() {
    _isRecording = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelReadings.clear();
    _gyroReadings.clear();
  }
}
