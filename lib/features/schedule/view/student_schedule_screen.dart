import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:get_storage/get_storage.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  bool isLoading = true;
  String errorMessage = '';
  List<dynamic> classes = [];
  DateTime selectedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;

  final Map<String, String> viWeekdays = {
    'Mon': 'Th2', 'Tue': 'Th3', 'Wed': 'Th4', 'Thu': 'Th5', 'Fri': 'Th6', 'Sat': 'Th7', 'Sun': 'CN'
  };
  final Map<int, String> viMonths = {
    1: 'Tháng 1', 2: 'Tháng 2', 3: 'Tháng 3', 4: 'Tháng 4', 5: 'Tháng 5', 6: 'Tháng 6', 7: 'Tháng 7', 8: 'Tháng 8', 9: 'Tháng 9', 10: 'Tháng 10', 11: 'Tháng 11', 12: 'Tháng 12'
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null).then((_) {
      fetchStudentClasses();
    });
  }

  Future<void> fetchStudentClasses() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final token = GetStorage().read('accessToken');
      final response = await http.get(
        Uri.parse('https://f-learn.app/api/student/classes/my-enrollments?page=1&pageSize=10'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      debugPrint('API status: \\${response.statusCode}');
      debugPrint('API body: \\${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            classes = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Lỗi không xác định';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi mạng hoặc máy chủ';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Đã xảy ra lỗi: $e';
        isLoading = false;
      });
    }
  }

  String _formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr);
    // Định dạng ngày tháng tiếng Việt: Thứ Sáu, 23/11/2025 15:00
    final weekdayVN = [
      'Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'
    ];
    final weekday = weekdayVN[dateTime.weekday % 7];
    final formatted = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(dateTime);
    return '$weekday, $formatted';
  }

  List<dynamic> get classesForSelectedDay {
    return classes.where((cls) {
      final start = DateTime.parse(cls['startDateTime']);
      return start.year == selectedDay.year && start.month == selectedDay.month && start.day == selectedDay.day;
    }).toList();
  }

  Future<void> bookClass(String classId) async {
    try {
      // ...existing code gọi API bookClass...
    } catch (e) {
      if (e.toString().contains('Student already enrolled in this class')) {
        Get.snackbar(
          'Thông báo',
          'Bạn đã có lịch học lớp này, kiểm tra lịch học nhé',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.black,
        );
      } else {
        Get.snackbar('Lỗi', e.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Lịch học của tôi',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        children: [
                          // Custom header chỉ hiển thị tháng/năm
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      selectedDay = DateTime(selectedDay.year, selectedDay.month - 1, selectedDay.day);
                                    });
                                  },
                                ),
                                Text(
                                  '${viMonths[selectedDay.month]} ${selectedDay.year}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                                  onPressed: () {
                                    setState(() {
                                      selectedDay = DateTime(selectedDay.year, selectedDay.month + 1, selectedDay.day);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          TableCalendar(
                            locale: 'vi_VN',
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: selectedDay,
                            calendarFormat: calendarFormat,
                            onFormatChanged: (format) {}, // Không cho đổi format
                            selectedDayPredicate: (day) {
                              return isSameDay(selectedDay, day);
                            },
                            onDaySelected: (selected, focused) {
                              setState(() {
                                selectedDay = selected;
                              });
                            },
                            headerVisible: false,
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(77),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              weekendTextStyle: const TextStyle(color: Colors.red),
                              outsideDaysVisible: false,
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                              weekendStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              dowTextFormatter: (day, locale) {
                                return viWeekdays[DateFormat('E', 'en_US').format(day)] ?? '';
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: classesForSelectedDay.isEmpty
                          ? Center(child: Text('Không có lớp học nào trong ngày này', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: classesForSelectedDay.length,
                              itemBuilder: (context, index) {
                                final cls = classesForSelectedDay[index];
                                final colorList = [Colors.orange.shade100, Colors.green.shade100, Colors.purple.shade100, Colors.blue.shade100];
                                final cardColor = colorList[index % colorList.length];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(18), // 0.07*255=18
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withAlpha(40),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(Icons.class_, color: AppColors.primary, size: 22),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                cls['title'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1A1A1A),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.person, color: Colors.grey, size: 18),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Giáo viên: ${cls['teacherName'] ?? ''}', style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.language, color: Colors.grey, size: 18),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Ngôn ngữ: ${cls['languageName'] ?? ''}', style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.access_time, color: Colors.grey, size: 18),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Thời gian: ${_formatDateTime(cls['startDateTime'])} - ${_formatDateTime(cls['endDateTime'])}', style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        if (cls['googleMeetLink'] != null && cls['googleMeetLink'].toString().isNotEmpty)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                              ),
                                              icon: const Icon(Icons.video_call, size: 20),
                                              label: const Text('Vào lớp học', style: TextStyle(fontWeight: FontWeight.bold)),
                                              onPressed: () async {
                                                final url = cls['googleMeetLink'];
                                                if (url != null && url.toString().isNotEmpty) {
                                                  final uri = Uri.parse(url);
                                                  if (await canLaunchUrl(uri)) {
                                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  } else {
                                                    Get.snackbar('Không mở được link', url, snackPosition: SnackPosition.BOTTOM);
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
