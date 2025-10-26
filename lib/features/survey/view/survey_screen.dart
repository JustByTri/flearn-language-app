import 'package:flearn_app/features/survey/view/survey_question_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../viewmodel/survey_viewmodel.dart';
import '../model/goal.dart';
import '../../auth/view/home_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final surveyViewModel = Get.find<SurveyViewModel>(); // Use Get.find since it's already put
  final Set<int> selectedGoalIds = {};

  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    final storedLang = box.read('selectedLanguageId') as String?;
    if (storedLang != null) {
      surveyViewModel.selectedLanguageId = storedLang;
    }
    surveyViewModel.fetchGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(), // Nút back
        ),
        title: const Text(
          'Mục tiêu của bạn',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (surveyViewModel.isLoadingGoals.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return FadeSlideAnimation(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    'Bạn muốn học để làm gì? Chọn một hoặc nhiều mục tiêu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: surveyViewModel.goals.length,
                    itemBuilder: (context, index) {
                      return _buildGoalCard(surveyViewModel.goals[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildStartButton(),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final isSelected = selectedGoalIds.contains(goal.id);
    return GestureDetector(
      onTap: () {
        // Logic is preserved
        setState(() {
          if (isSelected) {
            selectedGoalIds.remove(goal.id);
          } else {
            selectedGoalIds.add(goal.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (goal.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final bool isEnabled = selectedGoalIds.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _startAssessment : null, // Logic is preserved
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Blue button
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isEnabled ? 2 : 0,
        ),
        child: const Text(
          'Bắt đầu đánh giá',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _startAssessment() async {
    // This entire block of logic is preserved
    final languageId = GetStorage().read('selectedLanguageId') as String?;
    if (languageId == null || selectedGoalIds.isEmpty) return;

    await surveyViewModel.startAssessment(languageId, selectedGoalIds.toList());
    final assessmentId = surveyViewModel.assessment.value?.assessmentId;

    if (assessmentId != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SurveyQuestionScreen(assessmentId: assessmentId),
        ),
      );
    } else if (mounted) {
      final errorMsg = surveyViewModel.errorMessage.value ?? '';
      if (errorMsg.contains('ASSESSMENT_ALREADY_ACCEPTED') || errorMsg.contains('chấp nhận kết quả')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Đã có kết quả khảo sát'),
            content: const Text(
              'Bạn đã hoàn thành và chấp nhận kết quả đánh giá cho ngôn ngữ này.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Về trang chủ'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo bài đánh giá. Vui lòng thử lại!')),
        );
      }
    }
  }
}
