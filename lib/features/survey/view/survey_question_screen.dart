import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';

import '../viewmodel/survey_viewmodel.dart';

import 'assessment_result_screen.dart';

class SurveyQuestionScreen extends StatefulWidget {
  final String assessmentId;
  const SurveyQuestionScreen({super.key, required this.assessmentId});

  @override
  State<SurveyQuestionScreen> createState() => _SurveyQuestionScreenState();
}

class _SurveyQuestionScreenState extends State<SurveyQuestionScreen> {
  final surveyViewModel = Get.find<SurveyViewModel>();
  final _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? recordedFilePath;
  String? transcript;

  @override
  void initState() {
    super.initState();
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
      }
    } catch (e) {
      debugPrint('Lỗi dừng ghi âm: $e');
    }
  }

  void _showWordGuidesBottomSheet(List<dynamic> wordGuides) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.book, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Từ vựng hỗ trợ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: wordGuides.length,
                itemBuilder: (context, index) {
                  final word = wordGuides[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                word.word ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.volume_up,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                word.pronunciation ?? '',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.translate,
                              color: Colors.grey[600],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                word.vietnameseMeaning ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.visible,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                color: Colors.amber[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  word.example ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final question = surveyViewModel.currentQuestion.value;
      final assessment = surveyViewModel.assessment.value;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.9),
                AppColors.primary.withOpacity(0.6),
                AppColors.primary.withOpacity(0.3),
                Colors.white,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: surveyViewModel.isLoading.value
                ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
                : question == null || assessment == null
                ? _buildErrorState()
                : _buildContent(context, question, assessment),
          ),
        ),
      );
    });
  }

  Widget _buildErrorState() {
    final errorMessage = surveyViewModel.errorMessage.value ?? '';
    if (errorMessage.contains('Đã hoàn thành tất cả câu hỏi')) {
      Future.microtask(() async {
        final assessment = surveyViewModel.assessment.value;
        if (assessment != null) {
          final result = await surveyViewModel.completeAssessment(
            assessment.assessmentId,
          );
          if (result != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AssessmentResultScreen(result: result),
              ),
            );
          }
        }
      });
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            errorMessage.isNotEmpty ? errorMessage : 'Không thể tải câu hỏi',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => surveyViewModel.fetchCurrentAssessmentQuestion(
              widget.assessmentId,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Thử lại', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic question, dynamic assessment) {
    return FadeSlideAnimation(
      child: Column(
        children: [
          _buildProgressHeader(question, assessment),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(question),
                  if (transcript != null) ...[
                    const SizedBox(height: 24),
                    _buildTranscriptSection(),
                  ],
                ],
              ),
            ),
          ),
          _buildRecordingButton(),
          const SizedBox(height: 16),
          _buildActionButtons(assessment, question),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(dynamic question, dynamic assessment) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu hỏi ${question.questionNumber}/${assessment.totalQuestions}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${((question.questionNumber / assessment.totalQuestions) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: question.questionNumber / assessment.totalQuestions,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.question ?? 'Không có câu hỏi',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (question.wordGuides.isNotEmpty)
                IconButton(
                  onPressed: () => _showWordGuidesBottomSheet(
                    question.wordGuides,
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  tooltip: 'Từ vựng hỗ trợ',
                ),
            ],
          ),
          if (question.promptText != null && question.promptText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              question.promptText,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.translate, color: Colors.blue[600], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.vietnameseTranslation ?? 'Không có bản dịch',
                    style: TextStyle(
                      fontSize: 15,
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
    );
  }

  Widget _buildRecordingButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : AppColors.primary)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'Đang ghi âm...' : 'Nhấn để ghi âm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (recordedFilePath != null && !_isRecording) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Đã ghi âm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.play_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  tooltip: 'Nghe lại',
                  onPressed: () async {
                    if (recordedFilePath != null) {
                      await _audioPlayer.play(
                        DeviceFileSource(recordedFilePath!),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kết quả nhận diện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            transcript!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic assessment, dynamic question) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (recordedFilePath == null ||
                        !File(recordedFilePath!).existsSync()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn chưa ghi âm câu trả lời!'),
                        ),
                      );
                      return;
                    }

                    int duration = 0;
                    try {
                      final audioFile = File(recordedFilePath!);
                      duration = audioFile.existsSync()
                          ? audioFile.lengthSync() ~/ 16000
                          : 0;
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
                        const SnackBar(
                          content: Text('Gửi câu trả lời thất bại!'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Gửi câu trả lời',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateNext(dynamic assessment) async {
    final question = surveyViewModel.currentQuestion.value;
    final isLastQuestion = question != null && question.questionNumber >= 4;

    if (isLastQuestion) {
      final result = await surveyViewModel.completeAssessment(
        assessment.assessmentId,
      );
      if (result != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AssessmentResultScreen(result: result),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy kết quả đánh giá. Vui lòng thử lại!'),
          ),
        );
      }
    } else {
      setState(() {
        recordedFilePath = null;
        transcript = null;
        _isRecording = false;
      });

      await surveyViewModel.fetchCurrentAssessmentQuestion(
        assessment.assessmentId,
      );
    }
  }
}