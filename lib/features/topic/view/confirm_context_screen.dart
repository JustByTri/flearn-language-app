import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';

import '../model/topic.dart';
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

  final Map<String, List<String>> defaultLevels = {
    'EN': ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
    'JP': ['N5', 'N4', 'N3', 'N2', 'N1'],
    'ZH': ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'],
  };

  List<String> getLevelsForCurrentLang() {
    final langCode = GetStorage().read('selectedLangCode') as String? ?? 'EN';
    return defaultLevels[langCode] ?? ['A1'];
  }

  @override
  void initState() {
    super.initState();
    final levels = getLevelsForCurrentLang();
    selectedLevel = levels.isNotEmpty ? levels.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final String contextText =
        "Bạn sắp bắt đầu cuộc trò chuyện với AI về chủ đề:\n\n"
        "${widget.topic.topicName}\n\n"
        "Mô tả: ${widget.topic.topicDescription}\n\n"
        "Hãy xác nhận để tiếp tục!";

    final levels = getLevelsForCurrentLang();

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Xác nhận ngữ cảnh",
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.topic.imageUrl != "default" && widget.topic.imageUrl.isNotEmpty
                            ? Image.network(
                          widget.topic.imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                              ),
                            ),
                            child: Icon(Icons.topic, size: 50, color: Colors.white),
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                            ),
                          ),
                          child: Icon(Icons.topic, size: 50, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.topic.topicName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        contextText,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
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
                      onPressed: () async {
                        final languageId = GetStorage().read('selectedLanguageId') as String?;
                        final difficultyLevel = selectedLevel ?? levels.first;
                        if (languageId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn ngôn ngữ trước!')),
                          );
                          return;
                        }
                        final topicViewModel = Get.find<TopicViewModel>();
                        final conversationData = await topicViewModel.startConversation(
                          languageId: languageId,
                          topicId: widget.topic.topicId,
                          difficultyLevel: difficultyLevel,
                        );
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
            ),
          ],
        ),
      ),
    );
  }
}