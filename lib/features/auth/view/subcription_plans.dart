import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flearn_app/core/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart'; // Thêm package này vào pubspec.yaml
import 'payment_webview_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoadingPlans = true;
  String? _selectedPlan;
  bool _isPurchasing = false;


  bool _waitingForPayment = false;
  String? _pendingPlan;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionPlans();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi người dùng back thủ công từ trình duyệt về app
    if (state == AppLifecycleState.resumed && _waitingForPayment) {
      _checkSubscriptionStatus();
    }
  }

  Future<void> _fetchSubscriptionPlans() async {
    setState(() => _isLoadingPlans = true);
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/subscriptions/plans');
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          setState(() {
            _plans = List<Map<String, dynamic>>.from(jsonBody['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy plans: $e');
    } finally {
      setState(() => _isLoadingPlans = false);
    }
  }

  Future<void> _purchasePlan(String planName) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Xác nhận mua gói $planName"),
        content: Text("Bạn có chắc chắn muốn mua gói $planName không?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Huỷ"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Get.back(result: true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPurchasing = true);
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/subscriptions/purchase');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({"plan": planName}),
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (jsonBody['success'] == true && jsonBody['data'] != null) {
          final paymentUrl = jsonBody['data']['paymentUrl'];
          final transactionId = '${jsonBody['data']['transactionId']}';
          final amount = (jsonBody['data']['amount'] ?? 0) as int;

          if (paymentUrl != null) {
            final paid = await Get.to<bool>(() => PaymentWebViewScreen(
              paymentUrl: paymentUrl,
              planName: planName,
              transactionId: transactionId,
              amount: amount,
            ));

            if (paid == true) {

              await handlePaymentCallback(
                transactionId: transactionId,
                code: "00",
                amount: amount,
                signature: "",
                plan: planName,
              );
              Navigator.of(context).pop(true);
              return;
            } else if (paid == false) {
              Get.snackbar(
                "Thanh toán thất bại",
                "Bạn đã hủy giao dịch hoặc thanh toán không thành công.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }
            return;
          }
        }
      }

      Get.snackbar(
        "Lỗi",
        "Không thể tạo giao dịch. Vui lòng thử lại.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Lỗi",
        "Không thể kết nối. Vui lòng thử lại.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> handlePaymentCallback({
    required String transactionId,
    required String code,
    required int amount,
    required String signature,
    required String plan,
  }) async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/subscriptions/callback');
    final status = code == "00" ? "PAID" : "FAILED";

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "transactionId": transactionId,
          "status": status,
          "amount": amount,
          "signature": signature,
          "plan": plan,
        }),
      );

      if (response.statusCode == 200) {
        final jsonBody = jsonDecode(response.body);
        if (status == "PAID") {
          Get.snackbar(
            "Thanh toán thành công",
            "Bạn đã mua gói $plan thành công!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            "Thanh toán thất bại",
            "Có lỗi xảy ra khi thanh toán. Vui lòng thử lại.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          "Lỗi hệ thống",
          "Không thể xác nhận giao dịch. Vui lòng thử lại.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Lỗi kết nối",
        "Không thể kết nối tới hệ thống. Vui lòng thử lại.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // NEW: kiểm tra kết quả khi quay lại app hoặc khi bấm nút "Tôi đã thanh toán xong"
  Future<void> _checkSubscriptionStatus() async {
    final accessToken = GetStorage().read('accessToken');
    final url = Uri.parse('https://f-learn.app/api/conversation/usage');
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          // success=true <=> status=PAID (code=00)
          Get.snackbar(
            "Thanh toán thành công",
            _pendingPlan != null ? "Bạn đã mua gói $_pendingPlan thành công!" : "Giao dịch thành công!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            "Thanh toán thất bại",
            "Giao dịch không thành công. Vui lòng thử lại.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Check payment error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _waitingForPayment = false;
          _pendingPlan = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Gói đăng ký',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingPlans
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _fetchSubscriptionPlans,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF5AB0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.rocket_fill,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nâng cấp tài khoản',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Chọn gói phù hợp để tăng lượt luyện tập',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Hiển thị thanh nhắc kiểm tra khi đang chờ kết quả thanh toán
              if (_waitingForPayment) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF34C759).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF34C759)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Nếu bạn đã thanh toán xong, bấm để kiểm tra trạng thái.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _checkSubscriptionStatus,
                        child: const Text('Tôi đã thanh toán xong'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ..._plans.map((plan) {
                return _buildPlanCard(
                  planName: plan['plan'] ?? '',
                  dailyQuota: plan['dailyQuota'] ?? 0,
                  price: plan['priceVnd'] ?? '',
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planName,
    required int dailyQuota,
    required String price,
  }) {
    final isSelected = _selectedPlan == planName;
    Color planColor = const Color(0xFF4A90E2);
    IconData planIcon = CupertinoIcons.star_fill;

    if (planName.contains('10')) {
      planColor = const Color(0xFF34C759);
      planIcon = CupertinoIcons.flame_fill;
    } else if (planName.contains('15')) {
      planColor = const Color(0xFFFF9500);
      planIcon = CupertinoIcons.bolt_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? planColor : Colors.grey.shade200,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? planColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: isSelected ? 15 : 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedPlan = planName;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            planColor,
                            planColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: planColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(planIcon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: planColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dailyQuota lượt/ngày',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: planColor,
                          ),
                        ),
                        Text(
                          '/tháng',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: planColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tăng $dailyQuota lượt luyện tập mỗi ngày',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPurchasing ? null : () => _purchasePlan(planName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: planColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isPurchasing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.cart_fill, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mua gói $planName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}