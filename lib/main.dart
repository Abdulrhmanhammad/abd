import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'constants.dart';
import 'screens/favorites_screen.dart';
import 'screens/more_screen.dart';
import 'screens/web_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kPrimary,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const DaleelakApp());
}

class DaleelakApp extends StatelessWidget {
  const DaleelakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليلك',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kPrimary,
      ),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const RootShell(),
    );
  }
}

/// الهيكل الرئيسي: شريط تنقّل سفلي أصلي بثلاثة تبويبات.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final WebViewController _web;
  final GlobalKey<FavoritesScreenState> _favKey =
      GlobalKey<FavoritesScreenState>();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _web = _buildController();
  }

  WebViewController _buildController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);

    // إعدادات أندرويد: الموقع + أذونات الوسائط
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          final status = await Permission.location.request();
          return GeolocationPermissionsResponse(
              allow: status.isGranted, retain: false);
        },
      );
      android.setOnPlatformPermissionRequest((request) async {
        await Permission.camera.request();
        await Permission.microphone.request();
        request.grant();
      });
    }
    return controller;
  }

  void _openInWeb(String url) {
    _web.loadRequest(Uri.parse(url));
    setState(() => _index = 0);
  }

  void _onTab(int i) {
    setState(() => _index = i);
    if (i == 1) _favKey.currentState?.refresh(); // حدّث المفضّلة عند الدخول
  }

  Future<void> _onBack(bool didPop) async {
    if (didPop) return;
    if (_index != 0) {
      setState(() => _index = 0); // أي تبويب آخر → ارجع للرئيسية
      return;
    }
    if (await _web.canGoBack()) {
      await _web.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              WebScreen(controller: _web),
              FavoritesScreen(key: _favKey, onOpen: _openInWeb),
              const MoreScreen(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTab,
          backgroundColor: Colors.white,
          indicatorColor: kPrimary.withValues(alpha: 0.12),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: kPrimary),
                label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.bookmark_border),
                selectedIcon: Icon(Icons.bookmark, color: kPrimary),
                label: 'المفضّلة'),
            NavigationDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz, color: kPrimary),
                label: 'المزيد'),
          ],
        ),
      ),
    );
  }
}
