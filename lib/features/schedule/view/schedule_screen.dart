import 'package:flearn_app/features/schedule/view/student_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import 'package:flearn_app/features/schedule/model/schedule_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodel/teacher_schedule_viewmodel.dart';

class TeacherScheduleListScreen extends StatefulWidget {
  const TeacherScheduleListScreen({super.key});

  @override
  State<TeacherScheduleListScreen> createState() => _TeacherScheduleListScreenState();
}

class _TeacherScheduleListScreenState extends State<TeacherScheduleListScreen> with WidgetsBindingObserver {
  late final TeacherScheduleViewModel viewModel;

  String? _lastBookedClassId;
  bool _waitingPayment = false;

  @override
  void initState() {
    super.initState();
    viewModel = Get.put(TeacherScheduleViewModel(service: Get.find()));
    _fetchSchedules();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _waitingPayment && _lastBookedClassId != null) {

      _waitingPayment = false;
      _lastBookedClassId = null;
    }
  }

  void _fetchSchedules() {
    final languageId = GetStorage().read('selectedLanguageId') as String?;
    viewModel.fetchSchedules(languageId: languageId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text("Lịch thầy cô dạy học", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        if (viewModel.isLoading.value) {
          print('[ScheduleScreen] Loading schedules...');
          return const Center(child: CircularProgressIndicator());
        }
        if (viewModel.errorMessage.isNotEmpty) {
          print('[ScheduleScreen] Error: ${viewModel.errorMessage.value}');
          return Center(child: Text(viewModel.errorMessage.value, style: const TextStyle(color: Colors.red)));
        }
        final schedules = viewModel.schedules;
        if (schedules.isEmpty) {
          print('[ScheduleScreen] No schedules found.');
          return _buildEmptyState();
        }
        print('[ScheduleScreen] Loaded ${schedules.length} schedules.');
        return _buildScheduleList(schedules);
      }),
    );
  }

  Widget _buildScheduleList(List<TeacherClass> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildScheduleCard(schedules[index]),
        );
      },
    );
  }

  Widget _buildScheduleCard(TeacherClass schedule) {
    final isAlmostFull = schedule.currentEnrollments >= schedule.capacity * 0.8;
    final availableSpots = schedule.availableSlots;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAlmostFull
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      schedule.teacherName.isNotEmpty ? schedule.teacherName[0] : "?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.teacherName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            schedule.languageName,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${schedule.pricePerStudent ~/ 1000}K VNĐ",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${_getDuration(schedule)} phút",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(schedule.startDateTime),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(schedule.startDateTime),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                schedule.description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        "${schedule.currentEnrollments}/${schedule.capacity} học viên",
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (isAlmostFull) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Sắp đầy!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  ElevatedButton(
                    onPressed: availableSpots > 0
                        ? () {
                      _showBookingDialog(schedule);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      availableSpots > 0 ? "Đặt lịch" : "Đã đầy",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  int _getDuration(TeacherClass schedule) {
    return schedule.endDateTime.difference(schedule.startDateTime).inMinutes;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "Không có lịch dạy nào",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Thử chọn ngôn ngữ khác",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(TeacherClass schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Đặt lịch học với ${schedule.teacherName}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ngôn ngữ: ${schedule.languageName}"),
              Text("Thời gian: ${_formatDate(schedule.startDateTime)} ${_formatTime(schedule.startDateTime)}"),
              Text("Thời lượng: ${_getDuration(schedule)} phút"),
              Text("Giá: ${schedule.pricePerStudent ~/ 1000}K VNĐ"),
              const SizedBox(height: 16),
              const Text(
                "Bạn có chắc chắn muốn đặt lịch này?",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _bookSchedule(schedule);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookSchedule(TeacherClass schedule) async {
    try {
      final result = await viewModel.enrollClass(schedule.classID);
      final paymentUrl = result['data']?['paymentUrl'];
      if (paymentUrl != null && paymentUrl is String) {
        _waitingPayment = true;
        _lastBookedClassId = schedule.classID;
        await _openPaymentUrl(paymentUrl);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã đặt lịch với ${schedule.teacherName} thành công!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đặt lịch thất bại: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được link thanh toán. Vui lòng kiểm tra trình duyệt mặc định trên thiết bị!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được link thanh toán. Vui lòng kiểm tra trình duyệt mặc định trên thiết bị!')),
      );
    }
  }
}