import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      final clientId = dotenv.env['PAYPAL_CLIENT_ID'] ?? '';
      final secretKey = dotenv.env['PAYPAL_CLIENT_SECRET'] ?? '';

      if (clientId.isEmpty || secretKey.isEmpty) {
        return false;
      }

      final auth = base64Encode(utf8.encode('$clientId:$secretKey'));

      final tokenResponse = await http.post(
        Uri.parse('https://api-m.sandbox.paypal.com/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (tokenResponse.statusCode != 200) {
        return false;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      final orderResponse = await http.post(
        Uri.parse('https://api-m.sandbox.paypal.com/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'amount': {
                'currency_code': currency,
                'value': amount.toStringAsFixed(2),
              },
              'description': description,
            }
          ],
          'application_context': {
            'return_url': returnUrl,
            'cancel_url': cancelUrl,
          }
        }),
      );

      if (orderResponse.statusCode != 201) {
        return false;
      }

      final orderData = jsonDecode(orderResponse.body);
      final links = orderData['links'] as List;
      final approveLink = links.firstWhere(
        (link) => link['rel'] == 'approve',
        orElse: () => null,
      );

      if (approveLink == null) {
        return false;
      }

      final approveUrl = approveLink['href'];

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