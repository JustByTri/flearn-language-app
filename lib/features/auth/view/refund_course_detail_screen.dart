import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../viewmodel/user_viewmodel.dart';

class RefundDetailScreen extends StatefulWidget {
  final String purchaseId;

  const RefundDetailScreen({super.key, required this.purchaseId});

  @override
  State<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends State<RefundDetailScreen> {
  final UserViewModel userViewModel = Get.find<UserViewModel>();
  Map<String, dynamic>? _refundDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRefundDetail();
  }

  Future<void> _fetchRefundDetail() async {
    try {
      final detail = await userViewModel.fetchRefundDetail(widget.purchaseId);
      setState(() {
        _refundDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Lỗi', 'Không thể tải chi tiết đơn.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Chi tiết đơn hoàn tiền',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _refundDetail == null
          ? const Center(child: Text('Không tìm thấy đơn hoàn tiền.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Thông tin khóa học', [
              _buildRow('Khóa học', _refundDetail!['courseName'] ?? 'N/A'),
              _buildRow('Số tiền hoàn', '${_refundDetail!['refundAmount'] ?? 0}₫'),
              _buildRow('Lý do', _refundDetail!['reason'] ?? 'N/A'),
              _buildRow('Trạng thái', _refundDetail!['status'] ?? 'N/A'),
              _buildRow('Ngày gửi', _refundDetail!['requestedAt'] ?? 'N/A'),
              if (_refundDetail!['adminNote'] != null) _buildRow('Ghi chú', _refundDetail!['adminNote']),
            ]),
            const SizedBox(height: 24),
            _buildSection('Thông tin ngân hàng', [
              _buildRow('Tên ngân hàng', _refundDetail!['bankName'] ?? 'N/A'),
              _buildRow('Số tài khoản', _refundDetail!['bankAccountNumber'] ?? 'N/A'),
              _buildRow('Tên chủ tài khoản', _refundDetail!['bankAccountHolderName'] ?? 'N/A'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}