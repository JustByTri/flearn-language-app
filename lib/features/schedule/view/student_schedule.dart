import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:flearn_app/features/schedule/model/enrollment_model.dart';
import 'package:flearn_app/features/schedule/viewmodel/schedule_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentScheduleTimelineScreen extends StatefulWidget {
  const StudentScheduleTimelineScreen({super.key});

  @override
  State<StudentScheduleTimelineScreen> createState() => _StudentScheduleTimelineScreenState();
}

class _StudentScheduleTimelineScreenState extends State<StudentScheduleTimelineScreen> {
  late final ScheduleViewModel _viewModel;

  static const _cardColors = [
    Color(0xFF50C2C9),
    Color(0xFFF6A623),
    Color(0xFF7B61FF),
    Color(0xFFFF5B8F),
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = Get.isRegistered<ScheduleViewModel>()
        ? Get.find<ScheduleViewModel>()
        : Get.put(ScheduleViewModel(service: Get.find()), permanent: true);
    _viewModel.fetchMyEnrollments();
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
          'Lịch học của bạn',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        if (_viewModel.isLoading.value && _viewModel.myEnrollments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (_viewModel.errorMessage.value.isNotEmpty) {
          return Center(child: Text(_viewModel.errorMessage.value));
        }
        return RefreshIndicator(
          onRefresh: () => _viewModel.fetchMyEnrollments(),
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _buildGroupedTimeline(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGroupedTimeline() {
    final enrollments = _viewModel.myEnrollments;
    if (enrollments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Bạn chưa đăng ký lớp học nào.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final grouped = <DateTime, List<Enrollment>>{};
    for (final enrollment in enrollments) {
      final date = DateTime(
        enrollment.startDateTime.year,
        enrollment.startDateTime.month,
        enrollment.startDateTime.day,
      );
      grouped.putIfAbsent(date, () => <Enrollment>[]).add(enrollment);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final date in sortedDates) ...[
          _buildDaySection(date, grouped[date]!),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDaySection(DateTime date, List<Enrollment> enrollments) {
    final label = DateFormat('EEEE, dd MMMM yyyy', 'vi_VN').format(date);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final items = List<Enrollment>.from(enrollments)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Hôm nay',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _timelineTile(
                items[i],
                index: i,
                isLast: i == items.length - 1,
              ),
              if (i != items.length - 1) const SizedBox(height: 20),
            ],
          ],
        ),
      ],
    );
  }

  // Widget _timelineTile(
  //     Enrollment enrollment, {
  //       required int index,
  //       required bool isLast,
  //     }) {
  //   final start = DateFormat('HH:mm').format(enrollment.startDateTime);
  //   final end = DateFormat('HH:mm').format(enrollment.endDateTime);
  //   final now = DateTime.now();
  //
  //   late final String statusLabel;
  //   late final Color statusColor;
  //   if (enrollment.endDateTime.isBefore(now)) {
  //     statusLabel = 'Đã diễn ra';
  //     statusColor = Colors.grey.shade600;
  //   } else if (enrollment.startDateTime.isAfter(now)) {
  //     statusLabel = 'Sắp diễn ra';
  //     statusColor = AppColors.primary;
  //   } else {
  //     statusLabel = 'Đang diễn ra';
  //     statusColor = Colors.green.shade600;
  //   }
  //
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey.shade200),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.03),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(Icons.school, color: AppColors.primary, size: 20),
  //               ),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   enrollment.title ?? 'Lớp học dành cho người mới',
  //                   style: const TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                     color: Color(0xFF1A1A1A),
  //                   ),
  //                 ),
  //               ),
  //               _statusBadge(statusLabel, statusColor),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           Row(
  //             children: [
  //               Icon(Icons.person, size: 16, color: Colors.grey.shade600),
  //               const SizedBox(width: 4),
  //               Text(
  //                 'Giáo viên: ${enrollment.teacherName ?? "Unknown Teacher"}',
  //                 style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 4),
  //           Row(
  //             children: [
  //               Icon(Icons.language, size: 16, color: Colors.grey.shade600),
  //               const SizedBox(width: 4),
  //               Text(
  //                 'Ngôn ngữ: ${enrollment.languageName ?? "English"}',
  //                 style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 4),
  //           Row(
  //             children: [
  //               Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
  //               const SizedBox(width: 4),
  //               Expanded(
  //                 child: Text(
  //                   'Thời gian: ${DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(enrollment.startDateTime)} $start - $end',
  //                   style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           ElevatedButton.icon(
  //             onPressed: () async => _openMeeting(enrollment),
  //             icon: const Icon(Icons.video_call, size: 18, color: Colors.white),
  //             label: const Text(
  //               'Vào lớp học',
  //               style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
  //             ),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.primary,
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //               minimumSize: const Size(double.infinity, 0),
  //               elevation: 0,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _timelineTile(
      Enrollment enrollment, {
        required int index,
        required bool isLast,
      }) {
    final start = DateFormat('HH:mm').format(enrollment.startDateTime);
    final end = DateFormat('HH:mm').format(enrollment.endDateTime);
    final now = DateTime.now();

    late final String statusLabel;
    late final Color statusColor;
    if (enrollment.endDateTime.isBefore(now)) {
      statusLabel = 'Đã diễn ra';
      statusColor = Colors.grey.shade600;
    } else if (enrollment.startDateTime.isAfter(now)) {
      statusLabel = 'Sắp diễn ra';
      statusColor = AppColors.primary;
    } else {
      statusLabel = 'Đang diễn ra';
      statusColor = Colors.green.shade600;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần hiển thị giờ bên trái
          SizedBox(
            width: 70,
            child: Column(
              children: [
                Text(
                  start,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  width: 2,
                  height: 8,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Text(
                  end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card nội dung
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            enrollment.title ?? 'Lớp học dành cho người mới',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        _statusBadge(statusLabel, statusColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Giáo viên: ${enrollment.teacherName ?? "Unknown Teacher"}',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.language, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Ngôn ngữ: ${enrollment.languageName ?? "English"}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async => _openMeeting(enrollment),
                      icon: const Icon(Icons.video_call, size: 18, color: Colors.white),
                      label: const Text(
                        'Vào lớp học',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        minimumSize: const Size(double.infinity, 0),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _openMeeting(Enrollment enrollment) async {
    final url = (enrollment.googleMeetLink ?? '').trim();
    if (url.isEmpty) {
      Get.snackbar('Không tìm thấy link', 'Lớp học chưa có link tham gia.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Get.snackbar('Không mở được link', url, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar('Không mở được link', url, snackPosition: SnackPosition.BOTTOM);
    }
  }
}