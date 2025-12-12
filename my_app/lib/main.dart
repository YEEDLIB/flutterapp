import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const VoiceRecorderApp());
}

class VoiceRecorderApp extends StatelessWidget {
  const VoiceRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const RecorderPage(),
    );
  }
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final Record _record = Record();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  String? _filePath;
  Duration _recordedDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.positionStream.listen((pos) {
      setState(() => _playbackPosition = pos);
    });
    _player.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<String> _makeFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/recordings');
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${recDir.path}/rec_$ts.m4a';
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final req = await Permission.microphone.request();
    return req.isGranted;
  }

  Future<void> _startRecording() async {
    if (!await _ensureMicPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mic permission waa loo baahan yahay')),
      );
      return;
    }

    final canRecord = await _record.hasPermission();
    if (!canRecord) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ogolaanshaha duubista ma jiro')),
      );
      return;
    }

    final path = await _makeFilePath();

    await _record.start(
      path: path,
      encoder: AudioEncoder.aacLc, // .m4a
      bitRate: 128000,
      samplingRate: 44100,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _filePath = path;
      _recordedDuration = Duration.zero;
    });

    // Update duration periodically
    _tickDuration();
  }

  Future<void> _tickDuration() async {
    while (_isRecording) {
      final state = await _record.getRecordingState();
      if (state == RecordingState.record) {
        final d = await _record.getAmplitude();
        // Not exact duration; we fetch from recording state when stopping.
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    await _record.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    await _record.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final path = await _record.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _filePath = path ?? _filePath;
    });

    // Load into player
    if (_filePath != null && await File(_filePath!).exists()) {
      await _player.setFilePath(_filePath!);
    }
  }

  Future<void> _play() async {
    if (_filePath == null) return;
    if (_player.playerState.playing) return;
    await _player.setFilePath(_filePath!);
    await _player.play();
  }

  Future<void> _pausePlay() async {
    await _player.pause();
  }

  Future<void> _stopPlay() async {
    await _player.stop();
    setState(() => _playbackPosition = Duration.zero);
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _filePath != null && File(_filePath!).existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Recorder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _isRecording
                      ? (_isPaused ? Icons.pause_circle : Icons.fiber_manual_record)
                      : Icons.mic_none,
                  color: _isRecording ? Colors.red : null,
                ),
                title: Text(_isRecording
                    ? (_isPaused ? 'Recording paused' : 'Recording...')
                    : 'Ready to record'),
                subtitle: Text(hasFile ? 'Saved: ${_filePath!.split('/').last}' : 'No file yet'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRecording && !_isPaused ? _pauseRecording : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRecording && _isPaused ? _resumeRecording : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Playback'),
              subtitle: Text('Position: ${_fmt(_playbackPosition)}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: hasFile && !_isPlaying ? _play : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isPlaying ? _pausePlay : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: hasFile ? _stopPlay : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
            const Spacer(),
            if (hasFile)
              Text(
                'File path:\n$_filePath',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
