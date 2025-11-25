import 'package:flearn_app/features/auth/view/refund_center_screen.dart';
import 'package:flearn_app/features/auth/view/refund_course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../model/course_purchase_detail.dart';
import '../viewmodel/user_viewmodel.dart';

class CoursePurchaseDetailScreen extends StatefulWidget {
  final CoursePurchaseDetail detail;

  const CoursePurchaseDetailScreen({super.key, required this.detail});

  @override
  State<CoursePurchaseDetailScreen> createState() => _CoursePurchaseDetailScreenState();
}

class _CoursePurchaseDetailScreenState extends State<CoursePurchaseDetailScreen> {
  final UserViewModel userViewModel = Get.find<UserViewModel>(); // Inject UserViewModel
  Map<String, dynamic>? _refundDetail;
  bool _isLoadingRefund = false;

  @override
  void initState() {
    super.initState();
    _fetchRefundDetail();
  }

  Future<void> _fetchRefundDetail() async {
    setState(() => _isLoadingRefund = true);
    try {
      final detail = await userViewModel.fetchRefundDetail(widget.detail.purchaseId);
      setState(() {
        _refundDetail = detail;
      });
    } catch (e) {
      print('Fetch refund detail error: $e');
    } finally {
      setState(() => _isLoadingRefund = false);
    }
  }

  void _showRefundDetailDialog() {
    // Thay đổi: Chuyển đến trang mới thay vì dialog
    Get.to(() => RefundDetailScreen(purchaseId: widget.detail.purchaseId));
  }

  String formatVND(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'active':
        return Colors.green;
      case 'expired':
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính trạng thái đơn để hiển thị
    String displayPurchaseStatus = widget.detail.purchaseStatus;
    if (widget.detail.purchaseStatus.toLowerCase() == 'completed') {
      displayPurchaseStatus = 'Hoàn thành';
    } else if (widget.detail.purchaseStatus.toLowerCase() == 'failed') {
      displayPurchaseStatus = 'Thất bại';
    }

    // Kiểm tra xem nút có disable không
    bool isButtonDisabled = widget.detail.purchaseStatus.toLowerCase() == 'failed';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar với thumbnail
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Get.back(),
                          ),
                          const Expanded(
                            child: Text(
                              'Chi tiết khóa học đã mua',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
                // Thumbnail
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        widget.detail.courseThumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Cấp độ: ${widget.detail.courseLevel}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Course Name
                  Text(
                    widget.detail.courseName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Row
                  Row(
                    children: [
                      _buildInfoItem(Icons.language, widget.detail.courseLanguage),
                      const SizedBox(width: 20),
                      _buildInfoItem(Icons.access_time, '${widget.detail.courseDurationDays} ngày'),
                      const SizedBox(width: 20),
                      _buildInfoItem(Icons.calendar_today, '${widget.detail.daysRemaining} ngày còn lại'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1)),

          // Description Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô tả khóa học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.detail.courseDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Payment Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin thanh toán',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.attach_money, 'Giá gốc', formatVND(widget.detail.coursePrice)),
                        if (widget.detail.courseDiscountPrice != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.local_offer, 'Giá giảm', formatVND(widget.detail.courseDiscountPrice!)),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.shopping_cart, 'Tổng tiền', formatVND(widget.detail.totalAmount)),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.payment, 'Thanh toán cuối', formatVND(widget.detail.finalAmount), isBold: true),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.credit_card, 'Phương thức', widget.detail.paymentMethod),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái & thời gian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.shopping_bag, 'Trạng thái đơn', displayPurchaseStatus, statusColor: _getStatusColor(widget.detail.purchaseStatus)),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.calendar_month, 'Ngày mua', widget.detail.createdAt),
                        if (widget.detail.startsAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.play_circle, 'Bắt đầu', widget.detail.startsAt!),
                        ],
                        if (widget.detail.expiresAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.event_busy, 'Hết hạn', widget.detail.expiresAt!),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.hourglass_empty, 'Còn lại', '${widget.detail.daysRemaining} ngày', statusColor: widget.detail.daysRemaining > 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_refundDetail != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showRefundDetailDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xem đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: isButtonDisabled ? null : () {
                    if (!widget.detail.isRefundEligible) {
                      Get.snackbar('Thông báo', 'Khóa học này đã hết hạn để gửi đơn.', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    Get.to(() => const RefundCenterScreen(), arguments: {
                      'selectedRefundType': 1,
                      'selectedPurchaseId': widget.detail.purchaseId,
                      'selectedCourseName': widget.detail.courseName,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonDisabled ? Colors.grey.shade400 : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isButtonDisabled ? 0 : 0,
                  ),
                  child: const Text('Gửi đơn hoàn tiền', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBold = false, Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: statusColor ?? Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: statusColor ?? Colors.grey.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}