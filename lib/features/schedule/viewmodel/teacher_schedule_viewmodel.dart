import 'package:flutter/material.dart';
import 'package:flearn_app/features/schedule/data/repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../model/schedule_model.dart';
import '../view/schedule_payment_webview_screen.dart';
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

      final box = GetStorage();
      String? languageId = box.read('selectedLanguageId') as String?;

      if (languageId == null || languageId.isEmpty) {
        final user = box.read('user');
        final userLangId = user?['languageId']?.toString();
        if (userLangId != null && userLangId.isNotEmpty) {
          languageId = userLangId;
          box.write('selectedLanguageId', languageId);
          debugPrint('[TeacherScheduleViewModel] Fallback languageId từ user: $languageId');
        } else {
          debugPrint('[TeacherScheduleViewModel] Không tìm thấy languageId trong storage');
          errorMessage.value = 'Không tìm thấy ngôn ngữ. Vui lòng chọn ngôn ngữ.';
          return; // tránh gọi API với null
        }
      }

      final result = await service.getTeacherSchedules(languageId: languageId!); // <- ép non-null
      schedules.value = result;
    } catch (e) {
      errorMessage.value = "Không thể tải lịch học. Vui lòng thử lại.";
      print('fetchSchedules error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _confirmAndRefresh({required String classId}) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final user = GetStorage().read('user') as Map?;
      final studentId = user?['userID']?.toString() ?? user?['id']?.toString() ?? '';
      print('Confirming payment for studentId: $studentId, classId: $classId');
      print('_lastTransactionId: $_lastTransactionId, _lastAmount: $_lastAmount');

      final ok = (_lastTransactionId != null && _lastAmount != null && studentId.isNotEmpty)
          ? await service.confirmPaymentCallback(
        transactionId: _lastTransactionId!,
        amount: _lastAmount!,
        classId: classId,
        studentId: studentId,
      )
          : false;

      await fetchSchedules();
      if (Get.isRegistered<ScheduleViewModel>()) {
        await Get.find<ScheduleViewModel>().fetchMyEnrollments();
      }
      print('Payment confirmation result: $ok');
      Get.back(); // đóng loading
      if (ok) {
        Get.snackbar('Thành công', 'Thanh toán thành công. Lịch học của bạn đã được xác nhận.');
      } else {
        Get.snackbar('Thông báo', 'Không xác nhận được thanh toán. Vui lòng kiểm tra đơn hàng.');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái lịch học.');
    } finally {
      _waitingForPayment = false;
      _lastBookedClassId = null;
      _lastTransactionId = null;
      _lastAmount = null;
    }
  }

  Future<void> bookClass(String classId) async {
    if (isBooking.value) return;
    try {
      isBooking.value = true;
      final response = await service.bookClass(classId);
      final data = (response['data'] as Map?) ?? response;
      String? paymentUrl = data['paymentUrl'] as String?;
      _lastTransactionId = data['transactionId']?.toString();
      _lastAmount = (data['amount'] is int) ? data['amount'] as int : int.tryParse('${data['amount']}');


      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        _lastBookedClassId = classId;
        _waitingForPayment = true;

        final String safePaymentUrl = paymentUrl;
        final paid = await Get.to<bool>(() => PaymentScheduleWebViewScreen(
          paymentUrl: safePaymentUrl,
          transactionId: _lastTransactionId ?? '',
          classId: classId,
          amount: _lastAmount ?? 0,
        ));

        if (paid == true) {
          await _confirmAndRefresh(classId: classId);
        } else {
          _waitingForPayment = false;
          Get.snackbar('Thông báo', 'Bạn đã hủy hoặc thanh toán thất bại.');
        }
      } else {
        Get.snackbar('Thành công', 'Bạn đã đặt lớp thành công!');
        await fetchSchedules();
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Student already enrolled in this class')) {
        Get.snackbar('Thông báo', 'Bạn đã có lịch học lớp này, kiểm tra lịch học nhé',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.black);
      } else {
        Get.snackbar('Lỗi', 'Đặt lịch thất bại. Vui lòng thử lại sau.');
      }
    } finally {
      isBooking.value = false;
    }
  }

  void onAppResumed() {

    if (_waitingForPayment && _lastBookedClassId != null) {
      _confirmAndRefresh(classId: _lastBookedClassId!);
    }
  }




}
