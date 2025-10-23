import 'dart:ui';

import 'package:flearn_app/features/course/view/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../viewmodel/course_viewmodel.dart';

class CourseLessonScreen extends StatefulWidget {
  final String unitId;
  final String unitTitle;
  const CourseLessonScreen({super.key, required this.unitId, required this.unitTitle});

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  late final CourseViewModel courseViewModel;

  @override
  void initState() {
    super.initState();
    courseViewModel = Get.find<CourseViewModel>();
    courseViewModel.fetchCourseLessons(widget.unitId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.unitTitle,
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Obx(() {
          if (courseViewModel.isLoadingLesson.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final lessons = courseViewModel.lessons;
          if (lessons.isEmpty) {
            return _buildEmptyState();
          }
          return _buildLessonsList(lessons);
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeSlideAnimation(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_lesson_outlined,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có bài học nào',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chương này hiện chưa có nội dung bài học',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(List<dynamic> lessons) {
    return FadeSlideAnimation(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return _buildLessonCard(lesson, index);
        },
      ),
    );
  }

  Widget _buildLessonCard(dynamic lesson, int index) {
    final hasVideo = lesson.videoUrl != null && lesson.videoUrl.isNotEmpty;

    return Card(
      elevation: 8,
      shadowColor: AppColors.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              AppColors.primary.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (hasVideo) _buildVideoSection(lesson),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLessonHeader(lesson),
                  const SizedBox(height: 20),
                  _buildLessonContent(lesson),
                  const SizedBox(height: 20),
                  _buildActionButtons(lesson),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(dynamic lesson) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: VideoPlayerWidget(videoUrl: lesson.videoUrl),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _showFullscreenVideo(lesson),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonHeader(dynamic lesson) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.play_lesson,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (lesson.totalExercises > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz, color: AppColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${lesson.totalExercises} bài tập',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton(
            icon: Icon(Icons.more_vert, color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 12,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.article, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                        'Xem nội dung',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
                onTap: () {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _showContentDialog(lesson);
                  });
                },
              ),
              if (lesson.documentUrl != null && lesson.documentUrl.isNotEmpty)
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                          'Tài liệu PDF',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Implement PDF viewer
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonContent(dynamic lesson) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mô tả bài học',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic lesson) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to lesson detail
            },
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text('Bắt đầu học'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () => _showContentDialog(lesson),
            icon: Icon(Icons.article_outlined, color: AppColors.primary),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (lesson.documentUrl != null && lesson.documentUrl.isNotEmpty) ...[
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Open PDF
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullscreenVideo(dynamic lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              lesson.title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: VideoPlayerWidget(videoUrl: lesson.videoUrl),
          ),
        ),
      ),
    );
  }

  void _showContentDialog(dynamic lesson) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.article, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Html(data: lesson.content),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}