import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants.dart';
import '../services/favorites_service.dart';
import '../widgets/overlays.dart';

/// التبويب الرئيسي: يعرض الموقع داخل WebView مع شاشة بداية وعدم اتصال،
/// وزر أصلي لإضافة الصفحة الحالية إلى المفضّلة.
class WebScreen extends StatefulWidget {
  const WebScreen({super.key, required this.controller});

  final WebViewController controller;

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
    await widget.controller.loadRequest(Uri.parse(kUrl));
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

  Future<void> _addCurrentToFavorites() async {
    final url = await widget.controller.currentUrl();
    if (url == null) return;
    String title = url;
    try {
      final t = await widget.controller
          .runJavaScriptReturningResult('document.title');
      title = t.toString().replaceAll('"', '').trim();
      if (title.isEmpty) title = 'دليلك';
    } catch (_) {}

    final added = await FavoritesService.add(FavItem(title: title, url: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added ? 'أُضيفت إلى المفضّلة ⭐' : 'موجودة في المفضّلة'),
        duration: const Duration(seconds: 2),
      ),
    );
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
        if (!_offline) WebViewWidget(controller: widget.controller),
        if (_offline) OfflineView(onRetry: _load),
        if (_loading && !_offline) const SplashScreen(),
        if (!_offline && !_loading)
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'fav',
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              onPressed: _addCurrentToFavorites,
              child: const Icon(Icons.bookmark_add_outlined),
            ),
          ),
      ],
    );
  }
}
