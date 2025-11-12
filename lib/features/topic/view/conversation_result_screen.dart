import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';
import 'topic_screen.dart';
import 'package:translator/translator.dart';

class ConversationResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  const ConversationResultScreen({super.key, required this.resultData});

  @override
  State<ConversationResultScreen> createState() => _ConversationResultScreenState();
}

class _ConversationResultScreenState extends State<ConversationResultScreen> {
  final GoogleTranslator _translator = GoogleTranslator();

  bool _showOriginalFeedback = true;
  bool _showOriginalStrengths = true;
  bool _showOriginalImprovements = true;

  String _translatedFeedback = '';
  List<String> _translatedStrengths = [];
  List<String> _translatedImprovements = [];

  bool _isTranslatingFeedback = false;
  bool _isTranslatingStrengths = false;
  bool _isTranslatingImprovements = false;

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

  // Translate text using Google Translator
  Future<String> _translateText(String text) async {
    try {
      if (text.trim().isEmpty) return text;
      // Translate from auto-detect to Vietnamese
      final translation = await _translator.translate(text, to: 'vi');
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text; // Return original text if translation fails
    }
  }

  // Translate feedback
  Future<void> _translateFeedback(String originalText) async {
    if (_translatedFeedback.isNotEmpty) {
      // Already translated, just toggle
      setState(() {
        _showOriginalFeedback = !_showOriginalFeedback;
      });
      return;
    }

    setState(() {
      _isTranslatingFeedback = true;
    });

    final translated = await _translateText(originalText);

    setState(() {
      _translatedFeedback = translated;
      _showOriginalFeedback = false;
      _isTranslatingFeedback = false;
    });
  }

  // Translate strengths list
  Future<void> _translateStrengthsList(List<String> originalList) async {
    if (_translatedStrengths.isNotEmpty) {
      // Already translated, just toggle
      setState(() {
        _showOriginalStrengths = !_showOriginalStrengths;
      });
      return;
    }

    setState(() {
      _isTranslatingStrengths = true;
    });

    List<String> translated = [];
    for (String item in originalList) {
      final translatedItem = await _translateText(item);
      translated.add(translatedItem);
    }

    setState(() {
      _translatedStrengths = translated;
      _showOriginalStrengths = false;
      _isTranslatingStrengths = false;
    });
  }

  // Translate improvements list
  Future<void> _translateImprovementsList(List<String> originalList) async {
    if (_translatedImprovements.isNotEmpty) {
      // Already translated, just toggle
      setState(() {
        _showOriginalImprovements = !_showOriginalImprovements;
      });
      return;
    }

    setState(() {
      _isTranslatingImprovements = true;
    });

    List<String> translated = [];
    for (String item in originalList) {
      final translatedItem = await _translateText(item);
      translated.add(translatedItem);
    }

    setState(() {
      _translatedImprovements = translated;
      _showOriginalImprovements = false;
      _isTranslatingImprovements = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    final feedbackOriginal = widget.resultData['aiFeedback']?.toString() ?? "";
    final feedback = _showOriginalFeedback ? feedbackOriginal : _translatedFeedback;

    final strengthsOriginal = _parseFeedback(widget.resultData['strengths']);
    final strengths = _showOriginalStrengths ? strengthsOriginal : _translatedStrengths;

    final improvementsOriginal = _parseFeedback(widget.resultData['improvements']);
    final improvements = _showOriginalImprovements ? improvementsOriginal : _translatedImprovements;

    final totalMessages = widget.resultData['totalMessages'] ?? 0;
    final sessionDuration = widget.resultData['sessionDuration'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
        title: const Text(
          "Kết quả luyện tập",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompletionCard(),
            const SizedBox(height: 24),
            if(feedbackOriginal.isNotEmpty) _buildSectionTitle("Nhận xét tổng quan từ AI"),
            if(feedbackOriginal.isNotEmpty) _buildFeedbackCard(
              feedback,
              feedbackOriginal,
              _showOriginalFeedback,
              _isTranslatingFeedback,
              () => _translateFeedback(feedbackOriginal),
            ),
            if (strengthsOriginal.isNotEmpty)
              _buildFeedbackList(
                "Điểm mạnh",
                strengths,
                strengthsOriginal,
                CupertinoIcons.hand_thumbsup_fill,
                Colors.green,
                _showOriginalStrengths,
                _isTranslatingStrengths,
                () => _translateStrengthsList(strengthsOriginal),
              ),
            if (improvementsOriginal.isNotEmpty)
              _buildFeedbackList(
                "Gợi ý cải thiện",
                improvements,
                improvementsOriginal,
                CupertinoIcons.lightbulb_fill,
                Colors.orange,
                _showOriginalImprovements,
                _isTranslatingImprovements,
                () => _translateImprovementsList(improvementsOriginal),
              ),
            const SizedBox(height: 24),
            _buildStatsRow(totalMessages, sessionDuration),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: ()=> Get.offAll(() => const NavigationMenu()),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white, size: 48),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                " Đã hoàn thành!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 4),

            ],
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

  Widget _buildFeedbackCard(String text, String originalText, bool showOriginal, bool isTranslating, VoidCallback onTranslate) {
    // Always show translate button if original text is not empty
    final showTranslateButton = originalText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4)
            )
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: isTranslating
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đang dịch...',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        text.isEmpty ? originalText : text,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
          if (showTranslateButton) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: isTranslating ? null : onTranslate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        showOriginal ? CupertinoIcons.globe : CupertinoIcons.arrow_turn_up_left,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        showOriginal ? "Dịch sang tiếng Việt" : "Xem bản gốc",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackList(
    String title,
    List<String> items,
    List<String> originalItems,
    IconData icon,
    Color iconColor,
    bool showOriginal,
    bool isTranslating,
    VoidCallback onTranslate,
  ) {
    // Always show translate button if there are original items
    final showTranslateButton = originalItems.isNotEmpty;
    final displayItems = items.isEmpty ? originalItems : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4)
                )
              ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTranslating)
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Đang dịch...',
                      style: TextStyle(
                        fontSize: 15,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                ...displayItems.asMap().entries.map((entry) {
                  final isLast = entry.key == displayItems.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              if (showTranslateButton) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: isTranslating ? null : onTranslate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: iconColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showOriginal ? CupertinoIcons.globe : CupertinoIcons.arrow_turn_up_left,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            showOriginal ? "Dịch sang tiếng Việt" : "Xem bản gốc",
                            style: TextStyle(
                              fontSize: 13,
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
        _buildStatItem(CupertinoIcons.chat_bubble_2_fill, "$messages", "Tin nhắn", Colors.blue),
        _buildStatItem(CupertinoIcons.clock_fill, durationString, "Thời gian", Colors.purple),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(), // Go back to try again
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Luyện tập lại",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Get.offAll(() => const TopicScreen()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: const Text(
                  "Chủ đề khác",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
