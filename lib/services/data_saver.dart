import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/sensor_data.dart';

class DataSaver {
  static Future<Directory> get _dataDir async {
    final dir = await getApplicationDocumentsDirectory();
    final gaitDir = Directory('${dir.path}/GaitWatchData');
    if (!await gaitDir.exists()) {
      await gaitDir.create(recursive: true);
    }
    return gaitDir;
  }

  static Future<String> saveSensorData(SensorData data) async {
    final dir = await _dataDir;
    final json = data.toJson();
    final sessionId = json['session_id'] as String;
    final filePath = '${dir.path}/${sessionId}.json';

    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );

    return filePath;
  }

  static Future<List<FileSystemEntity>> listSavedFiles() async {
    final dir = await _dataDir;
    final files = await dir.list().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  static Future<String> getDataDirPath() async {
    final dir = await _dataDir;
    return dir.path;
  }
}
