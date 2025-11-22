import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../model/course_purchase_detail.dart';

class CoursePurchaseDetailScreen extends StatelessWidget {
  final CoursePurchaseDetail detail;

  const CoursePurchaseDetailScreen({super.key, required this.detail});

  String formatVND(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chi tiết khóa học',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detail.courseThumbnail,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Course Name
            Text(
              detail.courseName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              detail.courseDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow('Ngôn ngữ', detail.courseLanguage),
            _buildDetailRow('Cấp độ', detail.courseLevel),
            _buildDetailRow('Thời gian', '${detail.courseDurationDays} ngày'),
            _buildDetailRow('Giá gốc', formatVND(detail.coursePrice)),
            if (detail.courseDiscountPrice != null)
              _buildDetailRow('Giá giảm', formatVND(detail.courseDiscountPrice!)),
            _buildDetailRow('Tổng tiền', formatVND(detail.totalAmount)),
            _buildDetailRow('Giảm giá', formatVND(detail.discountAmount)),
            _buildDetailRow('Thanh toán cuối', formatVND(detail.finalAmount)),
            _buildDetailRow('Phương thức', detail.paymentMethod),
            _buildDetailRow('Trạng thái', detail.purchaseStatus),
            _buildDetailRow('Ngày mua', detail.createdAt),
            if (detail.startsAt != null) _buildDetailRow('Bắt đầu', detail.startsAt!),
            if (detail.expiresAt != null) _buildDetailRow('Hết hạn', detail.expiresAt!),
            _buildDetailRow('Còn lại', '${detail.daysRemaining} ngày'),
            _buildDetailRow('Trạng thái đăng ký', detail.enrollmentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}