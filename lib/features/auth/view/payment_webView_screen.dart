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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final uri = Uri.parse(req.url);
            final status = uri.queryParameters['status'];
            final code = uri.queryParameters['code'];
            final cancel = uri.queryParameters['cancel'];

            if (status == 'PAID' && code == '00') {
              if (!_done) {
                _done = true;
                Get.back(result: true);
              }
              return NavigationDecision.prevent;
            }

            if (status == 'CANCELLED' || cancel == 'true' || code == '01') {
              if (!_done) {
                _done = true;
                Get.back(result: false);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _onPaymentSuccess() async {

    if (Get.isRegistered<UserViewModel>()) {
      await Get.find<UserViewModel>().fetchUserInfo();
    }
    if (Get.isRegistered<TopicViewModel>()) {
      await Get.find<TopicViewModel>().fetchConversationUsage();
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}