import 'package:country_icons/country_icons.dart';
import 'package:dio/dio.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/auth/viewmodel/login_viewmodel.dart';
import 'package:flearn_app/features/course/model/course.dart';
import 'package:flearn_app/features/topic/model/topic.dart';
import 'package:flearn_app/features/topic/viewmodel/topic_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../course/viewmodel/course_viewmodel.dart';
import '../../schedule/viewmodel/teacher_schedule_viewmodel.dart';
import '../../survey/view/survey_screen.dart';
import '../../survey/viewmodel/survey_viewmodel.dart';

class Language {
  final String id;
  final String langName;
  final String langCode;

  Language({required this.id, required this.langName, required this.langCode});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'],
      langName: json['langName'],
      langCode: json['langCode'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Language> _languages = [];
  String? _selectedLanguageId;
  bool _isLoadingLanguages = true;
  String? _selectedTopicName;

  late CourseViewModel courseViewModel;
  late TeacherScheduleViewModel teacherScheduleViewModel;
  late SurveyViewModel surveyViewModel;
  late LoginViewModel loginViewModel;
  late TopicViewModel topicViewModel;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _initializeViewModels();
    _loadInitialData();
  }

  void _initializeViewModels() {
    courseViewModel = Get.put(CourseViewModel(Get.find()));
    teacherScheduleViewModel = Get.put(TeacherScheduleViewModel(service: Get.find()));
    surveyViewModel = Get.put(SurveyViewModel(Get.find()));
    topicViewModel = Get.put(TopicViewModel(Get.find()));
    loginViewModel = Get.find<LoginViewModel>();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchLanguages(),
      _fetchOtherData(),
    ]);
  }

  Future<void> _fetchOtherData() async {
    try {
      await courseViewModel.fetchCourses();
      await topicViewModel.fetchTopics();
      await teacherScheduleViewModel.fetchSchedules();
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu khác: $e');
    }
  }

  Future<void> _fetchLanguages() async {
    try {
      final response = await _dio.get('https://f-learn.app/api/languages');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        List<dynamic> data = response.data['data'];
        final userLangId = GetStorage().read('user')?['languageId'];

        if (mounted) {
          setState(() {
            _languages = data.map((json) => Language.fromJson(json)).toList();
            _selectedLanguageId = userLangId ?? (_languages.isNotEmpty ? _languages.first.id : null);
            _isLoadingLanguages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách ngôn ngữ: $e');
      if (mounted) {
        setState(() {
          _isLoadingLanguages = false;
        });
      }
    }
  }

  Future<void> _handleLanguageChange(String languageId) async {
    final box = GetStorage();
    final token = box.read('accessToken');


    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final assessmentResponse = await _dio.get(
        'https://f-learn.app/api/VoiceAssessment/check-lang-assessment/$languageId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      Get.back();

      final assessmentData = assessmentResponse.data?['data'];
      final hasCompletedAssessment = assessmentData?['hasCompletedAssessment'] ?? false;

      if (!hasCompletedAssessment) {

        Get.dialog(
          AlertDialog(
            title: const Text('Thông báo'),
            content: Text(assessmentData?['message'] ?? 'Trước khi chuyển ngôn ngữ, bạn hãy làm một chút khảo sát nhé.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
              TextButton(
                onPressed: () async {
                  Get.back();


                  Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                  final response = await _dio.post(
                    'https://f-learn.app/api/VoiceAssessment/switch-language/$languageId',
                    options: Options(
                      headers: {'Authorization': 'Bearer $token'},
                      validateStatus: (status) => status != null && status < 500,
                    ),
                  );
                  Get.back();

                  if (response.statusCode == 200 && (response.data['success'] == true)) {
                    final user = box.read('user');
                    if (user != null) {
                      user['languageId'] = languageId;
                      box.write('user', user);
                    } else {
                      box.write('user', {'languageId': languageId});
                    }
                    box.write('selectedLanguageId', languageId);

                    if (mounted) {
                      setState(() {
                        _selectedLanguageId = languageId;
                      });
                    }

                    await _loadInitialData();


                    Get.offAll(() => const SurveyScreen());
                  } else {
                    final message = response.data?['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại.';
                    Get.snackbar('Lỗi', message, snackPosition: SnackPosition.BOTTOM);
                  }
                },
                child: const Text('Đồng ý'),
              ),
            ],
          ),
        );
        return;
      }

      // Đã hoàn thành khảo sát, gọi API switch-language và đổi ngôn ngữ luôn
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final response = await _dio.post(
        'https://f-learn.app/api/VoiceAssessment/switch-language/$languageId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      Get.back();

      if (response.statusCode == 200 && (response.data['success'] == true)) {
        final user = box.read('user');
        if (user != null) {
          user['languageId'] = languageId;
          box.write('user', user);
        } else {
          box.write('user', {'languageId': languageId});
        }
        box.write('selectedLanguageId', languageId);

        if (mounted) {
          setState(() {
            _selectedLanguageId = languageId;
          });
        }

        await _loadInitialData();

        Get.snackbar('Thành công', 'Đã chuyển sang ngôn ngữ mới!', snackPosition: SnackPosition.BOTTOM);
      } else {
        final message = response.data?['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại.';
        Get.snackbar('Lỗi', message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      debugPrint('Lỗi xử lý chuyển ngôn ngữ: $e');
      Get.snackbar('Lỗi nghiêm trọng', 'Không thể kết nối đến máy chủ.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildPromoBanner(),
                const SizedBox(height: 20),
                _buildSectionHeader(title: 'Chủ đề'),
                const SizedBox(height: 12),
                _buildTopicFilter(),
                const SizedBox(height: 20),
                _buildSectionHeader(title: 'Khóa học phổ biến'),
                const SizedBox(height: 12),
                _buildPopularCourses(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final box = GetStorage();
    final user = box.read('user');
    final username = user?['userName'] ?? 'Bạn';
    final avatarUrl = user?['avatar'];

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Xin chào, $username.',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text('Chào mừng quay trở lại!', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(CupertinoIcons.bell, color: AppColors.textPrimary, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        _buildLanguageSelector(),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    if (_isLoadingLanguages) {
      return const SizedBox(width: 60, height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedLanguageId,
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        items: _languages.map((Language lang) {
          return DropdownMenuItem<String>(
            value: lang.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 18,
                  child: CountryIcons.getSvgFlag(
                    lang.langCode == 'EN' ? 'gb' : lang.langCode == 'ZH' ? 'cn' : lang.langCode == 'JP' ? 'jp' : lang.langCode.toLowerCase(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(lang.langCode, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null && newValue != _selectedLanguageId) {
            _handleLanguageChange(newValue);
          }
        },
      ),
    );
  }
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(CupertinoIcons.search, color: Colors.grey),
          border: InputBorder.none,
          hintText: 'Tìm kiếm khóa học...',
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Khám phá các khoá học mới',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/homescreen.png',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text('Xem tất cả', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }


  Widget _buildTopicFilter() {
    return Obx(() {
      if (topicViewModel.isLoadingTopics.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      // Create a new list with an 'All' topic
      final List<TopicModel> topicsWithAll = [
        TopicModel(topicId: 'all', name: 'For you', description: ''),
        ...topicViewModel.topics,
      ];

      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: topicsWithAll.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final topic = topicsWithAll[index];
            final isSelected = (_selectedTopicName == null && topic.topicId == 'all') || (_selectedTopicName == topic.name);

            return ChoiceChip(
              label: Text(topic.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTopicName = topic.topicId == 'all' ? null : topic.name;
                  });
                }
              },
              backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
              ),
              showCheckmark: false,
            );
          },
        ),
      );
    });
  }

  Widget _buildPopularCourses() {
    return Obx(() {
      if (courseViewModel.isLoadingCourse.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      final filteredCourses = courseViewModel.courses.where((course) {
        return _selectedTopicName == null || course.topics == _selectedTopicName;
      }).toList();

      if (filteredCourses.isEmpty) {
        return const Center(child: Text('Không có khoá học nào.'));
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredCourses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final course = filteredCourses[index];
          return CourseCard(course: course);
        },
      );
    });
  }
}

class CourseCard extends StatelessWidget {
  final Course course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Row(
        children: [
          (course.imageUrl != null && course.imageUrl!.isNotEmpty)
              ? Image.network(course.imageUrl!, width: 100, height: 100, fit: BoxFit.cover)
              : Container(width: 100, height: 100, color: Colors.grey.shade200, child: const Icon(Icons.school, color: Colors.grey)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(course.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text('${ 'N/A'} (1k+)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${course.numLessons} buổi', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
