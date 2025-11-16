import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
            // Nếu là scheme ngoài (app ngân hàng, tel, intent, …) thì mở ngoài
            final uri = Uri.tryParse(url);
            if (uri != null &&
                !['http','https','about','data','blob'].contains(uri.scheme)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
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

    // Ưu tiên đọc query chính xác nếu có
    try {
      final uri = Uri.parse(url);
      final status = uri.queryParameters['status'];
      final code = uri.queryParameters['code'];
      final cancelParam = uri.queryParameters['cancel'];
      final isSuccess = (status == 'PAID' && code == '00');
      final isCancel = (status == 'CANCELLED') || (cancelParam == 'true') || (code == '01');

      if (isSuccess || success) {
        _finished = true;
        Get.back(result: true);
        return;
      }
      if (isCancel || cancel) {
        _finished = true;
        Get.back(result: false);
        return;
      }
    } catch (_) {
      // ignore parse error
    }

    // Không khớp gì thì tiếp tục
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