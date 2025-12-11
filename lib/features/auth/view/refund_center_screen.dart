import 'dart:convert';
import 'dart:io';
import 'package:flearn_app/features/auth/view/refund_course_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../schedule/viewmodel/schedule_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';
import 'course_purchase_detail_screen.dart';

class RefundCenterScreen extends StatefulWidget {
  const RefundCenterScreen({super.key});

  @override
  State<RefundCenterScreen> createState() => _RefundCenterScreenState();
}

class _RefundCenterScreenState extends State<RefundCenterScreen> {
  int _tab = 0; // 0 = gửi đơn, 1 = xem đơn

  // NEW: Thay _viewTab bằng _selectedViewRefundType để đồng nhất với submit tab
  int _selectedViewRefundType = 0;

  late final ScheduleViewModel _scheduleVM;
  late final UserViewModel _userVM;

  // Form controllers
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderNameController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedEnrollmentID;
  String? _selectedClassID;
  String? _selectedClassName;
  int? _selectedRequestType;
  String? _accountNumberError;

  // NEW: Loại đơn hoàn tiền (null: chưa chọn, 0: lớp học, 1: khóa học)
  int? _selectedRefundType;

  // For course refund
  String? _selectedPurchaseId;
  String? _selectedCourseName;
  String? _proofImageBase64;
  File? _selectedImage;
  String? _refundEligibleError; // New: Error for refund eligibility
  // NEW: lưu id đơn lớp học đã được tạo sẵn (auto-created) để update bank info
  String? _prefilledClassRefundRequestId;

