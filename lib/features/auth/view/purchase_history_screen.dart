import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';
import '../model/purchase_history.dart';
import '../viewmodel/user_viewmodel.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final userVM = Get.find<UserViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userVM.fetchPurchaseHistory();
    });
  }

  String formatVND(int price) {
    if (price == 0) return 'Miễn phí';
    return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫';
  }

  Color statusColor(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return const Color(0xFF34C759);
    if (v == 'pending') return const Color(0xFFFF9500);
    if (v == 'failed') return const Color(0xFFFF3B30);
    return Colors.blueGrey;
  }

  IconData statusIcon(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return CupertinoIcons.arrow_down_circle_fill;
    if (v == 'pending') return CupertinoIcons.clock_fill;
    if (v == 'failed') return CupertinoIcons.xmark_circle_fill;
    return CupertinoIcons.circle_fill;
  }

  /// 🔥 Map status sang tiếng Việt
  String getVietnameseStatus(String s) {
    final v = s.toLowerCase();
    if (v == 'completed') return 'Hoàn thành';
    if (v == 'failed') return 'Thất bại';
    return s;
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
      body: Obx(() {
        if (userVM.isLoadingPurchases.value) {
          return const Center(child: CircularProgressIndicator());
        }

        /// 🔥 LỌC BỎ CÁC ITEM PENDING
        final filteredList = userVM.purchaseHistory
            .where((p) => p.purchaseStatus.toLowerCase() != 'pending')
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
          onRefresh: () => userVM.fetchPurchaseHistory(),
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
      }),
    );
  }

  Widget _buildPurchaseItem(Purchase p) {
    final statusCol = statusColor(p.purchaseStatus);
    final icon = statusIcon(p.purchaseStatus);

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
                        p.courseName,
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
                        color: p.purchaseStatus.toLowerCase() == 'completed'
                            ? const Color(0xFF34C759)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),


                    Text(
                      getVietnameseStatus(p.purchaseStatus),
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
