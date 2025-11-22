import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';

import '../model/course_purchase_history.dart';
import '../model/subcription_purchase_history.dart';
import '../viewmodel/user_viewmodel.dart';
import 'course_purchase_detail_screen.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final userVM = Get.find<UserViewModel>();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userVM.fetchCoursePurchaseHistory(); // Use new method
      userVM.fetchSubscriptionPurchaseHistory();
    });
  }

  String formatVND(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }

  // Update status functions to use 'status' instead of 'purchaseStatus'
  Color statusColor(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return const Color(0xFF34C759);
    if (v == 'refunded') return const Color(0xFFFF9500); // Add for new status
    if (v == 'failed') return const Color(0xFFFF3B30);
    return Colors.blueGrey;
  }

  IconData statusIcon(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return CupertinoIcons.arrow_down_circle_fill;
    if (v == 'refunded') return CupertinoIcons.arrow_left_circle_fill; // Add for new status
    if (v == 'failed') return CupertinoIcons.xmark_circle_fill;
    return CupertinoIcons.circle_fill;
  }

  /// 🔥 Map status sang tiếng Việt
  String getVietnameseStatus(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return 'Hoàn thành';
    if (v == 'refunded') return 'Đã hoàn tiền'; // Add for new status
    if (v == 'failed') return 'Thất bại';
    return s;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Tab Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Lịch sử mua khóa học', 0)),
                const SizedBox(width: 12),
                Expanded(child: _buildTabButton('Lịch sử mua gói', 1)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Body Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _tab == 0 ? _buildCoursePurchaseTab() : _buildSubscriptionPurchaseTab(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCoursePurchaseTab() {
    return Obx(() {
      if (userVM.isLoadingCoursePurchases.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filter out 'pending' or other statuses if needed
      final filteredList = userVM.coursePurchases
          .where((p) => p.status.toLowerCase() != 'pending')
          .toList();

      if (filteredList.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_text, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Chưa có giao dịch nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => userVM.fetchCoursePurchaseHistory(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: filteredList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = filteredList[index];
            return _buildPurchaseItem(p);
          },
        ),
      );
    });
  }


  Widget _buildSubscriptionPurchaseTab() {
    return Obx(() {
      if (userVM.isLoadingSubscriptionPurchases.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filter out 'pending' or other statuses if needed
      final filteredList = userVM.subscriptionPurchases
          .where((p) => p.status.toLowerCase() != 'pending')
          .toList();

      if (filteredList.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.time, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch sử mua gói',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => userVM.fetchSubscriptionPurchaseHistory(),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: filteredList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final p = filteredList[index];
            return _buildSubscriptionItem(p);
          },
        ),
      );
    });
  }

  Widget _buildSubscriptionItem(SubscriptionPurchase p) {
    final statusCol = statusColor(p.status);
    final icon = statusIcon(p.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusCol.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: statusCol, size: 24),
                ),

                const SizedBox(width: 14),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.subscriptionType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.paymentMethod,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Quota: ${p.conversationQuota}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Giá + Trạng thái
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatVND(p.finalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.status.toLowerCase() == 'completed'
                            ? const Color(0xFF34C759)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      getVietnameseStatus(p.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: statusCol,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseItem(CoursePurchase p) {
    final statusCol = statusColor(p.status);
    final icon = statusIcon(p.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await userVM.fetchCoursePurchaseDetail(p.purchaseId);
            if (userVM.coursePurchaseDetail.value != null) {
              Get.to(() => CoursePurchaseDetailScreen(detail: userVM.coursePurchaseDetail.value!));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusCol.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: statusCol, size: 24),
                ),

                const SizedBox(width: 14),

                // Nội dung
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.courseTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.paymentMethod,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        p.enrollmentStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Giá + Trạng thái
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatVND(p.finalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.status.toLowerCase() == 'completed'
                            ? const Color(0xFF34C759)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      getVietnameseStatus(p.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: statusCol,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}