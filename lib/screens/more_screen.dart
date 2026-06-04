import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

/// تبويب «المزيد»: شاشة أصلية فيها مشاركة، تقييم، تواصل، خصوصية.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _rate() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/id$kStoreIdIOS'
        : 'https://play.google.com/store/apps/details?id=$kPackageAndroid';
    await _open(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title:
            const Text('المزيد', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.share, color: kPrimary),
            title: const Text('مشاركة التطبيق'),
            onTap: () => Share.share(
              'حمّل تطبيق دليلك — كل محل أقرب إلك:\n$kUrl',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star_rate, color: kPrimary),
            title: const Text('قيّم التطبيق'),
            onTap: _rate,
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: kPrimary),
            title: const Text('تواصل معنا'),
            onTap: () =>
                _open('https://wa.me/${kContactPhone.replaceAll('+', '')}'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: kPrimary),
            title: const Text('سياسة الخصوصية'),
            onTap: () => _open(kPrivacyUrl),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('دليلك • الإصدار 1.0.0',
                  style: TextStyle(color: kTextMuted)),
            ),
          ),
        ],
      ),
    );
  }
}
