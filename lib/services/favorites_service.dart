import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// عنصر مفضّلة (صفحة محفوظة محلياً).
class FavItem {
  FavItem({required this.title, required this.url});

  final String title;
  final String url;

  Map<String, dynamic> toJson() => {'title': title, 'url': url};

  factory FavItem.fromJson(Map<String, dynamic> j) =>
      FavItem(title: (j['title'] ?? '') as String, url: j['url'] as String);
}

/// تخزين المفضّلة محلياً عبر SharedPreferences (ميزة أصلية تعمل دون إنترنت).
class FavoritesService {
  FavoritesService._();

  static const String _key = 'favorites';

  static Future<List<FavItem>> all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((e) => FavItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  /// يضيف عنصراً (يتجاهل التكرار حسب الرابط) ويعيد true إن أُضيف فعلاً.
  static Future<bool> add(FavItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    final exists = list.any((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return m['url'] == item.url;
    });
    if (exists) return false;
    list.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, list);
    return true;
  }

  static Future<void> removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      await prefs.setStringList(_key, list);
    }
  }
}
