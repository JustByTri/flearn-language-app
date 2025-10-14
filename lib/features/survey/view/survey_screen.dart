import 'package:flearn_app/features/survey/view/survey_question_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../../auth/view/home_screen.dart';
import '../viewmodel/survey_viewmodel.dart';
import '../model/goal.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final surveyViewModel = Get.put(SurveyViewModel(Get.find()));

  String? selectedLanguageId;
  String? selectedLanguageLabel;
  int? selectedGoalId;
  String? selectedGoalLabel;

  @override
  void initState() {
    super.initState();
    surveyViewModel.fetchLanguages();
    surveyViewModel.fetchGoals();

    ever(surveyViewModel.languages, (_) {
      if (mounted && surveyViewModel.languages.isNotEmpty) {
        setState(() {
          selectedLanguageId = surveyViewModel.selectedLanguageId ?? surveyViewModel.languages.keys.first;
          selectedLanguageLabel = surveyViewModel.languages[selectedLanguageId];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Khảo sát Luyện Nói'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (surveyViewModel.isLoadingGoals.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final goals = surveyViewModel.goals;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildSectionTitle('Chọn mục tiêu'),
                _buildSelectionGridGoal(
                  goals: goals,
                  selectedGoalId: selectedGoalId,
                  onChanged: (goal) {
                    setState(() {
                      selectedGoalId = goal.id;
                      selectedGoalLabel = goal.name;
                    });

                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedLanguageId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn ngôn ngữ!')),
                        );
                        return;
                      }
                      if (selectedGoalId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng chọn mục tiêu!')),
                        );
                        return;
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang tạo assessment...')),
                        );
                      }

                      await surveyViewModel.startAssessment(selectedLanguageId!, selectedGoalId!);
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
                                'Bạn đã hoàn thành và chấp nhận kết quả đánh giá cho ngôn ngữ này. Không thể làm lại khảo sát.',
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Bắt đầu đánh giá',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildSelectionGrid({
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectionGridGoal({
    required List<Goal> goals,
    required int? selectedGoalId,
    required ValueChanged<Goal> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goals.map((goal) {
        final isSelected = selectedGoalId == goal.id;
        return GestureDetector(
          onTap: () => onChanged(goal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal.description,
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}