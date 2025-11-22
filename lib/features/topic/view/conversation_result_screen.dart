import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:translator/translator.dart';
import '../../../shared/widgets/mainBottomNavbar.dart';

class ConversationResultScreen extends StatefulWidget {
  final Map<String, dynamic> resultData;
  const ConversationResultScreen({super.key, required this.resultData});

  @override
  State<ConversationResultScreen> createState() => _ConversationResultScreenState();
}

class _ConversationResultScreenState extends State<ConversationResultScreen> {
  bool isSummaryTranslated = false;
  bool isFluentTranslated = false;
  bool isGrammarTranslated = false;
  bool isVocabularyTranslated = false;
  bool isCultureTranslated = false;
  bool isPositiveTranslated = false;
  bool isAreasTranslated = false;
  bool isObservationsTranslated = false;

  String? summaryVi;
  String? fluentAssessmentVi;
  List<String>? fluentExamplesVi;
  List<String>? fluentImprovementsVi;
  String? fluentLevelVi;
  String? grammarAssessmentVi;
  List<String>? grammarExamplesVi;
  List<String>? grammarImprovementsVi;
  String? grammarLevelVi;
  String? vocabularyAssessmentVi;
  List<String>? vocabularyExamplesVi;
  List<String>? vocabularyImprovementsVi;
  String? vocabularyLevelVi;
  String? cultureAssessmentVi;
  List<String>? cultureExamplesVi;
  List<String>? cultureImprovementsVi;
  String? cultureLevelVi;
  List<String> positivePatternsVi = [];
  List<String> areasNeedingWorkVi = [];
  List<Map<String, dynamic>> specificObservationsVi = [];

  bool loadingSummary = false;
  bool loadingFluent = false;
  bool loadingGrammar = false;
  bool loadingVocabulary = false;
  bool loadingCulture = false;
  bool loadingPositive = false;
  bool loadingAreas = false;
  bool loadingObservations = false;

  final translator = GoogleTranslator();

  Future<void> _translateSummary(String text) async {
    setState(() { loadingSummary = true; });
    final result = await translator.translate(text, from: 'auto', to: 'vi');
    setState(() {
      summaryVi = result.text;
      isSummaryTranslated = true;
      loadingSummary = false;
    });
  }

