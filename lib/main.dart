import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/sensor_service.dart';
import 'services/data_saver.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const GaitWatchApp());
}

class GaitWatchApp extends StatelessWidget {
  const GaitWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GaitWatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F62FE),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const RecordScreen(),
    );
  }
}

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

enum RecState { idle, recording, saving, done }

class _RecordScreenState extends State<RecordScreen> {
  final SensorService _sensor = SensorService();
  RecState _state = RecState.idle;
  int _countdown = 30;
  String? _savedPath;
  String? _dataDirPath;
  int _sampleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDataDir();
  }

  Future<void> _loadDataDir() async {
    final path = await DataSaver.getDataDirPath();
    setState(() => _dataDirPath = path);
  }

  Future<void> startRecording() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission required')),
        );
      }
      return;
    }

    setState(() {
      _state = RecState.recording;
      _countdown = 30;
      _savedPath = null;
    });

    _sensor.startRecording();

    for (int i = 30; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _state != RecState.recording) return;
      setState(() => _countdown = i - 1);
    }

    final data = _sensor.stopRecording();

    setState(() {
      _state = RecState.saving;
      _sampleCount = data.sampleCount;
    });

    try {
      final path = await DataSaver.saveSensorData(data);
      setState(() {
        _savedPath = path;
        _state = RecState.done;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
      setState(() => _state = RecState.idle);
    }
  }

  void reset() {
    setState(() => _state = RecState.idle);
  }

  @override
  void dispose() {
    _sensor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GaitWatch'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: _state == RecState.idle
                ? _buildIdle()
                : _state == RecState.recording
                    ? _buildRecording()
                    : _state == RecState.saving
                        ? _buildSaving()
                        : _buildDone(),
          ),
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.directions_walk_rounded, size: 100, color: Color(0xFF0F62FE)),
        const SizedBox(height: 24),
        Text('Walk Test', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(
          'Place phone in your pocket and walk naturally for 30 seconds',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: startRecording,
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text('Start Recording', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          ),
        ),
        if (_dataDirPath != null) ...[
          const SizedBox(height: 40),
          Text('Data folder:', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(_dataDirPath!, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ],
      ],
    );
  }

  Widget _buildRecording() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200, height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: (30 - _countdown) / 30,
                strokeWidth: 12,
                color: const Color(0xFF0F62FE),
                backgroundColor: const Color(0xFF0F62FE).withValues(alpha: 0.2),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_countdown', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    const Text('seconds', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Icon(Icons.directions_walk_rounded, size: 40, color: Color(0xFF0F62FE)),
        const SizedBox(height: 8),
        const Text('Walking...'),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            _sensor.stopRecording();
            setState(() => _state = RecState.idle);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildSaving() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        const Text('Saving data...'),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        Text('Recording Complete', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('$_sampleCount samples collected'),
        if (_savedPath != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Saved:\n$_savedPath',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: reset,
          child: const Text('Record Again'),
        ),
      ],
    );
  }
}
