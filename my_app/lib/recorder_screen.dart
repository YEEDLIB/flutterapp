// recorder_screen.dart
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

class RecorderScreen extends StatefulWidget {
  @override
  _RecorderScreenState createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  List<String> _recordings = [];

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = await Directory('${directory.path}/recordings').create();
    
    List<FileSystemEntity> files = recordingsDir.listSync();
    setState(() {
      _recordings = files
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final recordingsDir = await Directory('${directory.path}/recordings').create();
        
        String fileName = 'recording_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.m4a';
        String path = p.join(recordingsDir.path, fileName);
        
        await _audioRecorder.start(
          RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        
        setState(() {
          _isRecording = true;
          _currentRecordingPath = path;
          _recordingDuration = Duration.zero;
        });
        
        // Update duration timer
        Timer.periodic(Duration(seconds: 1), (timer) {
          if (_isRecording) {
            setState(() {
              _recordingDuration += Duration(seconds: 1);
            });
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      print('Qalad duubista: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      await _loadRecordings();
    } catch (e) {
      print('Qalad joojinta: $e');
    }
  }

  Future<void> _playRecording(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
      
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      print('Qalad dhageysiga: $e');
    }
  }

  Future<void> _pausePlaying() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _deleteRecording(String path) async {
    try {
      File file = File(path);
      await file.delete();
      await _loadRecordings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duubista waa la tirtiray')),
      );
    } catch (e) {
      print('Qalad tirtirka: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Recording Section
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 80,
                color: _isRecording ? Colors.red : Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                _isRecording 
                  ? 'Duubista socoto...' 
                  : 'Riix badhanka si aad u bilowdo duubista',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRecording)
                    ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: Icon(Icons.mic),
                      label: Text('Bilow Duubista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: Icon(Icons.stop),
                      label: Text('Joogso Duubista'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Playback Section (if recording exists)
        if (_currentRecordingPath != null && !_isRecording)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => _isPlaying 
                      ? _pausePlaying() 
                      : _playRecording(_currentRecordingPath!),
                  iconSize: 40,
                  color: Colors.blue,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteRecording(_currentRecordingPath!),
                  iconSize: 40,
                  color: Colors.red,
                ),
              ],
            ),
          ),

        // Recordings List
        Expanded(
          child: _recordings.isEmpty
              ? Center(
                  child: Text(
                    'Weli ma jiro wax duubis ah',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    String path = _recordings[index];
                    String fileName = p.basename(path);
                    DateTime fileDate = File(path).lastModifiedSync();
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(Icons.audiotrack, color: Colors.blue),
                        title: Text(fileName.replaceAll('.m4a', '')),
                        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(fileDate)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(_isPlaying && _currentRecordingPath == path 
                                  ? Icons.pause : Icons.play_arrow),
                              onPressed: () => _isPlaying && _currentRecordingPath == path
                                  ? _pausePlaying()
                                  : _playRecording(path),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecording(path),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
