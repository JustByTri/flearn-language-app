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

  // Bổ sung thêm pattern phổ biến (VNPay/return URL)
  final List<String> _successIndicators = [
    'status=paid',
    'code=00',
    'vnp_responsecode=00',
    'success=true',
    '/payment/success',
    '/checkout/success',
  ];
  final List<String> _cancelIndicators = [
    'status=cancelled',
    'status=failed',
    'cancel=true',
    'code=01',
    '/payment/cancel',
    '/payment/failed',
  ];

  String _sanitizeUrl(String raw) {
    var u = raw.trim();
    if (u.startsWith('https//')) u = u.replaceFirst('https//', 'https://');
    if (u.startsWith('http//')) u = u.replaceFirst('http//', 'http://');
    if (!u.contains('://')) u = 'https://$u';
    return u;
  }

  @override
  void initState() {
    super.initState();
    final safeUrl = _sanitizeUrl(widget.paymentUrl);
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
          onUrlChange: (change) {
            final u = change.url;
            if (u != null) _inspect(u);
          },
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            // Chặn scheme ngoài http(s)/about/data/blob
            if (uri != null && !['http','https','about','data','blob'].contains(uri.scheme)) {
              return NavigationDecision.prevent;
            }
            _inspect(req.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(safeUrl));
  }

  void _inspect(String url) {
    if (_finished || url.isEmpty) return;

    // Ưu tiên parse query nếu có
    try {
      final uri = Uri.parse(url);
      final status = (uri.queryParameters['status'] ?? '').toLowerCase();
      final code = (uri.queryParameters['code'] ?? '').toLowerCase();
      final vnp = (uri.queryParameters['vnp_ResponseCode'] ?? uri.queryParameters['vnp_responsecode'] ?? '').toLowerCase();
      final cancel = (uri.queryParameters['cancel'] ?? '').toLowerCase();

      final isSuccess = (status == 'paid' && code == '00') || (vnp == '00');
      final isCancel = (status == 'cancelled') || (cancel == 'true') || (code == '01');

      if (isSuccess) {
        _finished = true;
        Get.back(result: true);
        return;
      }
      if (isCancel) {
        _finished = true;
        Get.back(result: false);
        return;
      }
    } catch (_) {
      // ignore parse error -> fallback pattern match
    }

    final lower = url.toLowerCase();
    final success = _successIndicators.any((p) => lower.contains(p));
    final cancel = _cancelIndicators.any((p) => lower.contains(p));

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
      Get.back(result: false);
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
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}