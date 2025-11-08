import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:flearn_app/core/constants/colors.dart';

class PaymentCourseWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String purchaseId;
  final String transactionReference;
  final int amount;

  const PaymentCourseWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.purchaseId,
    required this.transactionReference,
    required this.amount,
  });

  @override
  State<PaymentCourseWebViewScreen> createState() => _PaymentCourseWebViewScreenState();
}

class _PaymentCourseWebViewScreenState extends State<PaymentCourseWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  // Adjust patterns to your real returnUrl if needed
  final List<String> _successIndicators = [
    'status=PAID',
    'success=true',
    '/payment/success',
  ];
  final List<String> _cancelIndicators = [
    'status=CANCELLED',
    'status=FAILED',
    'cancel=true',
    '/payment/cancel',
    '/payment/failed',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (url) {
            setState(() => _loading = false);
            _inspect(url);
          },
          onNavigationRequest: (req) {
            _inspect(req.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _inspect(String url) {
    if (_finished) return;
    final lower = url.toLowerCase();

    final success = _successIndicators.any((p) => lower.contains(p.toLowerCase()));
    final cancel = _cancelIndicators.any((p) => lower.contains(p.toLowerCase()));

    if (success) {
      _finished = true;
      Get.back(result: true);
    } else if (cancel) {
      _finished = true;
      Get.back(result: false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_finished) {
      _finished = true;
      Get.back(result: false); // treat as cancel
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán khóa học'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                if (!_finished) {
                  _finished = true;
                  Get.back(result: false);
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}