import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/translate.dart';
import '../model/survey_request.dart';
import '../viewmodel/survey_viewmodel.dart';
import 'home_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final surveyViewModel = Get.put(SurveyViewModel(Get.find()));
  final PageController _pageController = PageController();

  int currentPage = 0;
  final int totalPages = 4;

  String? selectedCurrentLevel;
  String? selectedLearningStyle;
  String? selectedPrioritySkill;
  String? selectedTargetTimeline;
  String? selectedSpeakingChallenge;
  String? selectedPreferredAccent;
  int selectedConfidenceLevel = 5;


  final Map<String, String> availableLanguages = {

    '5a69a4e3-4b72-44c4-a798-6142161752f6': 'English',
    '6ee5120f-8d64-49cb-805d-075318efafa8': 'Chinese',
    '5d8e1adf-cd30-462a-b531-8daca3d0de8b': 'Japanese',
  };
  String? selectedLanguageLabel;
  String selectedLanguageId = '3fa85f64-5717-4562-b3fc-2c963f66afa6';


  final preferredLanguageIDController = TextEditingController(
      text: "3fa85f64-5717-4562-b3fc-2c963f66afa6"
  );
  final learningReasonController = TextEditingController();
  final previousExperienceController = TextEditingController();
  final interestedTopicsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    surveyViewModel.loadSurveyOptions();

    final box = GetStorage();
    final done = box.read('surveyCompleted') ?? false;
    if (done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
      return;
    }
  }

  @override
  void dispose() {
    preferredLanguageIDController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      setState(() => currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextPage() {
    switch (currentPage) {
      case 0:
        return selectedCurrentLevel != null;
      case 1:
        return selectedLearningStyle != null;
      case 2:
        return selectedPrioritySkill != null && selectedTargetTimeline != null;
      case 3:
        return selectedSpeakingChallenge != null && selectedPreferredAccent != null;
      default:
        return true;
    }
  }

  Future<void> _submitSurvey() async {
    final langIdToSend = selectedLanguageId.isNotEmpty ? selectedLanguageId : preferredLanguageIDController.text;
    final request = SurveyRequest(
      currentLevel: TranslationConstants.getEnglishValue(selectedCurrentLevel!),
      preferredLanguageID: langIdToSend,
      learningReason: TranslationConstants.getEnglishValue(selectedCurrentLevel!),
      previousExperience: "Self-study",
      preferredLearningStyle: TranslationConstants.getEnglishValue(selectedLearningStyle!),
      interestedTopics: "General",
      prioritySkills: TranslationConstants.getEnglishValue(selectedPrioritySkill!),
      targetTimeline: TranslationConstants.getEnglishValue(selectedTargetTimeline!),
      speakingChallenges: TranslationConstants.getEnglishValue(selectedSpeakingChallenge!),
      confidenceLevel: selectedConfidenceLevel,
      preferredAccent: TranslationConstants.getEnglishValue(selectedPreferredAccent!),
    );

    try {
      final success = await surveyViewModel.completeSurvey(request);
      if (!mounted) return;
      if (success) {
        await GetStorage().write('surveyCompleted', true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gửi khảo sát thành công!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gửi khảo sát thất bại!'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      final msg = e.toString();

      if (msg.contains('đã hoàn thành') || msg.toLowerCase().contains('already completed')) {
        await GetStorage().write('surveyCompleted', true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bạn đã hoàn thành khảo sát trước đó.'),
          backgroundColor: Colors.green,
        ));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi gửi khảo sát: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Khảo sát (${currentPage + 1}/$totalPages)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (surveyViewModel.isLoading.value && surveyViewModel.surveyOptions.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (surveyViewModel.surveyOptions.value == null) {
          return _buildErrorState();
        }

        final options = surveyViewModel.surveyOptions.value!.data;

        return Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(options),
                  _buildPage2(options),
                  _buildPage3(options),
                  _buildPage4(options),
                ],
              ),
            ),
            _buildNavigationButtons(),
            if (surveyViewModel.isLoading.value)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Không thể tải dữ liệu khảo sát'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => surveyViewModel.loadSurveyOptions(),
                child: const Text('Thử lại'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                ),
                child: const Text('Bỏ qua'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(totalPages, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < totalPages - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= currentPage ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPage1(options) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle('Về trình độ của bạn'),
          const SizedBox(height: 24),

          _buildSectionTitle('Trình độ hiện tại *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: options.currentLevels,
            selectedValue: selectedCurrentLevel,
            onChanged: (value) => setState(() => selectedCurrentLevel = value),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Ngôn ngữ học *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: availableLanguages.values.toList(),
            selectedValue: selectedLanguageLabel,
            onChanged: (label) {
              setState(() {
                selectedLanguageLabel = label;

                final entry = availableLanguages.entries.firstWhere(
                      (e) => e.value == label,
                  orElse: () => MapEntry(selectedLanguageId, label),
                );
                selectedLanguageId = entry.key;
                preferredLanguageIDController.text = selectedLanguageId;
              });
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Lý do bạn muốn học? *'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: learningReasonController,
            hint: 'VD: Để làm việc, du lịch, sở thích...',
            maxLines: 3,
          ),

          const SizedBox(height: 100), // Space for navigation buttons
        ],
      ),
    );
  }

  Widget _buildPage2(options) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle('Phong cách học tập'),
          const SizedBox(height: 16),
          _buildPageDescription('Bạn thích học theo cách nào nhất?'),
          const SizedBox(height: 24),

          _buildSectionTitle('Phong cách học ưa thích *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: TranslationConstants.translateList(options.learningStyles),
            selectedValue: selectedLearningStyle,
            onChanged: (value) => setState(() => selectedLearningStyle = value),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPage3(options) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle('Mục tiêu của bạn'),
          const SizedBox(height: 16),
          _buildPageDescription('Bạn muốn tập trung vào kỹ năng nào và trong bao lâu?'),
          const SizedBox(height: 24),

          _buildSectionTitle('Kỹ năng ưu tiên *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: TranslationConstants.translateList(options.prioritySkills),
            selectedValue: selectedPrioritySkill,
            onChanged: (value) => setState(() => selectedPrioritySkill = value),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Thời gian mục tiêu *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: TranslationConstants.translateList(options.targetTimelines),
            selectedValue: selectedTargetTimeline,
            onChanged: (value) => setState(() => selectedTargetTimeline = value),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPage4(options) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageTitle('Khó khăn và sở thích'),
          const SizedBox(height: 16),
          _buildPageDescription('Giúp chúng tôi hiểu thêm về bạn'),
          const SizedBox(height: 24),

          _buildSectionTitle('Khó khăn chính khi nói *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: TranslationConstants.translateList(options.speakingChallenges),
            selectedValue: selectedSpeakingChallenge,
            onChanged: (value) => setState(() => selectedSpeakingChallenge = value),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Mức độ tự tin khi nói: ${selectedConfidenceLevel}/10'),
          const SizedBox(height: 12),
          _buildConfidenceSlider(),

          const SizedBox(height: 24),

          _buildSectionTitle('Accent ưa thích *'),
          const SizedBox(height: 12),
          _buildSelectionGrid(
            options: TranslationConstants.translateList(options.preferredAccents),
            selectedValue: selectedPreferredAccent,
            onChanged: (value) => setState(() => selectedPreferredAccent = value),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPageTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildPageDescription(String description) {
    return Text(
      description,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
        height: 1.4,
      ),
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
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [
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

  Widget _buildConfidenceSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Không tự tin', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Text('Rất tự tin', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Slider(
            value: selectedConfidenceLevel.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey[300],
            thumbColor: AppColors.primary,
            label: selectedConfidenceLevel.toString(),
            onChanged: (value) {
              setState(() {
                selectedConfidenceLevel = value.round();
              });
            },
          ),
          Text(
            'Mức độ: ${selectedConfidenceLevel}/10',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại'),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (currentPage < totalPages - 1) {
                  if (_canProceedToNextPage()) {
                    _nextPage();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng chọn một lựa chọn!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else {
                  if (_canProceedToNextPage()) {
                    _submitSurvey();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng hoàn thành tất cả các lựa chọn!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                currentPage < totalPages - 1 ? 'Tiếp tục' : 'Hoàn thành',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
    );
  }
}