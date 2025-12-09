import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flearn_app/core/constants/colors.dart';

import '../../topic/viewmodel/topic_viewmodel.dart';
import '../viewmodel/user_viewmodel.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String planName;
  final String transactionId;
  final int amount;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.planName,
    required this.transactionId,
    required this.amount,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _done = false;

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
    final safe = _sanitizeUrl(widget.paymentUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (c) {
            final u = c.url;
            if (u == null) return;
            final uri = Uri.tryParse(u);
            final status = uri?.queryParameters['status'];
            final code = uri?.queryParameters['code'];
            final cancel = uri?.queryParameters['cancel'];
            if (status == 'PAID' && code == '00') {
              if (!_done) { _done = true; Get.back(result: true); }
            } else if (status == 'CANCELLED' || cancel == 'true' || code == '01') {
              if (!_done) { _done = true; Get.back(result: false); }
            }
          },
          onNavigationRequest: (req) {
            final uri = Uri.tryParse(req.url);
            if (uri != null && !['http','https','about','data','blob'].contains(uri.scheme)) {
              return NavigationDecision.prevent;
            }
            final uri2 = Uri.parse(req.url);
            final status = uri2.queryParameters['status'];
            final code = uri2.queryParameters['code'];
            final cancel = uri2.queryParameters['cancel'];
            if (status == 'PAID' && code == '00') {
              if (!_done) { _done = true; Get.back(result: true); }
              return NavigationDecision.prevent;
            }
            if (status == 'CANCELLED' || cancel == 'true' || code == '01') {
              if (!_done) { _done = true; Get.back(result: false); }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(safe));
  }

  Future<bool> _onWillPop() async {
    if (!_done) { _done = true; Get.back(result: false); return false; }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          centerTitle: true,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}