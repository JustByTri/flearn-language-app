import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfViewScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  const PdfViewScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final viewerUrl = 'https://drive.google.com/viewerng/viewer?embedded=true&url=${widget.pdfUrl}';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}