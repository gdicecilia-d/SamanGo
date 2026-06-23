import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class PayPalService {
  Future<bool?> processPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
    required String returnUrl,
    required String cancelUrl,
    required String reservaId,
    required String destinoId,
    required String estudianteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-samango.cloudfunctions.net/createPayPalOrder'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'description': description,
          'returnUrl': returnUrl,
          'cancelUrl': cancelUrl,
        }),
      );

      if (response.statusCode != 200) {
        print('Error en Cloud Function PayPal: ${response.body}');
        return false;
      }

      final responseData = jsonDecode(response.body);
      final approveUrl = responseData['approveUrl'];

      if (approveUrl == null) {
        return false;
      }

      if (kIsWeb) {
        html.window.localStorage['paypal_pending'] = jsonEncode({
          'reservaId': reservaId,
          'destinoId': destinoId,
          'estudianteId': estudianteId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        html.window.location.href = approveUrl;
        return true;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PayPalWebViewPage(
            url: approveUrl,
            returnUrl: returnUrl,
            cancelUrl: cancelUrl,
          ),
        ),
      );
      return result == true;
      
    } catch (e) {
      print('Error en PayPal: $e');
      return false;
    }
  }
}

class PayPalWebViewPage extends StatefulWidget {
  final String url;
  final String returnUrl;
  final String cancelUrl;

  const PayPalWebViewPage({
    super.key,
    required this.url,
    required this.returnUrl,
    required this.cancelUrl,
  });

  @override
  State<PayPalWebViewPage> createState() => _PayPalWebViewPageState();
}

class _PayPalWebViewPageState extends State<PayPalWebViewPage> {
  late final WebViewController _controller;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (change) {
            final url = change.url ?? '';
            if (_isRedirecting) return;

            if (url.contains('success') ||
                url.contains('return') ||
                url.contains('approved') ||
                url.contains('completed') ||
                url.contains(widget.returnUrl)) {
              _isRedirecting = true;
              Navigator.pop(context, true);
            }

            if (url.contains('cancel') ||
                url.contains('cancelar') ||
                url.contains('cancelled') ||
                url.contains(widget.cancelUrl)) {
              _isRedirecting = true;
              Navigator.pop(context, false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PayPal - Completa tu pago'),
        backgroundColor: const Color(0xFFFC6707),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}