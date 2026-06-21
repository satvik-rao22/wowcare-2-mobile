import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Hosts `assets/forte_auto_pay.html` to collect card / ACH details and
/// tokenize them with the Forte JS SDK (which has no native Dart equivalent and
/// must run in a browser context to keep raw PAN/account data out of our app).
///
/// Pops with the raw callback map from the HTML:
/// ```
/// { success: true, paymentType: 'card'|'echeck', data: { onetime_token, card_type, ... } }
/// // or
/// { success: false, error: {...} }
/// ```
class AutoPayTokenWebView extends StatefulWidget {
  const AutoPayTokenWebView({super.key, required this.payload});

  /// Init payload injected into the HTML: `{ env, apiLoginId, isAutoPayEnabled }`.
  final Map<String, dynamic> payload;

  @override
  State<AutoPayTokenWebView> createState() => _AutoPayTokenWebViewState();
}

class _AutoPayTokenWebViewState extends State<AutoPayTokenWebView> {
  InAppWebViewController? _controller;
  String? _html;
  bool _hasInjectedData = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHtml());
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/forte_auto_pay.html');
    if (mounted) {
      setState(() => _html = html);
    }
  }

  Future<void> _injectPayload() async {
    if (_controller == null || _hasInjectedData || _html == null) return;
    final payloadJson = jsonEncode(widget.payload);
    // Double-encode so the JSON string is passed as a safe string literal.
    final script = 'window.initializeAutoPay(${jsonEncode(payloadJson)});';
    await _controller!.evaluateJavascript(source: script);
    _hasInjectedData = true;
  }

  void _handleCallback(dynamic data) {
    // Surface the Forte-side response (incl. onetime_token) in app logs.
    debugPrint('[AUTOPAY][WEBVIEW] autopayTokenCallback: $data');
    if (data is Map) {
      final tokenData = data['data'];
      final token = tokenData is Map
          ? (tokenData['onetime_token'] ?? tokenData['onetimeToken'])
          : null;
      debugPrint('[AUTOPAY][WEBVIEW] one_time_token: $token');
    }
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    unawaited(Navigator.of(context).maybePop(data ?? {'success': false}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Auto Pay'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _html == null
          ? const Center(child: PrimaryCircularLoader())
          : InAppWebView(
              initialData: InAppWebViewInitialData(
                data: _html!,
                baseUrl: WebUri.uri(Uri.parse(
                    'https://forte-autopay.${widget.payload['env'] ?? 'sandbox'}')),
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'autopayTokenCallback',
                  callback: (args) {
                    if (args.isNotEmpty) {
                      _handleCallback(args[0]);
                    }
                    return null;
                  },
                );
              },
              onLoadStop: (_, __) async {
                await _injectPayload();
              },
              onConsoleMessage: (controller, consoleMessage) {
                // Forwards the HTML's `[AutoPay]` logs (incl. the Forte token
                // response) into the Flutter console.
                debugPrint('[AUTOPAY][WEBVIEW][JS] ${consoleMessage.message}');
              },
              onPermissionRequest: (controller, request) async {
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.DENY,
                );
              },
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useShouldOverrideUrlLoading: false,
              ),
            ),
    );
  }
}
