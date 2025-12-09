import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../model/lesson_progress_exercise.dart';
import '../viewmodel/course_viewmodel.dart';
import 'exercise_debate_screen.dart';
import 'exercise_picture_description_screen.dart';
import 'exercise_repeat_after_me_screen.dart';
import 'exercise_story_telling_screen.dart';
import 'exercise_submission_list_screen.dart';

class CourseLessonExerciseScreen extends StatefulWidget {
  final String lessonId;

  const CourseLessonExerciseScreen({super.key, required this.lessonId});

  @override
  State<CourseLessonExerciseScreen> createState() => _CourseLessonExerciseScreenState();
}

class _CourseLessonExerciseScreenState extends State<CourseLessonExerciseScreen> with WidgetsBindingObserver {  // Thêm WidgetsBindingObserver
  final CourseViewModel courseViewModel = Get.find<CourseViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // Thêm observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // Xóa observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Khi app resumed (trở lại foreground), refresh dữ liệu bài tập
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    await courseViewModel.fetchLessonProgressExercises(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      child: Obx(() {
        final loading = courseViewModel.isLoadingProgressExercises.value;
        final list = courseViewModel.progressExercises;
        print('lessonId: ${widget.lessonId}');
        print('list: $list');

        // Loading State
        if (loading && list.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        // Empty State
        if (list.isEmpty) {
          // Cần bọc trong ListView hoặc CustomScrollView để RefreshIndicator hoạt động khi list rỗng
          return Stack(
            children: [
              ListView(), // Dummy list để kích hoạt scroll gesture cho refresh
              _buildEmptyState(
                icon: Icons.assignment_outlined,
                message: 'Không có bài tập cho bài học này',
              ),
            ],
          );
        }

        // Giữ các hàm helper (có thể dùng chung vì field giống)
        Color _difficultyColor(String diff) {
          switch (diff.toLowerCase()) {
            case 'easy':
              return Colors.green;
            case 'medium':
              return Colors.orange;
            case 'hard':
              return Colors.red;
            case 'advanced':
              return Colors.purple;
            default:
              return Colors.grey;
          }
        }

        Color _typeColor(String t) {
          switch (t) {
            case 'RepeatAfterMe':
              return Colors.blue;
            case 'PictureDescription':
              return Colors.purple;
            case 'Debate':
              return Colors.brown;
            case 'StoryTelling':
              return Colors.teal;
            default:
              return AppColors.primary;
          }
        }

        String _typeLabel(String t) {
          switch (t) {
            case 'RepeatAfterMe':
              return 'Lặp lại theo mẫu';
            case 'PictureDescription':
              return 'Mô tả tranh';
            case 'Debate':
              return 'Tranh luận';
            case 'StoryTelling':
              return 'Kể chuyện';
            default:
              return 'Bài tập';
          }
        }

        String _difficultyLabel(String diff) {
          switch (diff.toLowerCase()) {
            case 'easy':
              return 'Dễ';
            case 'medium':
              return 'Trung bình';
            case 'hard':
              return 'Khó';
            case 'advanced':
              return 'Nâng cao';
            default:
              return diff;
          }
        }

        void _openExercise(LessonProgressExercise ex) {
          switch (ex.exerciseType) {
            case 'RepeatAfterMe':
              Get.to(() => ExerciseRepeatAfterMeScreen(exerciseId: ex.exerciseID));
              break;
            case 'PictureDescription':
              Get.to(() => ExerciseMultipleChoiceScreen(exerciseId: ex.exerciseID));
              break;
            case 'Debate':
              Get.to(() => ExerciseDebateScreen(exerciseId: ex.exerciseID));
              break;
            case 'StoryTelling':
              Get.to(() => ExerciseFillInBlankScreen(exerciseId: ex.exerciseID));
              break;
            default:
              Get.to(() => ExerciseRepeatAfterMeScreen(exerciseId: ex.exerciseID));
          }
        }

        void _viewScore(LessonProgressExercise ex) {
          Get.to(
                () => ExerciseSubmissionListScreen(
              exerciseId: ex.exerciseID,
              exerciseTitle: ex.title,
            ),
          );
        }

        // SỬ DỤNG CustomScrollView THAY VÌ SingleChildScrollView + ListView(shrinkWrap: true)
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Tiêu đề
            // const SliverToBoxAdapter(
            //   child: Padding(
            //     padding: EdgeInsets.only(bottom: 12),
            //     child: Text(
            //       'Bài tập',
            //       style: TextStyle(
            //         fontSize: 20,
            //         fontWeight: FontWeight.bold,
            //         color: AppColors.textPrimary,
            //       ),
            //     ),
            //   ),
            // ),

            // Danh sách bài tập (SliverList tối ưu hóa bộ nhớ và render)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final ex = list[i];
                  final typeColor = _typeColor(ex.exerciseType);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12), // Thay thế cho separatorBuilder
                    child: InkWell(
                      onTap: () => _openExercise(ex),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ex.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (ex.submissionId == null || (ex.submissionId is String && ex.submissionId!.isEmpty))
                                            SizedBox(
                                              height: 28,
                                              child: Chip(
                                                label: const Text(
                                                  'Chưa bắt đầu',
                                                  style: TextStyle(fontSize: 12, color: Colors.black87),
                                                ),
                                                backgroundColor: Colors.grey.shade200,
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                                elevation: 0,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            )
                                          else if (ex.isPassed)
                                            SizedBox(
                                              height: 28,
                                              child: Chip(
                                                label: const Text('Đạt', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                backgroundColor: Colors.green.shade600,
                                                avatar: const Icon(Icons.thumb_up, color: Colors.white, size: 14),
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                                elevation: 0,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              height: 28,
                                              child: Chip(
                                                label: const Text('Rớt', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                backgroundColor: Colors.red.shade600,
                                                avatar: const Icon(Icons.thumb_down, color: Colors.white, size: 14),
                                                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                                elevation: 0,
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Hiển thị điểm nếu có
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: typeColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _typeLabel(ex.exerciseType),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: typeColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (ex.difficulty.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _difficultyColor(ex.difficulty).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: _difficultyColor(ex.difficulty).withOpacity(0.5),
                                                ),
                                              ),
                                              child: Text(
                                                _difficultyLabel(ex.difficulty),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: _difficultyColor(ex.difficulty),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (ex.prompt.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          ex.prompt,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _viewScore(ex),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Xem điểm',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
            // Padding bottom cuối cùng
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ),
          ],
        );
      }),
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
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}