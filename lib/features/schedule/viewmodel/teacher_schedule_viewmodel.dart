import 'package:flutter/material.dart';
import 'package:flearn_app/features/schedule/data/repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/schedule_model.dart';
import 'schedule_viewmodel.dart';

class TeacherScheduleViewModel extends GetxController {
  final IScheduleRepository service;

  TeacherScheduleViewModel({required this.service});

  var isLoading = true.obs;
  var schedules = <TeacherClass>[].obs;
  var errorMessage = ''.obs;

  var isBooking = false.obs;
  String? _lastBookedClassId;
  String? _lastTransactionId;
  int? _lastAmount;
  var _waitingForPayment = false;

  @override
  void onInit() {
    super.onInit();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final languageId = GetStorage().read('selectedLanguageId') as String?;
      final result = await service.getTeacherSchedules(languageId: languageId);
      schedules.value = result;
    } catch (e) {
      errorMessage.value = "Không thể tải lịch học. Vui lòng thử lại.";
      print('fetchSchedules error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> bookClass(String classId) async {
    if (isBooking.value) return;

    try {
      isBooking.value = true;
      final response = await service.bookClass(classId);
      final data = (response['data'] as Map?) ?? response;
      final paymentUrl = data['paymentUrl'] as String?;
      _lastTransactionId = data['transactionId']?.toString();
      _lastAmount = (data['amount'] is int) ? data['amount'] as int : int.tryParse('${data['amount']}');

      print('Payment URL: $paymentUrl');

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          _lastBookedClassId = classId;
          _waitingForPayment = true;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar('Lỗi', 'Không thể mở trang thanh toán. Vui lòng thử lại.');
        }
      } else {
        Get.snackbar('Thành công', 'Bạn đã đặt lớp thành công!');
        await fetchSchedules();
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Student already enrolled in this class')) {
        Get.snackbar(
          'Thông báo',
          'Bạn đã có lịch học lớp này, kiểm tra lịch học nhé',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.black,
        );
      } else {
        Get.snackbar('Lỗi', 'Đặt lịch thất bại. Vui lòng thử lại sau.');
      }
      print('bookClass error: $e');
    } finally {
      isBooking.value = false;
    }
  }

  void onAppResumed() {
    if (_waitingForPayment && _lastBookedClassId != null) {
      _waitingForPayment = false;

      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      Future.delayed(const Duration(seconds: 1), () async {
        try {
          final user = GetStorage().read('user') as Map?;
          final studentId = user?['userID']?.toString() ?? user?['id']?.toString() ?? '';

          final ok = (_lastTransactionId != null && _lastAmount != null && studentId.isNotEmpty)
              ? await service.confirmPaymentCallback(
            transactionId: _lastTransactionId!,
            amount: _lastAmount!,
            classId: _lastBookedClassId!,
            studentId: studentId,
          )
              : false;

          await fetchSchedules();

          if (Get.isRegistered<ScheduleViewModel>()) {
            await Get.find<ScheduleViewModel>().fetchMyEnrollments();
          }

          Get.back();
          if (ok) {
            Get.snackbar('Thành công', 'Thanh toán thành công. Lịch học của bạn đã được xác nhận.');
          } else {
            Get.snackbar('Thông báo', 'Không xác nhận được thanh toán. Vui lòng kiểm tra đơn hàng.');
          }
        } catch (e) {
          Get.back();
          Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái lịch học.');
        } finally {
          _lastBookedClassId = null;
          _lastTransactionId = null;
          _lastAmount = null;
        }
      });
    }
  }
}
