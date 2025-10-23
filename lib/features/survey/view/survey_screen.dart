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
  final surveyViewModel = Get.put(SurveyViewModel(Get.find()));


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
    final size = MediaQuery.of(context).size;

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
          child: Obx(() {
            if (surveyViewModel.isLoadingGoals.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final goals = surveyViewModel.goals;

            return FadeSlideAnimation(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Text(
                      'Bạn muốn đạt được mục tiêu gì?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ListView.builder(
                        itemCount: goals.length,
                        itemBuilder: (context, index) {
                          return _buildGoalCard(goals[index]);
                        },
                      ),
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
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final isSelected = selectedGoalIds.contains(goal.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedGoalIds.remove(goal.id);
              } else {
                selectedGoalIds.add(goal.id);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isSelected ? 15 : 10,
                  offset: Offset(0, isSelected ? 6 : 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        goal.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedGoalIds.isNotEmpty
              ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
              : [Colors.grey, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (selectedGoalIds.isNotEmpty ? AppColors.primary : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: selectedGoalIds.isNotEmpty ? _startAssessment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'Bắt đầu đánh giá',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _startAssessment() async {
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
      if (errorMsg.contains('ASSESSMENT_ALREADY_ACCEPTED') ||
          errorMsg.contains('chấp nhận kết quả')) {
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
          const SnackBar(content: Text('Không thể tạo assessment. Vui lòng thử lại!')),
        );
      }
    }
  }
}