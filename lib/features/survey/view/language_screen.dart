import 'package:flearn_app/features/survey/view/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';

import '../../../shared/widgets/fadeSlideAnimation.dart';
import '../viewmodel/survey_viewmodel.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final surveyViewModel = Get.put(SurveyViewModel(Get.find()));

  @override
  void initState() {
    super.initState();
    surveyViewModel.fetchLanguages();
  }

  @override
  Widget build(BuildContext context) {
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
            final langsMap = surveyViewModel.languages;
            if (surveyViewModel.isLoadingLanguages.value) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            return FadeSlideAnimation(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Chọn ngôn ngữ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn muốn học ngôn ngữ nào?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView(
                        children: langsMap.entries.map((entry) {
                          return _buildLanguageCard(entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(String languageId, String languageName) {
    final displayName = languageNameVi[languageName] ?? languageName;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            GetStorage().write('selectedLanguageId', languageId);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SurveyScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.language, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, String> languageNameVi = {
    'English': 'Tiếng Anh',
    'Japanese': 'Tiếng Nhật',
    'Chinese': 'Tiếng Trung',
    'Vietnamese': 'Tiếng Việt',
  };
}