import 'dart:async'; // 1. Soo import-garee Timer
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VoiceRecorderPage(),
    );
  }
}

class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key});

  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Duration _position = Duration.zero;

  // 2. Variables-ka Timer-ka
  Timer? _timer;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        // 3. Bilow recording-ka
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _startTime = DateTime.now(); // Bilow waqtiga
          _recordingDuration = Duration.zero; // Jooji waqtiga hore
        });

        // 4. Bilow Timer-ka si aan si joogto ah u update-gareyno waqtiga
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_startTime != null) {
            final currentDuration = DateTime.now().difference(_startTime!);
            setState(() {
              _recordingDuration = currentDuration;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      // 5. Jooji Timer-ka
      _timer?.cancel();
      _timer = null;

      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
        // Ha joojin duration-ka, si aad u muujiso muddada saxda ah ee la qoray
      });
    } catch (e) {
      debugPrint("Error stopping recording: $e");
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_recordingPath != null) {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
      }
    } catch (e) {
      debugPrint("Error playing recording: $e");
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _position = Duration.zero;
      });
    } catch (e) {
      debugPrint("Error stopping playback: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    // 6. Aad muhiim ah: Jooji Timer-ka iyo resources-ka marka la saaray
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRecording ? 'Recording...' : 'Not Recording',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isRecording ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _formatDuration(_isRecording ? _recordingDuration : _position),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && _recordingPath != null)
                  IconButton(
                    onPressed: _isPlaying ? _stopPlaying : _playRecording,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    iconSize: 64,
                    color: Colors.green,
                  ),
                const SizedBox(width: 40),
                IconButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  iconSize: 64,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            if (_recordingPath != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: ListTile(
                    title: Text('Recording: ${_recordingPath?.split('/').last}'),
                    subtitle: Text('Duration: ${_formatDuration(_recordingDuration)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: _isPlaying ? _stopPlaying : _playRecording,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
