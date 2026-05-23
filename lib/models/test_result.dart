import 'dart:convert';
import 'dart:math';

enum RiskStatus {
  healthy,
  lowRisk,
  moderateRisk,
  highRisk,
  critical;

  String get displayName {
    switch (this) {
      case RiskStatus.healthy:
        return 'Healthy';
      case RiskStatus.lowRisk:
        return 'Low Risk';
      case RiskStatus.moderateRisk:
        return 'Moderate Risk';
      case RiskStatus.highRisk:
        return 'High Risk';
      case RiskStatus.critical:
        return 'Critical';
    }
  }

  static RiskStatus fromScore(int score) {
    if (score < 25) return RiskStatus.healthy;
    if (score < 45) return RiskStatus.lowRisk;
    if (score < 65) return RiskStatus.moderateRisk;
    if (score < 85) return RiskStatus.highRisk;
    return RiskStatus.critical;
  }
}

class AccelReading {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const AccelReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  double get magnitude => sqrt(x * x + y * y + z * z);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory AccelReading.fromJson(Map<String, dynamic> json) {
    return AccelReading(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

class GyroReading {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  const GyroReading({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  double get resultant => sqrt(x * x + y * y + z * z);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory GyroReading.fromJson(Map<String, dynamic> json) {
    return GyroReading(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

class SensorData {
  final List<AccelReading> accelReadings;
  final List<GyroReading> gyroReadings;

  const SensorData({
    required this.accelReadings,
    required this.gyroReadings,
  });

  factory SensorData.empty() {
    return const SensorData(accelReadings: [], gyroReadings: []);
  }

  List<double> get accelX => accelReadings.map((r) => r.x).toList();
  List<double> get accelY => accelReadings.map((r) => r.y).toList();
  List<double> get accelZ => accelReadings.map((r) => r.z).toList();
  List<double> get gyroX => gyroReadings.map((r) => r.x).toList();
  List<double> get gyroY => gyroReadings.map((r) => r.y).toList();
  List<double> get gyroZ => gyroReadings.map((r) => r.z).toList();

  Map<String, dynamic> toJson() {
    return {
      'accel_readings': accelReadings.map((r) => r.toJson()).toList(),
      'gyro_readings': gyroReadings.map((r) => r.toJson()).toList(),
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      accelReadings: (json['accel_readings'] as List?)
              ?.map((e) => AccelReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gyroReadings: (json['gyro_readings'] as List?)
              ?.map((e) => GyroReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TestResult {
  final String id;
  final DateTime timestamp;
  final int riskScore;
  final RiskStatus status;
  final SensorData sensorData;
  final double? stepCount;
  final double? averageStrideLength;
  final double? gaitVelocity;

  const TestResult({
    required this.id,
    required this.timestamp,
    required this.riskScore,
    required this.status,
    required this.sensorData,
    this.stepCount,
    this.averageStrideLength,
    this.gaitVelocity,
  });

  factory TestResult.fromPrediction(
    Map<String, dynamic> prediction,
    SensorData data,
  ) {
    final score = prediction['risk_score'] as int;
    return TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      riskScore: score,
      status: RiskStatus.fromScore(score),
      sensorData: data,
      stepCount: prediction['step_count'] as double?,
      averageStrideLength: prediction['avg_stride'] as double?,
      gaitVelocity: prediction['gait_velocity'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'risk_score': riskScore,
      'status': status.index,
      'sensor_data': sensorData.toJson(),
      'step_count': stepCount,
      'avg_stride': averageStrideLength,
      'gait_velocity': gaitVelocity,
    };
  }

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      riskScore: json['risk_score'] as int,
      status: RiskStatus.values[json['status'] as int],
      sensorData: SensorData.fromJson(
        json['sensor_data'] as Map<String, dynamic>,
      ),
      stepCount: json['step_count'] as double?,
      averageStrideLength: json['avg_stride'] as double?,
      gaitVelocity: json['gait_velocity'] as double?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TestResult.fromJsonString(String jsonString) {
    return TestResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

class UserProfile {
  final String name;
  final int age;
  final double height;
  final double weight;
  final String? medicalNotes;

  const UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    this.medicalNotes,
  });

  factory UserProfile.empty() {
    return const UserProfile(name: '', age: 0, height: 0, weight: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'medical_notes': medicalNotes,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      medicalNotes: json['medical_notes'] as String?,
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
    String? medicalNotes,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      medicalNotes: medicalNotes ?? this.medicalNotes,
    );
  }
}
