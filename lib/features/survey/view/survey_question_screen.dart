import 'dart:io';
import 'package:flearn_app/shared/widgets/mainBottomNavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:translator/translator.dart';

import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../../../shared/widgets/animated_progress_bar.dart';

import '../../auth/view/home_screen.dart';
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
  final _translator = GoogleTranslator();

  bool _isRecording = false;
  String? recordedFilePath;
  Duration _recordingDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isCompleting = false;
  String? _translatedText;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadQuestion();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _showErrorSnackBar('Vui lòng cấp quyền ghi âm.');
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: filePath);
    setState(() {
      _isRecording = true;
      recordedFilePath = null;
    });
  }

  Future<void> _stopRecording() async {
    final stopwatch = Stopwatch()..start();
    final path = await _recorder.stop();
    stopwatch.stop();
    setState(() {
      _isRecording = false;
      recordedFilePath = path;
      _recordingDuration = stopwatch.elapsed;
    });
  }

  Future<void> _playRecording() async {
    if (recordedFilePath != null && File(recordedFilePath!).existsSync()) {
      await _audioPlayer.play(DeviceFileSource(recordedFilePath!));
    } else {
      _showErrorSnackBar('Không tìm thấy file ghi âm.');
    }
  }

  Future<void> _submitAnswer({bool isSkipped = false}) async {
    final question = surveyViewModel.currentQuestion.value;
    if (question == null) return;

    final success = await surveyViewModel.submitVoiceAnswer(
        assessmentId: widget.assessmentId,
        questionNumber: question.questionNumber,
        isSkipped: isSkipped,
        audioFilePath: recordedFilePath,
        recordingDurationSeconds: _recordingDuration.inSeconds);

    if (success) {
      setState(() {
        recordedFilePath = null;
        _recordingDuration = Duration.zero;
        _translatedText = null; // Clear translation
      });
      surveyViewModel.fetchCurrentAssessmentQuestion(widget.assessmentId);
    } else {
      _showErrorSnackBar('Gửi câu trả lời thất bại.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Từ vựng hỗ trợ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(word.word ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if(word.pronunciation != null) ...[
                            const SizedBox(height: 4),
                            Text(word.pronunciation, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 8),
                          Text(word.vietnameseMeaning ?? ''),
                          if(word.example != null) ...[
                            const SizedBox(height: 8),
                            Text('VD: ${word.example}', style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                          ]
                        ],
                      ),
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

  Future<void> _handleAssessmentCompletion() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
    });

    final assessmentId = surveyViewModel.assessment.value?.assessmentId;
    if (assessmentId == null) return;

    final result = await surveyViewModel.completeAssessment(assessmentId);
    if (result != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AssessmentResultScreen(result: result)),
      );
    } else if (mounted) {
      _showErrorSnackBar('Không thể lấy kết quả đánh giá.');
      Get.offAll(() => const NavigationMenu());
    }
  }

  Future<void> _loadQuestion() async {

    print('Gọi fetchCurrentAssessmentQuestion với assessmentId: ${widget.assessmentId}');
    await surveyViewModel.fetchCurrentAssessmentQuestion(widget.assessmentId);
    print('Current question: ${surveyViewModel.currentQuestion.value}');
    print('Error message: ${surveyViewModel.errorMessage.value}');

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.offAll(() => const NavigationMenu()),
        ),
        title: const Text('Đánh giá năng lực', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          final assessment = surveyViewModel.assessment.value;

          if (surveyViewModel.errorMessage.value == 'ASSESSMENT_COMPLETED') {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleAssessmentCompletion());
            return const Center(child: CupertinoActivityIndicator());
          }

          if (surveyViewModel.isLoadingCurrentQuestion.value || assessment == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final question = surveyViewModel.currentQuestion.value;

          if (question == null && !_isCompleting) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleAssessmentCompletion());
            return const Center(child: CupertinoActivityIndicator());
          }


          if (_isCompleting || question == null) {
            return const Center(child: CupertinoActivityIndicator());
          }

          double progress = ((question.questionNumber - 1) / assessment.totalQuestions).toDouble();
          if (progress < 0) progress = 0;

          return FadeSlideAnimation(
            child: Column(
              children: [
                AnimatedProgressBar(progress: progress),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        _buildQuestionContent(question),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
                _buildRecordingControls(),
                _buildBottomNavBar(),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- FIXED: Translation logic is now more robust ---
  Widget _buildQuestionContent(dynamic question) {
    return Column(
      children: [
        if (question.question != null)
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.5),
          ),

        if (question.promptText != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              question.promptText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),

        if (_isTranslating)
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: CupertinoActivityIndicator(),
          )
        else if (_translatedText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              _translatedText!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: AppColors.primary, height: 1.4),
            ),
          ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (question.promptText != null)
              TextButton.icon(
                onPressed: () async {
                  if (_translatedText != null) {
                    setState(() {
                      _translatedText = null;
                    });
                    return;
                  }

                  if (question.vietnameseTranslation != null && question.vietnameseTranslation.isNotEmpty) {
                    setState(() {
                      _translatedText = question.vietnameseTranslation;
                    });
                  } else {
                    setState(() {
                      _isTranslating = true;
                    });
                    try {
                      final translation = await _translator.translate(question.promptText, to: 'vi');
                      setState(() {
                        _translatedText = translation.text;
                      });
                    } catch (e) {
                      _showErrorSnackBar('Dịch thất bại');
                    } finally {
                      setState(() {
                        _isTranslating = false;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.translate, color: AppColors.primary, size: 20),
                label: Text(_translatedText == null ? 'Dịch' : 'Ẩn dịch', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),

            if (question.promptText != null && question.wordGuides?.isNotEmpty == true)
              const SizedBox(width: 16),

            if (question.wordGuides?.isNotEmpty == true)
              TextButton.icon(
                onPressed: () => _showWordGuidesBottomSheet(question.wordGuides),
                icon: const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                label: const Text('Gợi ý', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    bool canSubmit = recordedFilePath != null && !_isRecording;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          if (recordedFilePath != null && !_isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _playRecording,
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppColors.primary, size: 40),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () => setState(() { recordedFilePath = null; _recordingDuration = Duration.zero; }),
                  icon: const Icon(Icons.replay, color: AppColors.textSecondary, size: 30),
                ),
              ],
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (_isRecording ? Colors.red : AppColors.primary).withOpacity(0.3), blurRadius: 10, spreadRadius: 3)],
              ),
              child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    bool canSubmit = recordedFilePath != null && !_isRecording;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _submitAnswer(isSkipped: true),
            child: const Text('Bỏ qua', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: canSubmit ? () => _submitAnswer() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
