import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/src/app_router.dart';

/// Typed `extra` for [WebViewScreen.routeName] (no untyped maps).
class WebViewArgs {
  const WebViewArgs({required this.url, this.title = ''});

  final String url;
  final String title;
}

/// The one and only way to open a link in the in-app browser.
///
/// Call it from anywhere — a drawer tile, a body link, a bottom sheet:
///
/// ```dart
/// openWebViewScreen(context, url: 'https://…', title: 'Privacy Policy');
/// ```
///
/// Two things it handles so no call site has to:
///
/// * **An open drawer.** Every drawer tile would otherwise need its own
///   close-then-navigate dance, and the closing drawer paints over the
///   incoming page for a frame if the push happens too early. Nothing
///   happens here when no drawer is open, so non-drawer call sites are
///   unaffected.
/// * **Push, not go.** [appRouter].push keeps the current screen underneath
///   so back returns to it; `appRouterGo`/`.go` would replace the stack and
///   strand the user on whatever the new location resolves to.
Future<void> openWebViewScreen(
  BuildContext context, {
  required String url,
  String title = '',
}) async {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold?.isDrawerOpen ?? false) {
    scaffold!.closeDrawer();
    await WidgetsBinding.instance.endOfFrame;
  }
  await appRouter.push<void>(
    WebViewScreen.routeName,
    extra: WebViewArgs(url: url, title: title),
  );
}

/// Generic in-app browser for a static link (privacy policy, terms, etc.).
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key, required this.url, this.title = ''});

  /// Root-level route (outside the dashboard shell) so the page covers the
  /// bottom nav bar, for the same reason the staff document viewer is.
  static const String routeName = '/web-view';

  final String url;
  final String title;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void dispose() {
    debugPrint('WEBVIEW_DISPOSE');
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(widget.url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Let the hardware/gesture back walk the page history first, and only
      // leave the screen once there is nothing left to go back to.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        debugPrint('WEBVIEW_POP_INVOKED didPop=$didPop');
        if (didPop) return;
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
          return;
        }
        if (mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppPalette.surfacePage,
        // The flat skin gives the bar the page ground and dark ink, like
        // CustomAppBar — no gradient flexibleSpace behind it.
        appBar: AppBar(
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppPalette.surfacePage,
          foregroundColor: AppPalette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          child: _hasError ? _buildError() : _buildWebView(),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            transparentBackground: true,
          ),
          onWebViewCreated: (controller) => _controller = controller,
          onLoadStop: (controller, url) {
            if (mounted) setState(() => _isLoading = false);
          },
          // Only the main frame matters here — a failed tracking pixel or
          // font on the page shouldn't blank out readable content.
          onReceivedError: (controller, request, error) {
            if (request.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
          onReceivedHttpError: (controller, request, response) {
            if (request.isForMainFrame == false) return;
            if ((response.statusCode ?? 0) >= 400 && mounted) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
        if (_isLoading) const Center(child: PrimaryCircularLoader()),
      ],
    );
  }

  Widget _buildError() {
    return AppErrorState(
      title: 'Unable to load this page.',
      message: 'Please check your connection.',
      onRetry: _reload,
    );
  }
}
