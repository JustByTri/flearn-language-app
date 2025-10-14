import 'package:flearn_app/features/survey/view/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
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
      appBar: AppBar(title: const Text('Chọn ngôn ngữ')),
      body: Obx(() {
        final langsMap = surveyViewModel.languages;
        if (surveyViewModel.isLoadingLanguages.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: langsMap.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () {
                GetStorage().write('selectedLanguageId', entry.key);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurveyScreen(),
                  ),
                );
              },
            );
          }).toList(),
        );
      }),
    );
  }
}