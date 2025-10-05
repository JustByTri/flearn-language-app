import 'package:flearn_app/features/survey/view/survey_question_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/colors.dart';
import '../viewmodel/survey_viewmodel.dart';
import '../model/goal.dart';
import 'assessment_result_screen.dart';

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
        if (surveyViewModel.isLoadingLanguages.value || surveyViewModel.isLoadingGoals.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final langsMap = surveyViewModel.languages;
        final langLabels = langsMap.values.toList();
        final goals = surveyViewModel.goals;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Chọn ngôn ngữ *'),
              const SizedBox(height: 12),
              _buildSelectionGrid(
                options: langLabels,
                selectedValue: selectedLanguageLabel,
                onChanged: (label) {
                  final entry = langsMap.entries.firstWhere((e) => e.value == label);
                  setState(() {
                    selectedLanguageLabel = label;
                    selectedLanguageId = entry.key;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Chọn mục tiêu (Goal) *'),
              const SizedBox(height: 12),
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
              const Spacer(),
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


                    final status = await surveyViewModel.checkAssessmentStatus(selectedLanguageId!, selectedGoalId!);

                    if (status != null) {
                      if (status['action'] == 'completed') {

                        final result = status['data']['result'];
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AssessmentResultScreen(result: {'data': {'voiceResult': result}}),
                          ),
                        );
                        return;
                      } else if (status['action'] == 'resumed') {

                        final assessmentId = status['data']['assessmentId'];
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => SurveyQuestionScreen(assessmentId: assessmentId),
                          ),
                        );
                        return;
                      }
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể tạo assessment. Vui lòng thử lại!')),
                      );
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