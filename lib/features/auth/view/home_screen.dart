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
import '../../course/view/course_screen.dart';
import '../../course/view/browse_course_screen.dart';
import '../../course/view/course_detail_screen.dart';
import '../../course/view/course_unit_screen.dart';
import '../../course/viewmodel/course_viewmodel.dart';
import '../../schedule/viewmodel/teacher_schedule_viewmodel.dart';
import '../../survey/view/survey_screen.dart';
import '../../survey/viewmodel/survey_viewmodel.dart';
import '../../course_progress/viewmodel/course_progress_viewmodel.dart';
import '../../course_progress/model/course_progress.dart';
import '../../notification/view/notification_screen.dart';
import '../viewmodel/user_viewmodel.dart';

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

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {

  List<Language> _languages = [];
  // Xóa hoặc giữ nhưng không dùng để chặn gọi API nữa
  // Set<String> _switchedLanguages = {};
  String? _selectedLanguageId;
  bool _isLoadingLanguages = true;
  String? _selectedTopicName;
  bool _hasLoadedOnce = false;
  bool _isVisible = true;


  // NEW: trạng thái chống spam
  bool _isSwitchingLanguage = false;
  CancelToken? _languageSwitchCancelToken;
  bool _isLoadingScreenOpen = false;

  late CourseViewModel courseViewModel;
  late TeacherScheduleViewModel teacherScheduleViewModel;
  late SurveyViewModel surveyViewModel;
  late LoginViewModel loginViewModel;
  late TopicViewModel topicViewModel;
  late CourseProgressViewModel courseProgressViewModel;
  late UserViewModel userViewModel;
  final Dio _dio = Dio();

  String _searchQuery = '';
  String? _sortBy;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeViewModels();
    _loadInitialData();

    courseProgressViewModel = Get.put(CourseProgressViewModel(Get.find()));
    courseProgressViewModel.fetchMyCourses();
    // Bỏ auto add vào set (không cần nữa)
    // if (_selectedLanguageId != null) {
    //   _switchedLanguages.add(_selectedLanguageId!);
    // }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      debugPrint('HomeScreen: App resumed, reloading data');
      _fetchOtherData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if this route is now visible
    final route = ModalRoute.of(context);
    final isCurrentRoute = route?.isCurrent ?? false;


    if (_hasLoadedOnce && isCurrentRoute && !_isVisible) {
      debugPrint('HomeScreen: Became visible again, reloading data');
      _isVisible = true;
      Future.microtask(() => _fetchOtherData());
    } else if (!isCurrentRoute) {
      _isVisible = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  String _getLanguageFlag(String langCode) {
    final flags = {
      'en': '🇬🇧',
      'ja': '🇯🇵',
      'zh': '🇨🇳',
      'ko': '🇰🇷',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'es': '🇪🇸',
      'vi': '🇻🇳',
    };
    return flags[langCode.toLowerCase()] ?? '🌐';
  }

  void _initializeViewModels() {
    courseViewModel = Get.put(CourseViewModel(Get.find()));
    teacherScheduleViewModel = Get.put(TeacherScheduleViewModel(service: Get.find()));
    surveyViewModel = Get.put(SurveyViewModel(Get.find()));
    topicViewModel = Get.put(TopicViewModel(Get.find()));
    loginViewModel = Get.find<LoginViewModel>();
    userViewModel = Get.put(UserViewModel(Get.find()));
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchLanguages(),
      _fetchOtherData(),
    ]);
    _hasLoadedOnce = true;
  }

  Future<Set<String>> _getEnrolledCourseIds(List<Course> courses) async {
    final vm = Get.find<CourseViewModel>();
    final results = await Future.wait(
      courses.map((c) async {
        await vm.fetchCourseAccess(c.courseID);
        final access = vm.courseAccess.value;
        return access != null && access.hasAccess ? c.courseID : null;
      }),
    );
    return results.whereType<String>().toSet();
  }

  Future<void> _fetchOtherData() async {
    try {
      debugPrint('HomeScreen: _fetchOtherData called');

      // Get user's active language
      final box = GetStorage();
      final user = box.read('user');
      String? langCode;

      if (user != null && user['languageId'] != null) {

        final language = _languages.firstWhere(
              (lang) => lang.id == user['languageId'],
          orElse: () => Language(id: '', langName: '', langCode: ''),
        );
        langCode = language.langCode.isNotEmpty ? language.langCode : null;
      }

      debugPrint('HomeScreen: Fetching courses with langCode: $langCode');


      await courseViewModel.fetchCoursesWithLanguage(
        lang: langCode,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: _sortBy,
        isRefresh: true,
      );

      debugPrint('HomeScreen: Fetched ${courseViewModel.courses.length} courses');


      if (topicViewModel.topics.isEmpty) {
        await topicViewModel.fetchTopics();
      }
      if (teacherScheduleViewModel.schedules.isEmpty) {
        await teacherScheduleViewModel.fetchSchedules();
      }
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
    if (_isSwitchingLanguage) return;
    if (languageId == _selectedLanguageId) {
      Get.dialog(
        AlertDialog(
          title: const Text('Thông báo'),
          content: const Text('Bạn đang ở ngôn ngữ này rồi.'),
          actions: [TextButton(onPressed: () => Get.back(), child: const Text('OK'))],
        ),
      );
      return;
    }

    final box = GetStorage();
    final token = box.read('accessToken');

    _isSwitchingLanguage = true;
    _languageSwitchCancelToken?.cancel('Cancelled previous switch');
    _languageSwitchCancelToken = CancelToken();

    try {
      final response = await _dio.post(
        'https://f-learn.app/api/VoiceAssessment/switch-language/$languageId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: _languageSwitchCancelToken,
      );

      final respData = response.data;
      final action = respData?['action'];
      final message = respData?['message'] ?? 'Có lỗi xảy ra, vui lòng thử lại.';

      if (action == "REQUIRE_ASSESSMENT") {
        await Get.dialog(
          AlertDialog(
            title: const Text('Đánh giá'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
              TextButton(
                onPressed: () {
                  Get.back();
                  box.write('selectedLanguageId', languageId);
                  Get.offAll(
                        () => const SurveyScreen(),
                    binding: BindingsBuilder(() {
                      if (!Get.isRegistered<SurveyViewModel>()) {
                        Get.put(SurveyViewModel(Get.find()));
                      }
                    }),
                    arguments: {'languageId': languageId},
                  );
                },
                child: const Text('Bắt đầu'),
              ),
            ],
          ),
        );
      } else if (action == "PROCEED_TO_HOME") {
        // Hiển thị loading overlay (dialog không đóng thủ công được)
        if (!_isLoadingScreenOpen) {
          _isLoadingScreenOpen = true;
          Get.dialog(
            const LanguageSwitchLoadingScreen(),
            barrierDismissible: false,
          );
        }

        final user = box.read('user') ?? {};
        user['languageId'] = languageId;
        box.write('user', user);
        box.write('selectedLanguageId', languageId);

        if (mounted) {
          setState(() {
            _selectedLanguageId = languageId;
          });
        }

        // Tải lại dữ liệu
        await _fetchOtherData();
        await courseProgressViewModel.fetchMyCourses();

        // Đóng loading sau khi hoàn tất
        if (_isLoadingScreenOpen) {
          Get.back(); // đóng LanguageSwitchLoadingScreen
          _isLoadingScreenOpen = false;
        }

        Get.snackbar('Thành công', message, snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Thông báo', message, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e, st) {
      if (_isLoadingScreenOpen) {
        Get.back();
        _isLoadingScreenOpen = false;
      }
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('Switch language bị hủy: ${e.message}');
      } else {
        debugPrint('Lỗi xử lý chuyển ngôn ngữ: $e\n$st');
        Get.snackbar('Lỗi', 'Không thể kết nối đến máy chủ.', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      _isSwitchingLanguage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                _buildOngoingCourses(),
                const SizedBox(height: 20),
                _buildSectionHeader(title: 'Khóa học phổ biến'),
                const SizedBox(height: 12),
                _buildPopularCoursesHorizontal(),
                const SizedBox(height: 20),
                _buildSectionHeader(title: 'Chủ đề'),
                const SizedBox(height: 12),
                _buildTopicFilter(),
                const SizedBox(height: 20),
                _buildSectionHeader(title: 'Khám phá'),
                const SizedBox(height: 12),
                _buildDiscoverCoursesVertical(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final user = userViewModel.user.value;
      final username = user?.fullname ?? user?.username ?? 'Bạn';
      final avatarUrl = user?.avatar;

      return Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withAlpha(25),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: AppColors.primary, size: 24)
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            onPressed: () {
              Get.to(
                    () => const NotificationScreen(),
                transition: Transition.cupertino,
              );
            },
          ),
          const SizedBox(width: 4),
          _buildLanguageSelector(),
        ],
      );
    });
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onSubmitted: (value) async {
                if (value.isNotEmpty) {
                  // Navigate to BrowseCourseScreen with search query
                  await Get.to(
                        () => BrowseCourseScreen(
                      searchQuery: value,
                      topic: _selectedTopicName,
                      sortBy: _sortBy,
                    ),
                    transition: Transition.cupertino,
                  );

                  // Reload data after returning from browse screen
                  debugPrint('HomeScreen: Returned from BrowseCourseScreen, reloading');
                  await _fetchOtherData();

                  // Clear search after navigation
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                }
              },
              decoration: const InputDecoration(
                icon: Icon(CupertinoIcons.search, color: Colors.grey),
                border: InputBorder.none,
                hintText: 'Tìm kiếm khóa học...',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(255),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              _showFilterBottomSheet();
            },
            icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    String? tempSelectedTopic = _selectedTopicName;
    String? tempSortBy = _sortBy;
    String? tempSelectedProgram;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lọc khóa học',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chọn chương trình',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchPrograms(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CupertinoActivityIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Không có chương trình nào');
                            }

                            final programs = [
                              {'programId': null, 'programName': 'Tất cả chương trình'},
                              ...snapshot.data!
                            ];

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: programs.map((program) {
                                final isSelected = (tempSelectedProgram == null && program['programId'] == null) ||
                                    (tempSelectedProgram == program['programId']);

                                return FilterChip(
                                  label: Text(program['programName']),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() {
                                        tempSelectedProgram = program['programId'];
                                      });
                                    }
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                  selectedColor: AppColors.primary.withAlpha(51),
                                  checkmarkColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? AppColors.primary : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chọn chủ đề',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (topicViewModel.isLoadingTopics.value) {
                            return const Center(child: CupertinoActivityIndicator());
                          }

                          final List<TopicModel> topicsWithAll = [
                            TopicModel(
                              topicId: 'all',
                              topicName: 'Tất cả',
                              topicDescription: '',
                              imageUrl: '',
                            ),
                            ...topicViewModel.topics,
                          ];

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: topicsWithAll.map((topic) {
                              final isSelected = (tempSelectedTopic == null && topic.topicId == 'all') ||
                                  (tempSelectedTopic == topic.topicName);

                              return FilterChip(
                                label: Text(topic.topicName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      tempSelectedTopic = topic.topicId == 'all' ? null : topic.topicName;
                                    });
                                  }
                                },
                                backgroundColor: Colors.grey.shade100,
                                selectedColor: AppColors.primary.withAlpha(51),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          );
                        }),
                        const SizedBox(height: 20),
                        const Text(
                          'Sắp xếp theo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: tempSortBy,
                          onChanged: (newValue) {
                            setModalState(() {
                              tempSortBy = newValue;
                            });
                          },
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Mặc định'),
                            ),
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Mới nhất'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Cũ nhất'),
                            ),
                            DropdownMenuItem(
                              value: 'price_asc',
                              child: Text('Giá: Thấp đến Cao'),
                            ),
                            DropdownMenuItem(
                              value: 'price_desc',
                              child: Text('Giá: Cao đến Thấp'),
                            ),
                            DropdownMenuItem(
                              value: 'rating_desc',
                              child: Text('Đánh giá: Cao nhất'),
                            ),
                            DropdownMenuItem(
                              value: 'rating_asc',
                              child: Text('Đánh giá: Thấp nhất'),
                            ),
                            DropdownMenuItem(
                              value: 'learners_desc',
                              child: Text('Học viên: Nhiều nhất'),
                            ),
                          ],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Navigate to BrowseCourseScreen with filters
                              await Get.to(
                                    () => BrowseCourseScreen(
                                  topic: tempSelectedTopic,
                                  sortBy: tempSortBy,
                                  programId: tempSelectedProgram,
                                ),
                                transition: Transition.cupertino,
                              );

                              // Reload data after returning from browse screen
                              debugPrint('HomeScreen: Returned from filter browse, reloading');
                              await _fetchOtherData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelectedTopic = null;
                                tempSortBy = null;
                                tempSelectedProgram = null;
                              });
                            },
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPrograms() async {
    try {

      final box = GetStorage();
      final user = box.read('user');
      String langCode = 'en'; // default

      if (user != null && user['languageId'] != null) {
        final language = _languages.firstWhere(
              (lang) => lang.id == user['languageId'],
          orElse: () => Language(id: '', langName: '', langCode: 'en'),
        );
        langCode = language.langCode;
      }

      final response = await _dio.get('https://f-learn.app/api/languages/$langCode/programs?Page=1&PageSize=100&SortBy=newest');

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        List<dynamic> data = response.data['data'];
        return data.map((program) => {
          'programId': program['programId'],
          'programName': program['programName'],
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách chương trình: $e');
      return [];
    }
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.blue.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khám phá các khóa học mới!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/Home.png',
            height: 140,
            width: 120,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title}) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTopicFilter() {
    return Obx(() {
      if (topicViewModel.isLoadingTopics.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final List<TopicModel> topicsWithAll = [
        TopicModel(
          topicId: 'all',
          topicName: 'Tất cả',
          topicDescription: '',
          imageUrl: '',
        ),
        ...topicViewModel.topics,
      ];

      return SizedBox(
        height: 45,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: topicsWithAll.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final topic = topicsWithAll[index];
            final isSelected = (_selectedTopicName == null && topic.topicId == 'all') ||
                (_selectedTopicName == topic.topicName);

            return ChoiceChip(
              label: Text(topic.topicName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTopicName = topic.topicId == 'all' ? null : topic.topicName;
                  });
                }
              },
              backgroundColor: isSelected ? AppColors.primary : Colors.white,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            );
          },
        ),
      );
    });
  }
  Widget _buildLanguageSelector() {
    if (_isLoadingLanguages) {
      return const CupertinoActivityIndicator();
    }

    if (_languages.isEmpty || _selectedLanguageId == null) {
      return const SizedBox.shrink();
    }

    final selectedLanguage = _languages.firstWhere(
          (lang) => lang.id == _selectedLanguageId,
      orElse: () => _languages.first,
    );

    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _getLanguageFlag(selectedLanguage.langCode),
          style: const TextStyle(fontSize: 24),
        ),
      ),
      onSelected: _handleLanguageChange,
      itemBuilder: (context) {
        return _languages.map((lang) {
          return PopupMenuItem<String>(
            value: lang.id,
            child: Row(
              children: [
                Text(
                  _getLanguageFlag(lang.langCode),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(lang.langName)),
                if (lang.id == _selectedLanguageId)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, color: AppColors.primary, size: 20),
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildOngoingCourses() {
    return Obx(() {
      if (courseProgressViewModel.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      final myCourses = courseProgressViewModel.courses;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: 'Tiếp tục học'),
          const SizedBox(height: 12),
          if (myCourses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Bạn chưa đăng ký khóa học nào cho ngôn ngữ này.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: myCourses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final course = myCourses[index];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: _OngoingCourseCard(course: course),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
  Widget _buildPopularCoursesHorizontal() {
    return FutureBuilder<Set<String>>(
      future: _getEnrolledCourseIds(courseViewModel.courses.toList()),
      builder: (context, snapshot) {
        if (courseViewModel.isLoadingCourse.value || snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final enrolledIds = snapshot.data ?? {};
        final popularCourses = courseViewModel.courses
            .where((c) => !enrolledIds.contains(c.courseID))
            .take(5)
            .toList();

        if (popularCourses.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text('Không có khóa học phổ biến chưa đăng ký'),
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularCourses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.65,
                child: PopularCourseCard(course: course),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoverCoursesVertical() {
    return FutureBuilder<Set<String>>(
      future: _getEnrolledCourseIds(courseViewModel.courses.toList()),
      builder: (context, snapshot) {
        if (courseViewModel.isLoadingCourse.value || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final enrolledIds = snapshot.data ?? {};
        var discoverCourses = courseViewModel.courses
            .where((c) => !enrolledIds.contains(c.courseID))
            .toList()
            .obs;

        // Filter by selected topic if any
        if (_selectedTopicName != null) {
          discoverCourses = discoverCourses.where((course) {
            return course.topics.any((topic) => topic.topicName == _selectedTopicName);
          }).toList().obs;
        }

        if (discoverCourses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text('Không có khóa học khám phá chưa đăng ký'),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: discoverCourses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final course = discoverCourses[index];
                return DiscoverCourseCard(course: course);
              },
            ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}

// Helper function to format VND
String formatVND(int price) {
  if (price == 0) return 'Miễn phí';
  return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫';
}

// Popular Course Card - Horizontal
class PopularCourseCard extends StatelessWidget {
  final Course course;

  const PopularCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => CourseDetailScreen(
          courseId: course.courseID,
        ));
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                (course.imageUrl.isNotEmpty)
                    ? Image.network(
                  course.imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.school, color: Colors.grey, size: 40),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: course.courseType == 'Free' ? Colors.green.shade400 : Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatVND(course.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${course.averageRating}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.person_outline, color: Colors.grey.shade600, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${course.learnerCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// Discover Course Card - Vertical
class DiscoverCourseCard extends StatelessWidget {
  final Course course;

  const DiscoverCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => CourseDetailScreen(
          courseId: course.courseID,
        ));
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                (course.imageUrl.isNotEmpty)
                    ? Image.network(
                  course.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.school, color: Colors.grey, size: 60),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: course.courseType == 'Free' ? Colors.green.shade400 : Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formatVND(course.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.program?.name ?? 'Chương trình',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.averageRating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.learnerCount} học viên',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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

// Keep old BrowseCourseCard for backward compatibility
class BrowseCourseCard extends StatelessWidget {
  final Course course;

  const BrowseCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => CourseDetailScreen(
          courseId: course.courseID,
        ));
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                (course.imageUrl.isNotEmpty)
                    ? Image.network(
                  course.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.school, color: Colors.grey, size: 60),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: course.courseType == 'Free' ? Colors.green.shade400 : Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.courseType == 'Free' ? 'Miễn phí' : '\$${course.price}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.program?.name ?? 'Chương trình',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.averageRating}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.person_outline, color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${course.learnerCount} học viên',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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


class _OngoingCourseCard extends StatelessWidget {
  final CourseProgress course;

  const _OngoingCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.to(() => CourseUnitScreen(
          courseId: course.courseId,
          courseTitle: course.courseTitle,
          enrollmentId: course.enrollmentId,
        ));
      },
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            (course.courseImage.isNotEmpty)
                ? Image.network(
              course.courseImage,
              width: 90,
              height: 130, // Tăng chiều cao từ 110 lên 130
              fit: BoxFit.cover,
            )
                : Container(
              width: 90,
              height: 130, // Tăng chiều cao từ 110 lên 130
              color: Colors.grey.shade200,
              child: const Icon(Icons.school, color: Colors.grey),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.courseTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Giáo viên: ${course.teacherName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: course.progressPercent / 100,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${course.progressPercent}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Bài: ${course.currentLesson}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageSwitchLoadingScreen extends StatelessWidget {
  const LanguageSwitchLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đang tải nội dung theo ngôn ngữ mới...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vui lòng chờ trong giây lát',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}