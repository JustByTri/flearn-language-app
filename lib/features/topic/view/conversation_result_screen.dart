import 'package:flearn_app/features/auth/view/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'topic_screen.dart';

class ConversationResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;
  const ConversationResultScreen({super.key, required this.resultData});

  // Helper function to safely parse feedback data which can be a String or a List
  List<String> _parseFeedback(dynamic feedbackData) {
    if (feedbackData == null) return [];
    if (feedbackData is String) {
      if (feedbackData.isEmpty) return [];
      // Split string by newline characters
      return feedbackData.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    if (feedbackData is List) {
      // If it's already a list, just ensure all elements are strings
      return feedbackData.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return []; // Return empty list for other types
  }

  @override
  Widget build(BuildContext context) {
    final feedback = resultData['aiFeedback']?.toString() ?? "";
    final strengths = _parseFeedback(resultData['strengths']);
    final improvements = _parseFeedback(resultData['improvements']);
    final totalMessages = resultData['totalMessages'] ?? 0;
    final sessionDuration = resultData['sessionDuration'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
        title: const Text(
          "Kết quả luyện tập",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompletionCard(),
            const SizedBox(height: 24),
            if(feedback.isNotEmpty) _buildSectionTitle("Nhận xét tổng quan từ AI"),
            if(feedback.isNotEmpty) _buildFeedbackCard(feedback),
            if (strengths.isNotEmpty)
              _buildFeedbackList("Điểm mạnh", strengths, CupertinoIcons.hand_thumbsup, Colors.green),
            if (improvements.isNotEmpty)
              _buildFeedbackList("Gợi ý cải thiện", improvements, CupertinoIcons.arrow_up_circle, Colors.orange),
            const SizedBox(height: 24),
            _buildStatsRow(totalMessages, sessionDuration),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: ()=> Get.offAll(()=> const HomeScreen()),
                child: const Text(
                  "Về trang chủ",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF6A1B9A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Text(
            "Hoàn thành xuất sắc!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildFeedbackCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }

  Widget _buildFeedbackList(String title, List<String> items, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int messages, int durationInSeconds) {
    final duration = Duration(seconds: durationInSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final durationString = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(CupertinoIcons.chat_bubble_2_fill, "$messages Tin nhắn", Colors.blue),
        _buildStatItem(CupertinoIcons.clock_fill, durationString, Colors.purple),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(), // Go back to try again
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Luyện tập lại", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Get.offAll(() => const TopicScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Chọn chủ đề khác", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
