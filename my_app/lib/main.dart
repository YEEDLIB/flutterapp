// Qalabka Duubista Codka ee Flutter (Flutter Voice Recorder App)
// Fiiro gaar ah: Qeybaha UI-ga waxaa loo turjumay Af-Soomaali.

// === TALAABOOYINKA DEJINTA EE MUHIIMKA AH ===
// 1. Ku dar dependencies-yada (Ku dar pubspec.yaml):
/*
dependencies:
  flutter:
    sdk: flutter
  record: ^5.0.1
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
*/

// 2. Ogolaanshaha Android (Ku dar android/app/src/main/AndroidManifest.xml):
/*
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
*/

// 3. Ogolaanshaha iOS (Ku dar ios/Runner/Info.plist):
/*
<key>NSMicrophoneUsageDescription</key>
<string>Waa inaan duubnaa codkaaga si aan u kaydino (We need your microphone to record audio).</string>
*/
// ===========================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
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
      title: 'Qalabka Duubista Codka',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AudioRecorderHome(),
    );
  }
}

class AudioRecorderHome extends StatefulWidget {
  const AudioRecorderHome({super.key});

  @override
  State<AudioRecorderHome> createState() => _AudioRecorderHomeState();
}

class _AudioRecorderHomeState extends State<AudioRecorderHome> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Xaqiijinta ogolaanshaha makarafoonka
  Future<bool> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isDenied) {
      // Muuji fariin haddii ogolaanshaha la diido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan ogolow makarafoonka si aad u duubto codka.')),
      );
      return false;
    }
    return status.isGranted;
  }

  // Bilowga duubista codka
  Future<void> _startRecording() async {
    if (await _checkPermissions()) {
      try {
        if (await _audioRecorder.hasPermission()) {
          // Hel goobta ku meel gaadhka ah ee lagu kaydinayo feylka
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/codka_${DateTime.now().millisecondsSinceEpoch}.m4a';

          // Bilow duubista
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 44100),
            path: path,
          );

          setState(() {
            _isRecording = true;
            _recordPath = null; // Nadiifi waddadii hore
            _recordDuration = Duration.zero;
          });

          _startTimer();
        }
      } catch (e) {
        debugPrint('Cilad markii la bilaabayay duubista: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cilad: Ma bilaabi karin duubista. Hubi dejinta ogolaanshaha. $e')),
        );
      }
    }
  }

  // Joojinta duubista codka
  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    
    setState(() {
      _isRecording = false;
      _recordPath = path;
    });

    if (path != null) {
      debugPrint('Duubista waa la joojiyay. Waa lagu kaydiyay: $path');
    }
  }

  // Bilowga saacadda wakhtiga duubista
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_isRecording) {
        setState(() {
          _recordDuration = _recordDuration + const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  // Foomka wakhtiga (HH:MM:SS)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qalabka Duubista Codka'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Calaamadda iyo Wakhtiga
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRecording)
                    const Icon(Icons.mic, color: Colors.red, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    _isRecording ? 'Duubista ayaa socota...' : 'Diyaar u ah Duubista',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Muujinta Wakhtiga
              Text(
                'Wakhtiga: ${_formatDuration(_recordDuration)}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 48),

              // Badhanka Duubista
              FloatingActionButton.extended(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                label: Text(
                  _isRecording ? 'Jooji Duubista' : 'Bilow Duubista',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                backgroundColor: _isRecording ? Colors.red.shade700 : Colors.green.shade700,
                extendedIconLabelSpacing: 12,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),

              const SizedBox(height: 40),

              // Muujinta Goobta Kaydinta
              if (_recordPath != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waa lagu kaydiyay:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recordPath!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          '[Fiiro gaar ah: Duubista waa la kaydiyay, laakiin kuma jiraan qalab lagu dhegeysto. Ku dar package sida `audioplayers` haddii aad rabto.]',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