  Future<void> _translateFluent(Map<String, dynamic> analysis) async {
    setState(() { loadingFluent = true; });
    fluentAssessmentVi = (await translator.translate(analysis['qualitativeAssessment'] ?? '', from: 'auto', to: 'vi')).text;
    fluentLevelVi = (await translator.translate(analysis['currentLevel'] ?? '', from: 'auto', to: 'vi')).text;
    fluentExamplesVi = [];
    for (var e in (analysis['specificExamples'] as List? ?? [])) {
      fluentExamplesVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    fluentImprovementsVi = [];
    for (var e in (analysis['suggestedImprovements'] as List? ?? [])) {
      fluentImprovementsVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    setState(() {
      isFluentTranslated = true;
      loadingFluent = false;
    });
  }

  Future<void> _translateGrammar(Map<String, dynamic> analysis) async {
    setState(() { loadingGrammar = true; });
    grammarAssessmentVi = (await translator.translate(analysis['qualitativeAssessment'] ?? '', from: 'auto', to: 'vi')).text;
    grammarLevelVi = (await translator.translate(analysis['currentLevel'] ?? '', from: 'auto', to: 'vi')).text;
    grammarExamplesVi = [];
    for (var e in (analysis['specificExamples'] as List? ?? [])) {
      grammarExamplesVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    grammarImprovementsVi = [];
    for (var e in (analysis['suggestedImprovements'] as List? ?? [])) {
      grammarImprovementsVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    setState(() {
      isGrammarTranslated = true;
      loadingGrammar = false;
    });
  }

  Future<void> _translateVocabulary(Map<String, dynamic> analysis) async {
    setState(() { loadingVocabulary = true; });
    vocabularyAssessmentVi = (await translator.translate(analysis['qualitativeAssessment'] ?? '', from: 'auto', to: 'vi')).text;
    vocabularyLevelVi = (await translator.translate(analysis['currentLevel'] ?? '', from: 'auto', to: 'vi')).text;
    vocabularyExamplesVi = [];
    for (var e in (analysis['specificExamples'] as List? ?? [])) {
      vocabularyExamplesVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    vocabularyImprovementsVi = [];
    for (var e in (analysis['suggestedImprovements'] as List? ?? [])) {
      vocabularyImprovementsVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    setState(() {
      isVocabularyTranslated = true;
      loadingVocabulary = false;
    });
  }

  Future<void> _translateCulture(Map<String, dynamic> analysis) async {
    setState(() { loadingCulture = true; });
    cultureAssessmentVi = (await translator.translate(analysis['qualitativeAssessment'] ?? '', from: 'auto', to: 'vi')).text;
    cultureLevelVi = (await translator.translate(analysis['currentLevel'] ?? '', from: 'auto', to: 'vi')).text;
    cultureExamplesVi = [];
    for (var e in (analysis['specificExamples'] as List? ?? [])) {
      cultureExamplesVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    cultureImprovementsVi = [];
    for (var e in (analysis['suggestedImprovements'] as List? ?? [])) {
      cultureImprovementsVi!.add((await translator.translate(e, from: 'auto', to: 'vi')).text);
    }
    setState(() {
      isCultureTranslated = true;
      loadingCulture = false;
    });
  }

  Future<void> _translatePositive(List<String> patterns) async {
    setState(() { loadingPositive = true; });
    positivePatternsVi = [];
    for (var e in patterns) {
      final translated = (await translator.translate(e, from: 'auto', to: 'vi')).text;
      positivePatternsVi.add(translated);
    }
    setState(() {
      isPositiveTranslated = true;
      loadingPositive = false;
    });
  }

  Future<void> _translateAreas(List<String> areas) async {
    setState(() { loadingAreas = true; });
    areasNeedingWorkVi = [];
    for (var e in areas) {
      final translated = (await translator.translate(e, from: 'auto', to: 'vi')).text;
      areasNeedingWorkVi.add(translated);
    }
    setState(() {
      isAreasTranslated = true;
      loadingAreas = false;
    });
  }

  Future<void> _translateObservations(List<Map<String, dynamic>> observations) async {
    setState(() { loadingObservations = true; });
    specificObservationsVi = [];
    for (var obs in observations) {
      final newObs = Map<String, dynamic>.from(obs);
      for (var k in ['category', 'observation', 'impact', 'example']) {
        if (newObs[k] != null && newObs[k].toString().isNotEmpty) {
          final translated = (await translator.translate(newObs[k].toString(), from: 'auto', to: 'vi')).text;
          newObs[k] = translated;
        }
      }
      specificObservationsVi.add(newObs);
    }
    setState(() {
      isObservationsTranslated = true;
      loadingObservations = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.resultData;
    final sessionDuration = data['sessionDuration'] ?? 0;
    final totalMessages = data['totalMessages'] ?? 0;
    final progressSummary = isSummaryTranslated ? '[VI] ${data['progressSummary'] ?? ''}' : data['progressSummary']?.toString() ?? '';
    final fluentAnalysis = data['fluentAnalysis'] as Map<String, dynamic>?;
    final grammarAnalysis = data['grammarAnalysis'] as Map<String, dynamic>?;
    final vocabularyAnalysis = data['vocabularyAnalysis'] as Map<String, dynamic>?;
    final culturalAnalysis = data['culturalAnalysis'] as Map<String, dynamic>?;
    final positivePatterns = (data['positivePatterns'] as List?)?.cast<String>() ?? [];
    final areasNeedingWork = (data['areasNeedingWork'] as List?)?.cast<String>() ?? [];
    final specificObservations = (data['specificObservations'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
        child: Column(
          children: [
            _buildCompletionHeader(sessionDuration, totalMessages),
            if (progressSummary.isNotEmpty)
              _buildSummarySection(progressSummary, isSummaryTranslated, () {
                _translateSummary(progressSummary);
              }, () {
                setState(() { isSummaryTranslated = false; });
              }),
            if (fluentAnalysis != null)
              _buildSkillAnalysis('Độ trôi chảy', fluentAnalysis, Icons.record_voice_over, AppColors.primary, isFluentTranslated, () {
                _translateFluent(fluentAnalysis);
              }, () {
                setState(() { isFluentTranslated = false; });
              }),
            if (grammarAnalysis != null)
              _buildSkillAnalysis('Ngữ pháp', grammarAnalysis, Icons.spellcheck, const Color(0xFF00897B), isGrammarTranslated, () {
                _translateGrammar(grammarAnalysis);
              }, () {
                setState(() { isGrammarTranslated = false; });
              }),
            if (vocabularyAnalysis != null)
              _buildSkillAnalysis('Từ vựng', vocabularyAnalysis, Icons.library_books, const Color(0xFF5E35B1), isVocabularyTranslated, () {
                _translateVocabulary(vocabularyAnalysis);
              }, () {
                setState(() { isVocabularyTranslated = false; });
              }),
            if (culturalAnalysis != null)
              _buildSkillAnalysis('Hiểu biết văn hóa', culturalAnalysis, Icons.public, const Color(0xFFFF6F00), isCultureTranslated, () {
                _translateCulture(culturalAnalysis);
              }, () {
                setState(() { isCultureTranslated = false; });
              }),
            if (positivePatterns.isNotEmpty)
              _buildListSection('Điểm mạnh', positivePatterns, Icons.thumb_up, Colors.green, isPositiveTranslated, () {
                _translatePositive(positivePatterns);
              }, () {
                setState(() { isPositiveTranslated = false; });
              }),
            if (areasNeedingWork.isNotEmpty)
              _buildListSection('Cần cải thiện', areasNeedingWork, Icons.trending_up, Colors.orange, isAreasTranslated, () {
                _translateAreas(areasNeedingWork);
              }, () {
                setState(() { isAreasTranslated = false; });
              }),
            if (specificObservations.isNotEmpty)
              _buildObservationsSection(specificObservations, isObservationsTranslated, () {
                _translateObservations(specificObservations);
              }, () {
                setState(() { isObservationsTranslated = false; });
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildCompletionHeader(int duration, int messages) {
    final minutes = (duration / 60).floor();
    final seconds = duration % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((0.05 * 255).toInt()),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withAlpha((0.1 * 255).toInt()), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hoàn thành!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(Icons.timer, '$minutes:${seconds.toString().padLeft(2, '0')}'),
              const SizedBox(width: 16),
              _buildStatChip(Icons.chat_bubble_outline, '$messages tin nhắn'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha((0.2 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String summary, bool isTranslated, VoidCallback onTranslate, VoidCallback onReset) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tổng quan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isTranslated)
                ElevatedButton.icon(
                  onPressed: onTranslate,
                  icon: const Icon(Icons.translate, size: 18),
                  label: const Text('Dịch ra tiếng Việt', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (isTranslated)
                ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Đổi lại tiếng Anh', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isTranslated && summaryVi != null ? summaryVi! : summary,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (loadingSummary) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillAnalysis(String skillName, Map<String, dynamic> analysis, IconData icon, Color color, bool isTranslated, VoidCallback onTranslate, VoidCallback onReset) {
    String assessment;
    List<String> examples;
    List<String> improvements;
    String level;
    bool loading;
    if (skillName == 'Độ trôi chảy') {
      assessment = isTranslated && fluentAssessmentVi != null ? fluentAssessmentVi! : analysis['qualitativeAssessment']?.toString() ?? '';
      examples = isTranslated && fluentExamplesVi != null ? fluentExamplesVi! : (analysis['specificExamples'] as List?)?.cast<String>() ?? [];
      improvements = isTranslated && fluentImprovementsVi != null ? fluentImprovementsVi! : (analysis['suggestedImprovements'] as List?)?.cast<String>() ?? [];
      level = isTranslated && fluentLevelVi != null ? fluentLevelVi! : analysis['currentLevel']?.toString() ?? '';
      loading = loadingFluent;
    } else if (skillName == 'Ngữ pháp') {
      assessment = isTranslated && grammarAssessmentVi != null ? grammarAssessmentVi! : analysis['qualitativeAssessment']?.toString() ?? '';
      examples = isTranslated && grammarExamplesVi != null ? grammarExamplesVi! : (analysis['specificExamples'] as List?)?.cast<String>() ?? [];
      improvements = isTranslated && grammarImprovementsVi != null ? grammarImprovementsVi! : (analysis['suggestedImprovements'] as List?)?.cast<String>() ?? [];
      level = isTranslated && grammarLevelVi != null ? grammarLevelVi! : analysis['currentLevel']?.toString() ?? '';
      loading = loadingGrammar;
    } else if (skillName == 'Từ vựng') {
      assessment = isTranslated && vocabularyAssessmentVi != null ? vocabularyAssessmentVi! : analysis['qualitativeAssessment']?.toString() ?? '';
      examples = isTranslated && vocabularyExamplesVi != null ? vocabularyExamplesVi! : (analysis['specificExamples'] as List?)?.cast<String>() ?? [];
      improvements = isTranslated && vocabularyImprovementsVi != null ? vocabularyImprovementsVi! : (analysis['suggestedImprovements'] as List?)?.cast<String>() ?? [];
      level = isTranslated && vocabularyLevelVi != null ? vocabularyLevelVi! : analysis['currentLevel']?.toString() ?? '';
      loading = loadingVocabulary;
    } else if (skillName == 'Hiểu biết văn hóa') {
      assessment = isTranslated && cultureAssessmentVi != null ? cultureAssessmentVi! : analysis['qualitativeAssessment']?.toString() ?? '';
      examples = isTranslated && cultureExamplesVi != null ? cultureExamplesVi! : (analysis['specificExamples'] as List?)?.cast<String>() ?? [];
      improvements = isTranslated && cultureImprovementsVi != null ? cultureImprovementsVi! : (analysis['suggestedImprovements'] as List?)?.cast<String>() ?? [];
      level = isTranslated && cultureLevelVi != null ? cultureLevelVi! : analysis['currentLevel']?.toString() ?? '';
      loading = loadingCulture;
    } else {
      assessment = analysis['qualitativeAssessment']?.toString() ?? '';
      examples = (analysis['specificExamples'] as List?)?.cast<String>() ?? [];
      improvements = (analysis['suggestedImprovements'] as List?)?.cast<String>() ?? [];
      level = analysis['currentLevel']?.toString() ?? '';
      loading = false;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.08 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            skillName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: level.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Level: $level',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          trailing: !isTranslated
              ? ElevatedButton.icon(
                  onPressed: onTranslate,
                  icon: const Icon(Icons.translate, size: 18),
                  label: const Text('Dịch', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Đổi lại tiếng Anh', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
          children: [
            if (assessment.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Đánh giá:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assessment,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (examples.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ví dụ cụ thể:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...examples.map((example) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (improvements.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gợi ý cải thiện:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...improvements.map((improvement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        improvement,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (loading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon, Color color, bool isTranslated, VoidCallback onTranslate, VoidCallback onReset) {
    final displayItems = isTranslated ? (title == 'Điểm mạnh' ? positivePatternsVi : areasNeedingWorkVi) : items;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isTranslated)
                ElevatedButton.icon(
                  onPressed: onTranslate,
                  icon: const Icon(Icons.translate, size: 18),
                  label: const Text('Dịch', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (isTranslated)
                ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Đổi lại tiếng Anh', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildObservationsSection(List<Map<String, dynamic>> observations, bool isTranslated, VoidCallback onTranslate, VoidCallback onReset) {
    final displayObservations = isTranslated ? specificObservationsVi : observations;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha((0.2 * 255).toInt())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Nhận xét chi tiết',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isTranslated)
                ElevatedButton.icon(
                  onPressed: onTranslate,
                  icon: const Icon(Icons.translate, size: 18),
                  label: const Text('Dịch', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              if (isTranslated)
                ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.language, size: 18),
                  label: const Text('Đổi lại tiếng Anh', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayObservations.map((obs) {
            final category = obs['category']?.toString() ?? '';
            final observation = obs['observation']?.toString() ?? '';
            final impact = obs['impact']?.toString() ?? '';
            final example = obs['example']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (observation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      observation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (impact.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ảnh hưởng: $impact',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (example.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ví dụ: "$example"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => Get.offAll(() => const NavigationMenu()),

          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Về trang chủ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