  static const Map<int, String> _requestTypeOptions = {
    0: 'Lớp bị hủy do thiếu học viên',
    1: 'Lớp bị hủy do giáo viên bận',
    2: 'Lý do cá nhân',
    3: 'Vấn đề chất lượng lớp',
    4: 'Lỗi kỹ thuật',
    5: 'Khác',
  };

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _selectedRefundType = args['selectedRefundType'];
        _selectedPurchaseId = args['selectedPurchaseId'];
        _selectedCourseName = args['selectedCourseName'];
        _tab = 0; // Chuyển sang tab "Gửi đơn"
        // NEW: Nếu vừa gửi đơn khóa học, set tab xem đơn là khóa học
        if (_selectedRefundType == 1) {
          _selectedViewRefundType = 1;
        }
      });
    }
    _scheduleVM = Get.isRegistered<ScheduleViewModel>()
        ? Get.find<ScheduleViewModel>()
        : Get.put(ScheduleViewModel(service: Get.find()), permanent: true);
    _userVM = Get.find<UserViewModel>();
    _userVM.fetchCourseRefundRequests();
    _scheduleVM.fetchMyEnrollments();
    _userVM.fetchRefundRequests();
    _userVM.fetchCoursePurchaseHistory().then((_) {
      // Sau khi fetch, đảm bảo set lại nếu có args
      if (_selectedPurchaseId != null && _selectedCourseName == null) {
        final selected = _userVM.coursePurchases.firstWhereOrNull((p) => p.purchaseId == _selectedPurchaseId);
        if (selected != null) {
          setState(() {
            _selectedCourseName = selected.courseTitle;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = File(pickedFile.path);
        _proofImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _submitRefund() async {
    if (_selectedRefundType == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn loại đơn.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => _accountNumberError = null);
    final accountNumber = _bankAccountNumberController.text.trim();
    if (accountNumber.length < 6 || accountNumber.length > 15) {
      setState(() => _accountNumberError = 'Số tài khoản cần lớn hơn 5 và nhỏ hơn 15');
      return;
    }
    if (_selectedRefundType == 0) { // Lớp học
      // Nếu là đơn tự tạo (đã có refundRequestId) thì chỉ cần bank info, không tạo mới
      final isPrefilled = _prefilledClassRefundRequestId != null;
      if (!isPrefilled) {
        if (_selectedEnrollmentID == null || _selectedClassID == null || _selectedClassName == null) {
          Get.snackbar('Lỗi', 'Vui lòng chọn lớp cần hoàn tiền.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
        if (_selectedRequestType == null) { // vẫn yêu cầu khi tạo mới
          Get.snackbar('Lỗi', 'Vui lòng chọn loại đơn.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
      }
    } else if (_selectedRefundType == 1) { // Khóa học
      if (_selectedPurchaseId == null || _selectedCourseName == null) {
        Get.snackbar('Lỗi', 'Vui lòng chọn khóa học cần hoàn tiền.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (_proofImageBase64 == null || _proofImageBase64!.isEmpty) {
        Get.snackbar('Lỗi', 'Vui lòng upload ảnh chứng minh.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      // BỎ: Không cần check _selectedRequestType cho khóa học
      // if (_selectedRequestType == null) {
      //   Get.snackbar('Lỗi', 'Vui lòng chọn loại đơn.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      //   return;
      // }
    }
    setState(() => _isSubmitting = true);
    Map<String, dynamic>? result;
    try {
      if (_selectedRefundType == 0) {
        final isPrefilled = _prefilledClassRefundRequestId != null;
        if (isPrefilled) {
          // Cập nhật thông tin ngân hàng cho đơn lớp đã có
          result = await _scheduleVM.updateClassRefundBankInfo(
            refundRequestId: _prefilledClassRefundRequestId!,
            bankName: _bankNameController.text.trim(),
            bankAccountNumber: accountNumber,
            bankAccountHolderName: _bankAccountHolderNameController.text.trim(),
          );
        } else {
          print('selectedRequestType 0: $_selectedRequestType');
          result = await _scheduleVM.submitRefundRequest(
            enrollmentID: _selectedEnrollmentID!,
            classID: _selectedClassID!,
            className: _selectedClassName!,
            requestType: _selectedRequestType!,
            bankName: _bankNameController.text.trim(),
            bankAccountNumber: accountNumber,
            bankAccountHolderName: _bankAccountHolderNameController.text.trim(),
            reason: _reasonController.text.trim(),
          );
        }
      } else if (_selectedRefundType == 1) {
        print('selectedRequestType 1: $_selectedRequestType');
        result = await _userVM.submitCourseRefund(
          purchaseId: _selectedPurchaseId!,
          bankName: _bankNameController.text.trim(),
          bankAccountNumber: accountNumber,
          bankAccountHolderName: _bankAccountHolderNameController.text.trim(),
          reason: _reasonController.text.trim(),
          proofImagePath: _selectedImage!.path, // truyền path file
        );
      }
      setState(() => _isSubmitting = false);
      if (result != null && result['status'] == 'success') {
        String message = result['data'] == "Refund request submitted successfully"
            ? "Gửi đơn hoàn tiền thành công. Đơn của bạn đang được xử lý."
            : "Gửi đơn hoàn tiền thành công.";
        Get.snackbar('Thành công', result['message'] ?? 'Gửi đơn hoàn tiền thành công.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);

        // Nếu vừa update đơn lớp có sẵn, chuyển sang tab xem đơn
        final bool updatedPrefilled = _prefilledClassRefundRequestId != null && _selectedRefundType == 0;

        if (_selectedRefundType == 1) {
          // BỎ: Không cần add local nữa vì API fetch sẽ lấy lên
        }

        // LƯU purchaseId trước khi clear form
        final String? purchaseId = _selectedPurchaseId;

        await _userVM.fetchRefundRequests();

        // Clear form (nếu vẫn ở lại trang này)
        _clearForm();

        // Điều hướng về màn chi tiết đơn mua khóa học
        if (purchaseId != null) {
          await _userVM.fetchCoursePurchaseDetail(purchaseId);
          if (_userVM.coursePurchaseDetail.value != null) {
            Get.off(() => CoursePurchaseDetailScreen(detail: _userVM.coursePurchaseDetail.value!));
          } else {
            // fallback nếu không fetch được detail
            Get.back();
          }
        } else if (updatedPrefilled) {
          // Với đơn lớp đã có sẵn, chỉ quay về tab xem đơn
          setState(() {
            _tab = 1;
            _selectedViewRefundType = 0;
          });
        } else {
          Get.back();
        }
      } else if (result != null && result['status'] == 'fail') {
        String errorMsg = "";
        if (result['errors'] == "There is already a pending refund request for this purchase") {
          errorMsg = "Bạn đã gửi đơn hoàn tiền cho khóa học này và đơn đang chờ xử lý.";
        } else if (result['message'] == "Validation failed") {
          errorMsg = "Gửi đơn thất bại do dữ liệu không hợp lệ.";
        } else {
          errorMsg = "Gửi đơn hoàn tiền thất bại.";
        }

        print('errorMsg: $errorMsg');
        Get.snackbar('Lỗi', errorMsg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar('Lỗi', 'Gửi đơn hoàn tiền thất bại.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      Get.snackbar('Lỗi', e.toString().replaceFirst('Exception: ', ''), snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _clearForm() {
    _selectedRefundType = null;
    _selectedEnrollmentID = null;
    _selectedClassID = null;
    _selectedClassName = null;
    _selectedPurchaseId = null;
    _selectedCourseName = null;
    _selectedRequestType = null;
    _proofImageBase64 = null;
    _selectedImage = null;
    _refundEligibleError = null;
    _prefilledClassRefundRequestId = null;
    _bankNameController.clear();
    _bankAccountNumberController.clear();
    _bankAccountHolderNameController.clear();
    _reasonController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: Color(0xFF1A1A1A)),
            onPressed: () => Get.back(),
          ),
          title: Text(
            _tab == 0 ? 'Gửi đơn' : 'Xem đơn',
            style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Gửi đơn', 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTabButton('Xem đơn', 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nội dung
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tab == 0 ? _buildSubmitTab() : _buildViewTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final active = _tab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _tab = index),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // Tab gửi đơn
  Widget _buildSubmitTab() {
    return Obx(() {
      if (_scheduleVM.isLoading.value || _userVM.isLoadingCoursePurchases.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      final enrollments = _scheduleVM.myEnrollments;
      final coursePurchases = _userVM.coursePurchases;
      return Column(
        children: [
          // Phần dropdown fixed ở trên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loại đơn hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: _decoration('Chọn loại đơn', 'Chọn loại'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem<int>(value: 0, child: Text('Lớp học')),
                    DropdownMenuItem<int>(value: 1, child: Text('Khóa học')),
                  ],
                  value: _selectedRefundType,
                  onChanged: (v) => setState(() => _selectedRefundType = v),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Phần form scrollable bên dưới
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedRefundType == 0) ...[ // Lớp học
                    if (enrollments.isEmpty) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Bạn chưa đăng ký lớp nào.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Vui lòng đăng ký lớp trước khi gửi đơn hoàn tiền.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Vui lòng điền đầy đủ thông tin để xử lý đơn hoàn tiền',
                                  style: TextStyle(fontSize: 13, color: Colors.orange.shade700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Thông tin lớp học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _decoration('Chọn lớp cần hoàn tiền', 'Chọn lớp'),
                        isExpanded: true,
                        items: enrollments.map((e) => DropdownMenuItem<String>(value: e.enrollmentID, child: Text(e.title ?? 'Không rõ tên lớp'))).toList(),
                        value: _selectedEnrollmentID,
                        onChanged: (value) {
                          final selected = enrollments.firstWhereOrNull((e) => e.enrollmentID == value);
                          setState(() {
                            _selectedEnrollmentID = selected?.enrollmentID;
                            _selectedClassID = selected?.classID;
                            _selectedClassName = selected?.title;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Lý do hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: _decoration('Chọn loại đơn', 'Chọn lý do'),
                        isExpanded: true,
                        items: _requestTypeOptions.entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))).toList(),
                        value: _selectedRequestType,
                        onChanged: (v) => setState(() => _selectedRequestType = v),
                      ),
                      const SizedBox(height: 24),
                      const Text('Thông tin ngân hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      _textField(controller: _bankNameController, label: 'Tên ngân hàng', hint: 'VD: Vietcombank, Techcombank...'),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Số tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                              const SizedBox(width: 8),
                              const Text('Thông tin này cần chính xác', style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                          if (_accountNumberError != null) ...[
                            const SizedBox(height: 4),
                            Text(_accountNumberError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bankAccountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Nhập số tài khoản', 'Nhập số tài khoản ngân hàng'),
                            maxLength: 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _textField(controller: _bankAccountHolderNameController, label: 'Tên chủ tài khoản', hint: 'Nhập tên chủ tài khoản'),
                      const SizedBox(height: 24),
                      const Text('Lý do hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      _textField(controller: _reasonController, label: 'Mô tả chi tiết', hint: 'Nhập lý do hoàn tiền...', maxLines: 4),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : _submitRefund,
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text('Gửi đơn hoàn tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ] else if (_selectedRefundType == 1) ...[ // Khóa học
                    // SỬA: Kiểm tra nếu list rỗng VÀ không có khóa học được chọn sẵn từ trang trước
                    if (coursePurchases.isEmpty && _selectedPurchaseId == null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Bạn chưa mua khóa học nào.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Vui lòng mua khóa học trước khi gửi đơn hoàn tiền.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Vui lòng điền đầy đủ thông tin để xử lý đơn hoàn tiền',
                                  style: TextStyle(fontSize: 13, color: Colors.orange.shade700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Thông tin khóa học', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      if (_refundEligibleError != null) ...[
                        Text(_refundEligibleError!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                        const SizedBox(height: 8),
                      ],
                      // SỬA: Dropdown hiển thị khóa học đã chọn sẵn
                      DropdownButtonFormField<String>(
                        decoration: _decoration('Chọn khóa học cần hoàn tiền', 'Chọn khóa học'),
                        isExpanded: true,
                        items: [
                          ...coursePurchases.map((p) => DropdownMenuItem<String>(value: p.purchaseId, child: Text(p.courseTitle))),
                          // Thêm item thủ công nếu khóa học đã chọn không có trong list API trả về
                          if (_selectedPurchaseId != null && !coursePurchases.any((p) => p.purchaseId == _selectedPurchaseId))
                            DropdownMenuItem<String>(
                              value: _selectedPurchaseId,
                              child: Text(_selectedCourseName ?? 'Khóa học đã chọn'),
                            ),
                        ],
                        value: _selectedPurchaseId,
                        onChanged: (value) {
                          final selected = coursePurchases.firstWhereOrNull((p) => p.purchaseId == value);
                          setState(() {
                            _selectedPurchaseId = value;
                            if (selected != null) {
                              _selectedCourseName = selected.courseTitle;
                              _refundEligibleError = selected.isRefundEligible == false ? 'Khóa học này đã hết hạn để gửi đơn.' : null;
                            } else {
                              // Nếu chọn lại cái đã được pre-fill (không có trong list), reset lỗi (vì đã check ở trang trước)
                              _refundEligibleError = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('Thông tin ngân hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      _textField(controller: _bankNameController, label: 'Tên ngân hàng', hint: 'VD: Vietcombank, Techcombank...'),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Số tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                              const SizedBox(width: 8),
                              const Text('Thông tin này cần chính xác', style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                          if (_accountNumberError != null) ...[
                            const SizedBox(height: 4),
                            Text(_accountNumberError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bankAccountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: _decoration('Nhập số tài khoản', 'Nhập số tài khoản ngân hàng'),
                            maxLength: 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _textField(controller: _bankAccountHolderNameController, label: 'Tên chủ tài khoản', hint: 'Nhập tên chủ tài khoản'),
                      const SizedBox(height: 24),
                      const Text('Ảnh chứng minh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload),
                            label: const Text('Upload ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          if (_selectedImage != null) ...[
                            const SizedBox(height: 16),
                            Image.file(_selectedImage!, height: 100, width: 100, fit: BoxFit.cover),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Lý do hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))), // GIỮ: Section cho text field
                      const SizedBox(height: 16),
                      _textField(controller: _reasonController, label: 'Mô tả chi tiết', hint: 'Nhập lý do hoàn tiền...', maxLines: 4),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSubmitting ? null : _submitRefund,
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text('Gửi đơn hoàn tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // Tab xem đơn
  Widget _buildViewTab() {
    return Column(
      children: [
        // Phần dropdown fixed ở trên, giống submit tab
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Loại đơn hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: _decoration('Chọn loại đơn', 'Chọn loại'),
                isExpanded: true,
                items: const [
                  DropdownMenuItem<int>(value: 0, child: Text('Đơn lớp học')),
                  DropdownMenuItem<int>(value: 1, child: Text('Đơn khóa học')),
                ],
                value: _selectedViewRefundType,
                onChanged: (v) => setState(() => _selectedViewRefundType = v ?? 0),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        // Phần list scrollable bên dưới
        Expanded(
          child: _selectedViewRefundType == 0 ? _buildClassRefundList() : _buildCourseRefundList(),
        ),
      ],
    );
  }

  Widget _buildClassRefundList() {
    return Obx(() {
      if (_userVM.isLoadingRefundRequests.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      final data = _userVM.refundRequests.where((req) => req['courseName'] == null).toList();
      if (data.isEmpty) {
        return const Center(child: Text('Bạn chưa có đơn hoàn tiền nào cho lớp học.'));
      }
      return ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final req = data[idx];
          final displayName = req['className'] ?? 'Không xác định';
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _prefillFromClassRefund(req),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('(Lớp học)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Số tiền: ${req['refundAmount'] ?? 0}₫', style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Trạng thái: ', style: const TextStyle(fontSize: 13)),
                      Text(_statusText(req['status']), style: TextStyle(fontSize: 13, color: _getStatusColor(req['status']), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Ngày gửi: ${req['requestedAt'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (req['adminNote'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Ghi chú: ${req['adminNote']}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }


  Widget _buildCourseRefundList() {
    return Obx(() {
      if (_userVM.isLoadingCourseRefundRequests.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      final data = _userVM.courseRefundRequests;
      if (data.isEmpty) {
        return const Center(child: Text('Bạn chưa có đơn hoàn tiền nào cho khóa học.'));
      }
      return ListView.separated(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),  // Giảm top padding từ 24 xuống 8 để gần hơn với dropdown
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final req = data[idx];
          final displayName = req['courseName'] ?? 'Không xác định';
          return InkWell( // Thêm InkWell để xử lý onTap
            onTap: () {
              final purchaseId = req['purchaseId']; // Lấy purchaseId từ req
              if (purchaseId != null) {
                Get.to(() => RefundDetailScreen(purchaseId: purchaseId));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('(Khóa học)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Số tiền: ${req['refundAmount'] ?? 0}₫', style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Trạng thái: ', style: const TextStyle(fontSize: 13)),
                      Text(_statusText(req['status']), style: TextStyle(fontSize: 13, color: _getStatusColor(req['status']), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Ngày gửi: ${req['requestedAt'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (req['adminNote'] != null) ...[
                    const SizedBox(height: 4),
                    Text('Ghi chú: ${req['adminNote']}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Color _getStatusColor(dynamic status) {
    String statusText = _statusText(status);
    switch (statusText.toLowerCase()) {
      case 'đang xử lý':
        return Colors.orange;  // Orange for pending
      case 'đã duyệt':
        return Colors.green;  // Green for approved
      case 'từ chối':
        return Colors.red;  // Red for rejected
      default:
        return Colors.black;  // Black for unknown
    }
  }

  String _statusText(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'pending':
          return 'Đang xử lý';
        case 'approved':
          return 'Đã duyệt';
        case 'rejected':
          return 'Từ chối';
        default:
          return 'Không xác định';
      }
    } else if (status is int) {
      switch (status) {
        case 0:
          return 'Đang xử lý';
        case 1:
          return 'Đã duyệt';
        case 2:
          return 'Từ chối';
        default:
          return 'Không xác định';
      }
    }
    return 'Không xác định';
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _decoration(label, hint ?? ''),
    );
  }

// Thêm hàm hỗ trợ prefill khi bấm vào đơn lớp học
  void _prefillFromClassRefund(Map req) {
    setState(() {
      // Chuyển sang tab Gửi đơn và loại đơn = Lớp học
      _tab = 0;
      _selectedRefundType = 0;

      // Điền sẵn thông tin lớp từ đơn tự tạo
      _selectedEnrollmentID = req['enrollmentID']?.toString();
      _selectedClassID = req['classID']?.toString();
      _selectedClassName = (req['className'] ?? req['title'] ?? 'Không xác định').toString();
      _selectedRequestType = req['requestType'] is int ? req['requestType'] as int : null;
      _prefilledClassRefundRequestId = (req['refundRequestId'] ?? req['id'] ?? req['refundId'])?.toString();

      // Prefill ngân hàng nếu API đã có, để trống nếu thiếu
      _bankNameController.text = (req['bankName'] ?? '').toString();
      _bankAccountNumberController.text = (req['bankAccountNumber'] ?? req['bankAccount'] ?? '').toString();
      _bankAccountHolderNameController.text = (req['bankAccountHolderName'] ?? req['accountHolder'] ?? '').toString();

      // Prefill lý do nếu có
      if (req['reason'] != null) {
        _reasonController.text = req['reason'].toString();
      }

      // Reset các state khác để tránh xung đột
      _accountNumberError = null;
      _refundEligibleError = null;
      _selectedPurchaseId = null;
      _selectedCourseName = null;
      _proofImageBase64 = null;
      _selectedImage = null;
    });
  }
}

