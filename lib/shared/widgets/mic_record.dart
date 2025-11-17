import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/constants/colors.dart';

class VoiceRecorder extends StatefulWidget {
  final String exerciseId;
  final ValueChanged<String?> onRecorded; // return path khi có file, null khi xoá
  final Color primaryColor;

  const VoiceRecorder({
    super.key,
    required this.exerciseId,
    required this.onRecorded,
    this.primaryColor = AppColors.primary,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  String? _path;

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.stop();
    _recorder.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      bool hasPerm = await _recorder.hasPermission() ?? false;
      if (!hasPerm) {
        final st = await Permission.microphone.request();
        if (!st.isGranted) {
          Get.snackbar('Thông báo', 'Cần quyền micro để ghi âm');
          return;
        }
      }
      final dir = await getTemporaryDirectory();
      final p = '${dir.path}/exercise_${widget.exerciseId}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: p,
      );
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _path = null;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể bắt đầu ghi âm');
    }
  }

  Future<void> _stop() async {
    try {
      final p = await _recorder.stop();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        if (p != null && p.isNotEmpty) {
          _path = p;
          widget.onRecorded(_path);
        }
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể dừng ghi âm');
    }
  }

  Future<void> _play() async {
    if (_path == null || !File(_path!).existsSync()) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      setState(() => _isPlaying = true);
      await _player.play(DeviceFileSource(_path!));
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (_) {
      setState(() => _isPlaying = false);
      Get.snackbar('Lỗi', 'Không thể phát ghi âm');
    }
  }

  Future<void> _reRecord() async {
    setState(() {
      _path = null;
      _recordingDuration = Duration.zero;
    });
    widget.onRecorded(null);
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final recorded = _path;
    final primary = widget.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: (_isRecording ? Colors.red : primary).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: IconButton(
              onPressed: () async => _isRecording ? _stop() : _start(),
              icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? _fmt(_recordingDuration)
                : (recorded != null ? '✓ Đã ghi âm' : 'Nhấn để ghi âm'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.red.shade700 : (recorded != null ? Colors.green.shade700 : Colors.grey.shade700),
            ),
          ),
          if (recorded != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: _play,
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 32, color: primary),
                    tooltip: _isPlaying ? 'Tạm dừng' : 'Nghe lại',
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    onPressed: _reRecord,
                    icon: const Icon(Icons.refresh_rounded, size: 32, color: Colors.orange),
                    tooltip: 'Ghi lại',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}