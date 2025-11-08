import 'package:flearn_app/features/course/view/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../model/course_lesson.dart';
import '../../../shared/widgets/app_scaffold.dart';

class CourseLessonScreen extends StatefulWidget {
  final Lesson lesson;
  const CourseLessonScreen({super.key, required this.lesson});

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  int _currentStep = 0; // 0: Content (HTML), 1: Video, 2: PDF

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lesson.unitTitle,
          style: const TextStyle(
            color: AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Content body
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStepContent(),
              ),
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepDot(0, 'Nội dung'),
          _buildStepLine(0),
          _buildStepDot(1, 'Video'),
          _buildStepLine(1),
          _buildStepDot(2, 'Tài liệu'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : (isActive ? AppColors.primary : Colors.grey.shade300),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildContentStep();
      case 1:
        return _buildVideoStep();
      case 2:
        return _buildDocumentStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Bài ${widget.lesson.position}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.lesson.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (widget.lesson.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.lesson.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Html(
            data: widget.lesson.content,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "h1": Style(
                fontSize: FontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              "h2": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              "p": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.6),
                color: AppColors.textSecondary,
              ),
              "li": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.6),
                color: AppColors.textSecondary,
              ),
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVideoStep() {
    if (widget.lesson.videoUrl.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        message: 'Bài học này không có video',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Video bài học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayerWidget(videoUrl: widget.lesson.videoUrl),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hãy xem kỹ video để hiểu rõ hơn về bài học này',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentStep() {
    if (widget.lesson.documentUrl.isEmpty) {
      return _buildEmptyState(
        icon: Icons.description_outlined,
        message: 'Bài học này không có tài liệu PDF',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tài liệu bài học',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                widget.lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài liệu PDF',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Mở PDF viewer hoặc download
                  Get.snackbar(
                    'Thông báo',
                    'Chức năng xem PDF đang được phát triển',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Tải tài liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tài liệu bổ sung giúp bạn ôn tập và ghi nhớ tốt hơn',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep < 2) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    // Hoàn thành bài học
                    Get.back();
                    Get.snackbar(
                      'Hoàn thành',
                      'Bạn đã hoàn thành bài học ${widget.lesson.title}!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep < 2 ? 'Tiếp theo' : 'Hoàn thành',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentStep < 2 ? Icons.arrow_forward : Icons.check,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}