import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../../schedule/viewmodel/schedule_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';

class RefundCenterScreen extends StatefulWidget {
  const RefundCenterScreen({super.key});

  @override
  State<RefundCenterScreen> createState() => _RefundCenterScreenState();
}

class _RefundCenterScreenState extends State<RefundCenterScreen> {
  int _tab = 0; // 0 = gửi đơn, 1 = xem đơn

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
    _scheduleVM = Get.isRegistered<ScheduleViewModel>()
        ? Get.find<ScheduleViewModel>()
        : Get.put(ScheduleViewModel(service: Get.find()), permanent: true);
    _userVM = Get.find<UserViewModel>();

    _scheduleVM.fetchMyEnrollments();
    _userVM.fetchRefundRequests();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    setState(() => _accountNumberError = null);
    final accountNumber = _bankAccountNumberController.text.trim();
    if (accountNumber.length < 6 || accountNumber.length > 15) {
      setState(() => _accountNumberError = 'Số tài khoản cần lớn hơn 5 và nhỏ hơn 15');
      return;
    }
    if (_selectedEnrollmentID == null || _selectedClassID == null || _selectedClassName == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn lớp cần hoàn tiền.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (_selectedRequestType == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn loại đơn.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await _scheduleVM.submitRefundRequest(
      enrollmentID: _selectedEnrollmentID!,
      classID: _selectedClassID!,
      className: _selectedClassName!,
      requestType: _selectedRequestType!,
      bankName: _bankNameController.text.trim(),
      bankAccountNumber: accountNumber,
      bankAccountHolderName: _bankAccountHolderNameController.text.trim(),
      reason: _reasonController.text.trim(),
    );
    setState(() => _isSubmitting = false);
    if (result != null) {
      Get.snackbar('Thành công', 'Gửi đơn hoàn tiền thành công.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      _userVM.fetchRefundRequests(); // cập nhật danh sách bên tab xem đơn
      _clearForm();
    }
  }

  void _clearForm() {
    _selectedEnrollmentID = null;
    _selectedClassID = null;
    _selectedClassName = null;
    _selectedRequestType = null;
    _bankNameController.clear();
    _bankAccountNumberController.clear();
    _bankAccountHolderNameController.clear();
    _reasonController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1A1A1A)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Hoàn tiền',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 18),
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
      if (_scheduleVM.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      final enrollments = _scheduleVM.myEnrollments;
      if (enrollments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.info_circle, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Bạn chưa đăng ký lớp nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text('Vui lòng đăng ký lớp trước khi gửi đơn hoàn tiền', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text('Loại đơn hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
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
        ),
      );
    });
  }

  // Tab xem đơn
  Widget _buildViewTab() {
    return Obx(() {
      if (_userVM.isLoadingRefundRequests.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }
      if (_userVM.refundRequests.isEmpty) {
        return const Center(child: Text('Bạn chưa có đơn hoàn tiền nào.'));
      }
      final data = _userVM.refundRequests;
      return ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, idx) {
          final req = data[idx];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['className'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Số tiền: ${req['refundAmount']}₫', style: const TextStyle(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Trạng thái: ${_statusText(req['status'])}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('Ngày gửi: ${req['requestedAt'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (req['adminNote'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Ghi chú: ${req['adminNote']}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  String _statusText(int? status) {
    switch (status) {
      case 0: return 'Đang xử lý';
      case 1: return 'Đã duyệt';
      case 2: return 'Từ chối';
      default: return 'Không xác định';
    }
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
}