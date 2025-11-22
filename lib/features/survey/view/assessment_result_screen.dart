import 'package:flearn_app/di.dart';
import 'package:flearn_app/features/survey/view/language_screen.dart';
import 'package:flearn_app/features/survey/viewmodel/survey_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import '../model/assessment_result.dart';
import '../../../features/auth/viewmodel/login_viewmodel.dart';
import '../../../features/auth/view/home_screen.dart';

class AssessmentResultScreen extends StatefulWidget {
  final AssessmentResult result;

  const AssessmentResultScreen({super.key, required this.result});

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  final SurveyViewModel surveyViewModel = Get.find();
  bool _isAccepting = false;
  bool _isRejecting = false;

  Future<void> _onAcceptPressed() async {
    if (widget.result.determinedLevel == 'Unassessed') {
      if (!Get.isRegistered<LoginViewModel>()) {
        Get.put(LoginViewModel(Get.find()));
      }
      setupDI();
      Get.offAll(() => const NavigationMenu());
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    final success = await surveyViewModel.acceptVoiceAssessment(widget.result.learnerLanguageId);

    if (mounted) {
      if (success) {
        final box = GetStorage();
        final user = box.read('user') ?? {};
        user['languageId'] = widget.result.languageId;
        box.write('user', user);
        box.write('selectedLanguageId', widget.result.languageId);
        if (!Get.isRegistered<LoginViewModel>()) {
          Get.put(LoginViewModel(Get.find()));
        }
        setupDI();
        Get.offAll(() => const NavigationMenu());
      } else {
        setState(() {
          _isAccepting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra. Vui lòng thử lại.')),
        );
      }
    }
  }

  Future<void> _onRedoPressed() async {
    setState(() {
      _isRejecting = true;
    });

    final success = await surveyViewModel.rejectVoiceAssessment(widget.result.learnerLanguageId);

    if (mounted) {

      Get.offAll(() => const LanguageScreen());

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnassessed = widget.result.determinedLevel == 'Unassessed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kết quả đánh giá',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          _buildHeader(isUnassessed),
          const SizedBox(height: 24),
          _buildLevelCard(),
          const SizedBox(height: 24),
          if (widget.result.strengths.isNotEmpty) ...[
            _buildStrengthsCard(),
            const SizedBox(height: 24),
          ],
          if (widget.result.weaknesses.isNotEmpty) ...[
            _buildImprovementsCard(),
            const SizedBox(height: 24),
          ],
          _buildRecommendedCoursesCard(),  // Always show
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildHeader(bool isUnassessed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(13), // FIXED: withOpacity(0.05)
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/hurray.jpg',
            height: 120,
          ),
          const SizedBox(height: 16),
          Text(
            isUnassessed ? 'Chưa thể xếp hạng' : 'Chúc mừng!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUnassessed ? 'Bạn đã bỏ qua quá nhiều câu hỏi. Hãy thử làm lại để có kết quả chính xác nhé.' : 'Đây là kết quả đánh giá năng lực của bạn.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return _buildInfoCard(
      title: 'Trình độ của bạn',
      content: Text(
        widget.result.determinedLevel,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      isCentered: true,
    );
  }

  Widget _buildStrengthsCard() {
    return _buildInfoCard(
      title: 'Thế mạnh của bạn',
      content: Column(
        children: widget.result.strengths.map((strength) => _buildListItem(strength, Icons.check_circle, Colors.green)).toList(),
      ),
    );
  }

  Widget _buildImprovementsCard() {
    return _buildInfoCard(
      title: 'Cần cải thiện',
      content: Column(
        children: widget.result.weaknesses.map((weakness) => _buildListItem(weakness, Icons.track_changes, Colors.orange)).toList(),
      ),
    );
  }

  Widget _buildRecommendedCoursesCard() {
    if (widget.result.recommendedCourses.isEmpty) {
      return _buildInfoCard(
        title: 'Khóa học đề xuất',
        content: const Text(
          'Hiện tại chưa có khóa học đề xuất nào.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      );
    }
    return _buildInfoCard(
      title: 'Khóa học đề xuất',
      content: Column(
        children: widget.result.recommendedCourses.map((course) => _buildListItem(
          '${course.courseName} (${course.level}) - ${course.matchReason}',
          Icons.school,
          Colors.blue,
        )).toList(),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content, bool isCentered = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)
      ),
      child: Column(
        crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildListItem(String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _isAccepting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _onAcceptPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Khám phá ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _isRejecting
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
              onPressed: _onRedoPressed,
              child: const Text('Làm lại bài đánh giá', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
