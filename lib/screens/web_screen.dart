import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../widgets/overlays.dart';

// النطاقات الخارجية التي تُفتح خارج التطبيق (سوشيال ميديا/مراسلة).
const Set<String> _externalHosts = {
  'facebook.com',
  'www.facebook.com',
  'm.facebook.com',
  'fb.com',
  'fb.me',
  'twitter.com',
  'www.twitter.com',
  'x.com',
  'www.x.com',
  'instagram.com',
  'www.instagram.com',
  'wa.me',
  'api.whatsapp.com',
  't.me',
  'youtube.com',
  'www.youtube.com',
  'youtu.be',
};

// المخططات (schemes) التي تُسلَّم لتطبيقات النظام مباشرة.
const Set<String> _externalSchemes = {
  'whatsapp',
  'tel',
  'mailto',
  'sms',
};

/// تبويب يعرض صفحة من الموقع داخل WebView مع شاشة بداية وعدم اتصال،
/// سحب للتحديث، وفتح الروابط الخارجية خارج التطبيق.
class WebScreen extends StatefulWidget {
  const WebScreen({
    super.key,
    required this.controller,
    required this.url,
  });

  final WebViewController controller;

  /// رابط الصفحة التي يحمّلها هذا التبويب.
  final String url;

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _netSub;

  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    widget.controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: _onNavigationRequest,
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (error) {
          if ((error.isForMainFrame ?? false) && mounted) {
            setState(() => _offline = true);
          }
        },
      ),
    );
    _watchConnectivity();
    _load();
  }

  /// يعترض الروابط: الخارجية تُفتح بتطبيق النظام، والداخلية تكمل داخل WebView.
  FutureOr<NavigationDecision> _onNavigationRequest(NavigationRequest req) {
    final url = req.url;
    final uri = Uri.tryParse(url);
    final scheme = (uri?.scheme ?? '').toLowerCase();
    final host = (uri?.host ?? '').toLowerCase();

    final isExternal = _externalSchemes.contains(scheme) ||
        (host.isNotEmpty &&
            host != kSiteHost &&
            !host.endsWith('.$kSiteHost') &&
            _externalHosts.contains(host));

    if (isExternal) {
      _launchExternal(uri ?? Uri.parse(url));
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* تجاهل: لا تطبيق يتعامل مع الرابط */}
  }

  Future<void> _load() async {
    final connected = await _hasNet();
    if (!connected) {
      if (mounted) {
        setState(() {
          _offline = true;
          _loading = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _offline = false;
        _loading = true;
      });
    }
    await widget.controller.loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _hasNet() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void _watchConnectivity() {
    _netSub = _connectivity.onConnectivityChanged.listen((result) async {
      final connected = !result.contains(ConnectivityResult.none);
      if (connected && _offline) {
        await _load();
      } else if (!connected && mounted) {
        setState(() => _offline = true);
      }
    });
  }

  @override
  void dispose() {
    _netSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_offline)
          RefreshIndicator(
            color: kPrimary,
            onRefresh: () => widget.controller.reload(),
            child: WebViewWidget(controller: widget.controller),
          ),
        if (_offline) OfflineView(onRetry: _load),
        if (_loading && !_offline) const SplashScreen(),
      ],
    );
  }
}
