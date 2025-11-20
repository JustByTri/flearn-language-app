import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

class PaymentScheduleWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String transactionId;
  final String classId;
  final int amount;

  const PaymentScheduleWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.transactionId,
    required this.classId,
    required this.amount,
  });

  @override
  State<PaymentScheduleWebViewScreen> createState() => _PaymentScheduleWebViewScreenState();
}

class _PaymentScheduleWebViewScreenState extends State<PaymentScheduleWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  final List<String> _successIndicators = [
    'status=PAID',
    'code=00',
    '/payment/success',
    'success=true',
  ];
  final List<String> _cancelIndicators = [
    'status=CANCELLED',
    'status=FAILED',
    'cancel=true',
    'code=01',
    '/payment/cancel',
    '/payment/failed',
  ];

  String _sanitizeUrl(String raw) {
    var u = raw.trim();
    // sửa lỗi thiếu ":" như "https//"
    if (u.startsWith('https//')) u = u.replaceFirst('https//', 'https://');
    if (u.startsWith('http//')) u = u.replaceFirst('http//', 'http://');
    // nếu thiếu scheme thì thêm https
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
          onNavigationRequest: (req) {
            final url = req.url;
            final uri = Uri.tryParse(url);
            // Chỉ prevent nếu là scheme ngoài, KHÔNG gọi launchUrl
            if (uri != null &&
                !['http','https','about','data','blob'].contains(uri.scheme)) {
              // Có thể show thông báo hoặc ignore, KHÔNG mở ngoài app
              return NavigationDecision.prevent;
            }
            _inspect(url);
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final u = change.url;
            if (u != null) _inspect(u);
          },
        ),
      )
      ..loadRequest(Uri.parse(safeUrl));
  }

  void _inspect(String url) {
    if (_finished) return;
    final lower = url.toLowerCase();

    final success = _successIndicators.any((p) => lower.contains(p.toLowerCase()));
    final cancel = _cancelIndicators.any((p) => lower.contains(p.toLowerCase()));

    try {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'];
      final code = uri.queryParameters['code'];
      final cancelParam = uri.queryParameters['cancel'];
      final isCancel = (status == 'CANCELLED') || (cancelParam == 'true') || (code == '01');
      final isSuccess = (status == 'PAID' && code == '00');

      // Ưu tiên hủy nếu có dấu hiệu hủy
      if (isCancel || cancel) {
        _finished = true;
        Get.back(result: false);
        return;
      }
      if (isSuccess || success) {
        _finished = true;
        Get.back(result: true);
        return;
      }
    } catch (_) {
      // parse error -> bỏ qua
    }
  }

  Future<bool> _onWillPop() async {
    if (_finished) return true;
    _finished = true;
    Get.back(result: false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán lịch học'),
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