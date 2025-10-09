import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../viewmodel/survey_viewmodel.dart';
import '../../auth/view/home_screen.dart';
import 'assessment_result_screen.dart';

class SurveyQuestionScreen extends StatefulWidget {
  final String assessmentId;
  const SurveyQuestionScreen({super.key, required this.assessmentId});

  @override
  State<SurveyQuestionScreen> createState() => _SurveyQuestionScreenState();
}

class _SurveyQuestionScreenState extends State<SurveyQuestionScreen>
    with TickerProviderStateMixin {
  final surveyViewModel = Get.find<SurveyViewModel>();
  final _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? recordedFilePath;
  String? transcript;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    _requestPermissions();
    surveyViewModel.fetchCurrentAssessmentQuestion(widget.assessmentId);
  }

  Future<void> _requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập micro')),
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
      final filePath = '${dir.path}/survey_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);

      if (mounted) {
        setState(() {
          _isRecording = true;
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
          _isRecording = false;
          recordedFilePath = path;
        });
      }
      if (path != null && File(path).existsSync()) {
        final file = File(path);
        if (file.lengthSync() == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File ghi âm rỗng!')),
            );
          }
          return;
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

  @override
  void dispose() {
    _animationController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final question = surveyViewModel.currentQuestion.value;
      final assessment = surveyViewModel.assessment.value;

      // if (assessment != null && question == null) {
      //   Future.microtask(() async {
      //     debugPrint('AssessmentId: ${assessment.assessmentId}');
      //     final result = await surveyViewModel.completeAssessment(assessment.assessmentId);
      //     if (result != null && mounted) {
      //       Navigator.of(context).pushReplacement(
      //         MaterialPageRoute(
      //           builder: (_) => AssessmentResultScreen(result: result),
      //         ),
      //       );
      //     } else if (mounted) {
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Không thể lấy kết quả đánh giá. Vui lòng thử lại!')),
      //       );
      //       Navigator.of(context).pushReplacement(
      //         MaterialPageRoute(builder: (_) => const HomeScreen()),
      //       );
      //     }
      //   });

      //   return const Scaffold(
      //     body: Center(child: CircularProgressIndicator()),
      //   );
      // }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, question, assessment),
        body: surveyViewModel.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : question == null || assessment == null
            ? _buildErrorState()
            : _buildContent(context, question, assessment),
      );
    });
  }

  AppBar _buildAppBar(BuildContext context, dynamic question, dynamic assessment) {
    return AppBar(
      title: const Text('Khảo sát Luyện Nói'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        ),
      ),
      bottom: (question != null && assessment != null)
          ? PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu hỏi ${question.questionNumber}/${assessment.totalQuestions}',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    '${((question.questionNumber / assessment.totalQuestions) * 100).toInt()}%',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: question.questionNumber / assessment.totalQuestions,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
              ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildErrorState() {
    final errorMessage = surveyViewModel.errorMessage.value ?? '';
    if (errorMessage.contains('Đã hoàn thành tất cả câu hỏi')) {

      Future.microtask(() async {
        final assessment = surveyViewModel.assessment.value;
        if (assessment != null) {
          final result = await surveyViewModel.completeAssessment(assessment.assessmentId);
          if (result != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AssessmentResultScreen(result: result),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể lấy kết quả đánh giá. Vui lòng thử lại!')),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            errorMessage.isNotEmpty ? errorMessage : 'Không thể tải câu hỏi',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => surveyViewModel.fetchCurrentAssessmentQuestion(widget.assessmentId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Thử lại', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic question, dynamic assessment) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(question),
                    if (question.wordGuides.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildWordGuides(question.wordGuides),
                    ],
                    const SizedBox(height: 16),
                    _buildRecordingSection(),
                    if (transcript != null) ...[
                      const SizedBox(height: 16),
                      _buildTranscriptSection(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionButtons(assessment, question),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text('Câu hỏi ${question.questionNumber}'),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              labelStyle: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              question.question ?? 'Không có câu hỏi',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.promptText ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate, color: Colors.blue[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.vietnameseTranslation ?? 'Không có bản dịch',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordGuides(List<dynamic> wordGuides) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Từ vựng hỗ trợ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...wordGuides.map((word) => Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  label: Text(word.word),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.volume_up, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Text(
                      word.pronunciation,
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Nghĩa: ${word.vietnameseMeaning}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Ví dụ: ${word.example}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildRecordingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ghi âm câu trả lời',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : AppColors.primary).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isRecording ? 'Nhấn để dừng' : 'Nhấn để ghi âm',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            if (recordedFilePath != null && !_isRecording) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Đã ghi âm thành công!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.blue),
                      tooltip: 'Nghe lại',
                      onPressed: () async {
                        if (recordedFilePath != null) {
                          await _audioPlayer.play(DeviceFileSource(recordedFilePath!));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kết quả nhận diện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              transcript!,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic assessment, dynamic question) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final success = await surveyViewModel.submitVoiceAnswer(
                    assessmentId: assessment.assessmentId,
                    questionNumber: question.questionNumber,
                    isSkipped: true,
                    audioFilePath: null,
                    recordingDurationSeconds: 0,
                  );
                  if (success && mounted) {
                    _navigateNext(assessment);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Bỏ qua', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () async {
                  if (recordedFilePath == null || !File(recordedFilePath!).existsSync()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn chưa ghi âm câu trả lời!')),
                    );
                    return;
                  }

                  int duration = 0;
                  try {
                    final audioFile = File(recordedFilePath!);
                    duration = audioFile.existsSync() ? audioFile.lengthSync() ~/ 16000 : 0;
                  } catch (_) {}

                  final success = await surveyViewModel.submitVoiceAnswer(
                    assessmentId: assessment.assessmentId,
                    questionNumber: question.questionNumber,
                    isSkipped: false,
                    audioFilePath: recordedFilePath,
                    recordingDurationSeconds: duration,
                  );

                  if (success && mounted) {
                    _navigateNext(assessment);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gửi câu trả lời thất bại!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Gửi câu trả lời', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateNext(dynamic assessment) async {
    final question = surveyViewModel.currentQuestion.value;
    final isLastQuestion = question != null && question.questionNumber >= assessment.totalQuestions;

    if (isLastQuestion) {
      final result = await surveyViewModel.completeAssessment(assessment.assessmentId);
      if (result != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssessmentResultScreen(result: result),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy kết quả đánh giá. Vui lòng thử lại!')),
        );
      }
    } else {
      setState(() {
        recordedFilePath = null;
        transcript = null;
        _isRecording = false;
      });

      await surveyViewModel.fetchCurrentAssessmentQuestion(assessment.assessmentId);

    }
  }
}