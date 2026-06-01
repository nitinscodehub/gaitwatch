import 'dart:math';

class AccelReading {
  final double x;
  final double y;
  final double z;
  final int timestampMs;

  const AccelReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestampMs,
  });

  double get magnitude => sqrt(x * x + y * y + z * z);
}

class GyroReading {
  final double x;
  final double y;
  final double z;
  final int timestampMs;

  const GyroReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestampMs,
  });
}

class SensorData {
  final List<AccelReading> accelReadings;
  final List<GyroReading> gyroReadings;
  final DateTime startTime;
  final DateTime endTime;

  const SensorData({
    required this.accelReadings,
    required this.gyroReadings,
    required this.startTime,
    required this.endTime,
  });

  int get sampleCount => accelReadings.length;

  Map<String, dynamic> toJson() {
    return {
      'session_id':
          '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}_'
          '${startTime.hour.toString().padLeft(2, '0')}${startTime.minute.toString().padLeft(2, '0')}${startTime.second.toString().padLeft(2, '0')}',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': endTime.difference(startTime).inSeconds,
      'sample_count': accelReadings.length,
      'accelerometer': {
        'x': accelReadings.map((r) => r.x).toList(),
        'y': accelReadings.map((r) => r.y).toList(),
        'z': accelReadings.map((r) => r.z).toList(),
        'timestamps_ms': accelReadings.map((r) => r.timestampMs).toList(),
      },
      'gyroscope': {
        'x': gyroReadings.map((r) => r.x).toList(),
        'y': gyroReadings.map((r) => r.y).toList(),
        'z': gyroReadings.map((r) => r.z).toList(),
        'timestamps_ms': gyroReadings.map((r) => r.timestampMs).toList(),
      },
    };
  }
}
