import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RecorderPage(),
    );
  }
}

class RecorderPage extends StatefulWidget {
  @override
  _RecorderPageState createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _currentFile;
  List<FileSystemEntity> _recordings = [];

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _loadRecordings();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${dir.path}/recording_$timestamp.aac';
  }

  void _startRecording() async {
    _currentFile = await _getFilePath();
    await _recorder.startRecorder(
      toFile: _currentFile,
      codec: Codec.aacADTS,
    );
    setState(() => _isRecording = true);
  }

  void _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _currentFile = null;
      _loadRecordings();
    });
  }

  void _loadRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) => f.path.endsWith('.aac')).toList();
    setState(() {
      _recordings = files;
    });
  }

  void _deleteRecording(FileSystemEntity file) async {
    await file.delete();
    _loadRecordings();
  }

  void _playRecording(String path) async {
    await _player.startPlayer(
      fromURI: path,
      codec: Codec.aacADTS,
      whenFinished: () => setState(() {}),
    );
  }

  void _stopPlayback() async {
    await _player.stopPlayer();
    setState(() {});
  }

  // Basic scheduled recording
  void _scheduleRecording(DateTime time, int durationSeconds) {
    AndroidAlarmManager.oneShotAt(
      time,
      0,
      () async {
        final filePath = await _getFilePath();
        await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);
        await Future.delayed(Duration(seconds: durationSeconds));
        await _recorder.stopRecorder();
      },
      exact: true,
      wakeup: true,
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voice Recorder")),
      body: Column(
        children: [
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
          SizedBox(height: 20),
          Text('Scheduled Recording Example: Start in 10s, duration 5s'),
          ElevatedButton(
            onPressed: () {
              final scheduledTime = DateTime.now().add(Duration(seconds: 10));
              _scheduleRecording(scheduledTime, 5);
            },
            child: Text('Schedule Recording'),
          ),
          SizedBox(height: 20),
          Divider(),
          Text('Recordings:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _recordings.length,
              itemBuilder: (context, index) {
                final file = _recordings[index];
                return ListTile(
                  title: Text(file.path.split('/').last),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () => _playRecording(file.path),
                      ),
                      IconButton(
                        icon: Icon(Icons.stop),
                        onPressed: _stopPlayback,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteRecording(file),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
