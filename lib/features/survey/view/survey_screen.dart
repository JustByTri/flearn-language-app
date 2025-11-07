import 'package:flearn_app/features/survey/view/survey_question_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/constants/colors.dart';
import '../viewmodel/survey_viewmodel.dart';
import '../model/goal.dart';
import '../model/program.dart';
import '../../auth/view/home_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final surveyViewModel = Get.find<SurveyViewModel>();
  String? selectedProgramId;
  bool _isLoadingAssessment = false;


  @override
  void initState() {
    super.initState();
    final box = GetStorage();
    final languageId = box.read('selectedLanguageId') as String?;
    if (languageId != null) {
      surveyViewModel.fetchPrograms(languageId);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (surveyViewModel.isLoadingPrograms.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn chương trình',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: surveyViewModel.programs.length,
                  itemBuilder: (context, index) {
                    return _buildProgramCard(surveyViewModel.programs[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildStartButton(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProgramCard(Program program) {
    final isSelected = selectedProgramId == program.programId;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedProgramId = program.programId;
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
                    program.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (program.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      program.description,
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
    final bool isEnabled = selectedProgramId != null && !_isLoadingAssessment;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isEnabled ? _startAssessment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isEnabled ? 2 : 0,
        ),
        child: _isLoadingAssessment
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CupertinoActivityIndicator(
            color: Colors.white,
            radius: 12,
          ),
        )
            : const Text(
          'Bắt đầu khảo sát',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _startAssessment() async {
    setState(() => _isLoadingAssessment = true);
    final languageId = GetStorage().read('selectedLanguageId') as String?;
    if (languageId == null || selectedProgramId == null) {
      setState(() => _isLoadingAssessment = false);
      return;
    }

    await surveyViewModel.startAssessment(languageId, selectedProgramId!);
    final assessmentId = surveyViewModel.assessment.value?.assessmentId;

    setState(() => _isLoadingAssessment = false);

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
