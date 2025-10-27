import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for initialization

import '../model/schedule_model.dart';
import '../viewmodel/teacher_schedule_viewmodel.dart';

class TeacherScheduleListScreen extends StatefulWidget {
  const TeacherScheduleListScreen({super.key});

  @override
  State<TeacherScheduleListScreen> createState() =>
      _TeacherScheduleListScreenState();
}

class _TeacherScheduleListScreenState extends State<TeacherScheduleListScreen>
    with WidgetsBindingObserver {
  final TeacherScheduleViewModel viewModel =
      Get.put(TeacherScheduleViewModel(service: Get.find()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FIX: Initialize date formatting for Vietnamese locale before using DateFormat.
    initializeDateFormatting('vi_VN', null);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      viewModel.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Lịch học với giáo viên",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchSchedules,
        child: Obx(() {
          if (viewModel.isLoading.value && viewModel.schedules.isEmpty) {
            return const Center(child: CupertinoActivityIndicator(radius: 15));
          }
          if (viewModel.errorMessage.isNotEmpty && viewModel.schedules.isEmpty) {
            return _buildErrorState();
          }
          if (viewModel.schedules.isEmpty) {
            return _buildEmptyState();
          }
          return _buildScheduleList(viewModel.schedules);
        }),
      ),
    );
  }

  Widget _buildScheduleList(List<TeacherClass> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18.0),
          child: _buildScheduleCard(schedules[index]),
        );
      },
    );
  }

  Widget _buildScheduleCard(TeacherClass schedule) {
    final Color statusColor = schedule.isFull
        ? Colors.red.shade400
        : schedule.isAlmostFull
            ? Colors.orange.shade400
            : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(schedule),
                    const SizedBox(height: 12),
                    Text(
                      schedule.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(CupertinoIcons.time,
                        "${_formatTime(schedule.startDateTime)} - ${_formatTime(schedule.endDateTime)} (${schedule.durationInMinutes} phút)"),
                    const SizedBox(height: 6),
                    _buildInfoRow(CupertinoIcons.calendar,
                        _formatDate(schedule.startDateTime)),
                    const SizedBox(height: 12),
                    _buildCardFooter(schedule),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(TeacherClass schedule) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                schedule.teacherName.isNotEmpty
                    ? schedule.teacherName[0].toUpperCase()
                    : 'G',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              schedule.teacherName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            schedule.languageName,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCardFooter(TeacherClass schedule) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    final price = currencyFormat.format(schedule.pricePerStudent);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              price,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 2),
            Text(
              "/${schedule.durationInMinutes} phút",
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        Obx(() => CupertinoButton(
              onPressed: schedule.isFull || viewModel.isBooking.value
                  ? null
                  : () => _showBookingDialog(schedule),
              color: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              borderRadius: BorderRadius.circular(25),
              child: viewModel.isBooking.value
                  ? const CupertinoActivityIndicator(
                      color: Colors.white, radius: 10)
                  : Text(
                      schedule.isFull ? "Đã đầy" : "Đặt lịch",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.calendar_badge_minus,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Không có lịch học nào',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hiện tại chưa có giáo viên nào mở lớp cho ngôn ngữ này.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.wifi_exclamationmark,
              size: 80, color: Colors.red.shade300),
          const SizedBox(height: 24),
          const Text(
            'Lỗi kết nối',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              viewModel.errorMessage.value,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: viewModel.fetchSchedules,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  void _showBookingDialog(TeacherClass schedule) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    final price = currencyFormat.format(schedule.pricePerStudent);

    Get.dialog(
      CupertinoAlertDialog(
        title: const Text("Xác nhận đặt lịch"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text("Giáo viên: ${schedule.teacherName}",
                style: const TextStyle(height: 1.5)),
            Text(
                "Thời gian: ${_formatTime(schedule.startDateTime)}, ${_formatDate(schedule.startDateTime)}",
                style: const TextStyle(height: 1.5)),
            Text("Thời lượng: ${schedule.durationInMinutes} phút",
                style: const TextStyle(height: 1.5)),
            const SizedBox(height: 8),
            Text("Chi phí: $price",
                style: const TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ],
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: const Text("Hủy"),
            onPressed: () => Get.back(),
            isDefaultAction: true,
          ),
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () {
              Get.back(); // Close the dialog first
              viewModel.bookClass(schedule.classID);
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }
}
