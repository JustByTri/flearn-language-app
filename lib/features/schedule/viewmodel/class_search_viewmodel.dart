import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flearn_app/features/schedule/data/repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/schedule_model.dart';

class ClassSearchViewModel extends GetxController {
  final IScheduleRepository service;

  ClassSearchViewModel({required this.service});

  var isLoading = true.obs;
  var classes = <ClassSearchResult>[].obs;
  var errorMessage = ''.obs;

  var teachers = <Teacher>[].obs;
  var programs = <Program>[].obs;
  var isLoadingFilters = true.obs;

  var isBooking = false.obs;
  String? _lastBookedClassId;
  String? _lastTransactionId;
  int? _lastAmount;
  var _waitingForPayment = false;

  // Filter variables
  var selectedTeacherId = ''.obs;
  var selectedProgramId = ''.obs;
  var searchKeyword = ''.obs;
  var selectedStatus = '2'.obs; // Default to Published

  // Debounce timer for keyword search
  Timer? _debounce;

  // Pagination state
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  final int pageSize = 10; // can adjust later
  var isLoadingMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFilters();
    searchClasses(resetPage: true);
  }

  Future<void> loadFilters() async {
    try {
      isLoadingFilters.value = true;
      await Future.wait([
        loadTeachers(),
        loadPrograms(),
      ]);
    } catch (e) {
      print('loadFilters error: $e');
    } finally {
      isLoadingFilters.value = false;
    }
  }

  Future<void> loadTeachers() async {
    try {
      final result = await service.getAllTeachers();
      teachers.value = result;
    } catch (e) {
      print('loadTeachers error: $e');
    }
  }

  Future<void> loadPrograms() async {
    try {
      final languageId = GetStorage().read('selectedLanguageId') as String? ?? '';
      print('[PROGRAMS] Fetching for languageId: $languageId');
      if (languageId.isNotEmpty) {
        final result = await service.getPrograms(languageId);
        print('[PROGRAMS] result: ${result.length} programs');
        programs.value = result;
      }
    } catch (e) {
      print('[PROGRAMS] error: $e');
    }
  }

  // Helper getters
  String? get activeTeacherName {
    if (selectedTeacherId.value.isEmpty) return null;
    try {
      return teachers.firstWhere((t) => t.teacherId == selectedTeacherId.value).fullName;
    } catch (_) {
      return null;
    }
  }

  String? get activeProgramName {
    if (selectedProgramId.value.isEmpty) return null;
    try {
      return programs.firstWhere((p) => p.programId == selectedProgramId.value).name;
    } catch (_) {
      return null;
    }
  }

  Future<void> searchClasses({bool resetPage = false, bool append = false}) async {
    try {
      if (resetPage) {
        currentPage.value = 1;
        if (!append) classes.clear();
      }
      if (!append) {
        isLoading.value = true; // show loading when not appending
      }
      errorMessage.value = '';
      final languageId = GetStorage().read('selectedLanguageId') as String? ?? '';
      print('[SEARCH] languageId: $languageId, teacherId: ${selectedTeacherId.value}, programId: ${selectedProgramId.value}, keyword: ${searchKeyword.value}, status: ${selectedStatus.value}, page: ${currentPage.value}');
      final result = await service.searchClasses(
        languageId: languageId,
        teacherId: selectedTeacherId.value.isNotEmpty ? selectedTeacherId.value : null,
        programId: selectedProgramId.value.isNotEmpty ? selectedProgramId.value : null,
        keyword: searchKeyword.value.isNotEmpty ? searchKeyword.value : null,
        status: selectedStatus.value,
        page: currentPage.value,
        pageSize: pageSize,
      );
      print('[SEARCH] fetched: ${result.length} classes');
      if (append) {
        classes.addAll(result);
      } else {
        classes.value = result;
      }
      // If result length < pageSize assume last page
      if (result.length < pageSize) {
        totalPages.value = currentPage.value; // stop further loads
      } else {
        totalPages.value = currentPage.value + 1; // optimistic until API meta implemented
      }
    } catch (e) {
      errorMessage.value = "Không thể tải danh sách lớp học. Vui lòng thử lại.";
      print('[SEARCH] error: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void updateFilters({String? teacherId, String? programId, String? keyword}) {
    bool shouldSearch = false;
    if (teacherId != null && teacherId != selectedTeacherId.value) {
      selectedTeacherId.value = teacherId;
      shouldSearch = true;
    }
    if (programId != null && programId != selectedProgramId.value) {
      selectedProgramId.value = programId;
      shouldSearch = true;
    }
    if (keyword != null) {
      searchKeyword.value = keyword;
      _debounceKeyword();
    } else if (shouldSearch) {
      searchClasses(resetPage: true);
    }
  }

  void _debounceKeyword() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      searchClasses(resetPage: true);
    });
  }

  void clearFilters() {
    selectedTeacherId.value = '';
    selectedProgramId.value = '';
    searchKeyword.value = '';
    selectedStatus.value = '2';
    searchClasses(resetPage: true);
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value) return;
    if (currentPage.value >= totalPages.value) return; // no more pages
    isLoadingMore.value = true;
    currentPage.value += 1;
    await searchClasses(resetPage: false, append: true);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
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
        await searchClasses();
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

          await searchClasses();

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
