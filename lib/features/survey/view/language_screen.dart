import 'package:flearn_app/features/survey/view/survey_screen.dart';
import 'package:flearn_app/shared/widgets/mainBottomNavbar.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.offAll(() => const NavigationMenu()), // Quay về trang chủ
        ),
        title: const Text(
          'Khảo sát đầu vào',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (surveyViewModel.isLoadingLanguages.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final langsMap = surveyViewModel.languages;
          return FadeSlideAnimation(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Bạn muốn học ngôn ngữ nào?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lựa chọn của bạn sẽ quyết định bài kiểm tra đầu vào.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.separated(
                      itemCount: langsMap.entries.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = langsMap.entries.elementAt(index);
                        return _buildLanguageCard(entry.key, entry.value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLanguageCard(String languageId, String languageName) {
    final displayName = languageNameVi[languageName] ?? languageName;
    final flagEmoji = flagEmojis[languageName] ?? '🏳️';
    return InkWell(
      onTap: () {
        final box = GetStorage();
        final user = box.read('user') ?? {};
        user['languageId'] = languageId;
        box.write('user', user);
        box.write('selectedLanguageId', languageId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SurveyScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 18),
          ],
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

  final Map<String, String> flagEmojis = {
    'English': '🇬🇧',
    'Japanese': '🇯🇵',
    'Chinese': '🇨🇳',
    'Vietnamese': '🇻🇳',
  };
}
