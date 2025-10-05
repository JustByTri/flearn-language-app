import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SpeakingPracticeScreen extends StatefulWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  State<SpeakingPracticeScreen> createState() => _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends State<SpeakingPracticeScreen> {
  final _recorder = AudioRecorder();
  bool isRecording = false;
  String? recordedFilePath;
  String? lastRecordedPath;
  String selectedLang = 'EN';
  String? apiResult;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied ||
        storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập micro hoặc bộ nhớ')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await Permission.microphone.isGranted) {
        await _requestPermissions();
        if (!await Permission.microphone.isGranted) return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);

      if (mounted) {
        setState(() {
          isRecording = true;
          recordedFilePath = filePath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang ghi âm...')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi bắt đầu ghi âm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi bắt đầu ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (mounted) {
        setState(() {
          isRecording = false;
          lastRecordedPath = path;
        });
      }
      if (path != null && File(path).existsSync()) {
        final file = File(path);
        debugPrint('File size: ${file.lengthSync()} bytes');
        if (file.lengthSync() == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File ghi âm rỗng!')),
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã lưu file ghi âm tại: $path')),
          );

          await _sendFileToApi();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi: File không được lưu')),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi dừng ghi âm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dừng ghi âm: $e')),
        );
      }
    }
  }

  Future<void> _sendFileToApi() async {
    if (lastRecordedPath == null) return;
    final file = File(lastRecordedPath!);
    final uri = Uri.parse('https://xbensieve-pronunciation-assessment-api.hf.space/api/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..fields['lang'] = selectedLang.toLowerCase()
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('audio', 'wav'),
      ));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (mounted) {
      setState(() {
        apiResult = respStr; // Lưu kết quả để hiển thị
      });
    }

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kết quả: $respStr')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi file: $respStr')),
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Luyện Nói')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('EN'),
                  selected: selectedLang == 'EN',
                  onSelected: (_) => setState(() => selectedLang = 'EN'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ja'),
                  selected: selectedLang == 'ja',
                  onSelected: (_) => setState(() => selectedLang = 'ja'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ZH'),
                  selected: selectedLang == 'ZH',
                  onSelected: (_) => setState(() => selectedLang = 'ZH'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(isRecording ? Icons.stop : Icons.mic),
              label: Text(isRecording ? 'Dừng Ghi Âm' : 'Bắt Đầu Ghi Âm'),
              onPressed: isRecording ? _stopRecording : _startRecording,
            ),
            const SizedBox(height: 24),
            if (lastRecordedPath != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Phát lại ghi âm'),
                onPressed: () async {
                  final player = AudioPlayer();
                  await player.setFilePath(lastRecordedPath!);
                  await player.play();
                },
              ),
            if (apiResult != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Kết quả nhận diện: $apiResult',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}