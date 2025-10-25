import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';

import '../model/topic.dart';
import '../model/conversationLanguage.dart';
import '../viewmodel/topic_viewmodel.dart';
import 'chatAi_screen.dart';

class ConfirmContextScreen extends StatefulWidget {
  final TopicModel topic;
  const ConfirmContextScreen({super.key, required this.topic});

  @override
  State<ConfirmContextScreen> createState() => _ConfirmContextScreenState();
}

class _ConfirmContextScreenState extends State<ConfirmContextScreen> {
  String? selectedLevel;
  bool _isLoading = false;

  List<String> getLevelsForCurrentLang() {
    final topicViewModel = Get.find<TopicViewModel>();
    final selectedLanguageId = GetStorage().read('selectedLanguageId') as String?;
    if (selectedLanguageId == null) return [];
    final lang = topicViewModel.conversationLanguages
        .firstWhereOrNull((e) => e.languageId == selectedLanguageId);
    return lang?.availableLevels ?? [];
  }

  @override
  void initState() {
    super.initState();
    final topicViewModel = Get.find<TopicViewModel>();
    if (topicViewModel.conversationLanguages.isEmpty) {
      topicViewModel.fetchConversationLanguages().then((_) {
        final levels = getLevelsForCurrentLang();
        setState(() {
          selectedLevel = levels.isNotEmpty ? levels.first : null;
        });
      });
    } else {
      final levels = getLevelsForCurrentLang();
      selectedLevel = levels.isNotEmpty ? levels.first : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicViewModel = Get.find<TopicViewModel>();
    return Obx(() {
      final levels = getLevelsForCurrentLang();
      return Stack(
        children: [
          AppScaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              title: Text(
                "Xác nhận chủ đề",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textLight),
                onPressed: () => Navigator.pop(context),
              ),
              elevation: 0,
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              widget.topic.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.topic.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary.withOpacity(0.8),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Divider(color: AppColors.primary.withOpacity(0.2), thickness: 1),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              value: selectedLevel,
                              items: levels
                                  .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLevel = value;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Chọn trình độ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "Quay lại",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                              final languageId = GetStorage().read('selectedLanguageId') as String?;
                              final difficultyLevel = selectedLevel ?? levels.first;
                              if (languageId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng chọn ngôn ngữ trước!')),
                                );
                                return;
                              }
                              setState(() => _isLoading = true); // Bắt đầu loading
                              final topicViewModel = Get.find<TopicViewModel>();
                              final conversationData = await topicViewModel.startConversation(
                                languageId: languageId,
                                topicId: widget.topic.topicId,
                                difficultyLevel: difficultyLevel,
                              );
                              setState(() => _isLoading = false); // Kết thúc loading
                              if (conversationData != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      topic: widget.topic,
                                      conversationData: conversationData,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không thể bắt đầu cuộc trò chuyện!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 8,
                            ),
                            child: Text(
                              "Bắt đầu chat",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
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
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
        ],
      );
    });
  }
}