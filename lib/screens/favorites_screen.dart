import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/favorites_service.dart';

/// تبويب المفضّلة: شاشة أصلية بالكامل تعرض الصفحات المحفوظة محلياً.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpen});

  /// يُستدعى عند اختيار عنصر لفتحه في تبويب الموقع.
  final void Function(String url) onOpen;

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  List<FavItem> _items = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final items = await FavoritesService.all();
    if (mounted) setState(() {
          _items = items;
          _loaded = true;
        });
  }

  Future<void> _remove(int index) async {
    await FavoritesService.removeAt(index);
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: const Text('المفضّلة',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _items.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: kPrimary,
                          child: Icon(Icons.bookmark, color: Colors.white),
                        ),
                        title: Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kTextMuted)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _remove(i),
                        ),
                        onTap: () => widget.onOpen(item.url),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 72, color: kTextMuted),
          SizedBox(height: 16),
          Text('لا توجد عناصر في المفضّلة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextDark)),
          SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: Text(
              'افتح صفحة من تبويب «الرئيسية» واضغط زر الحفظ ⭐ لإضافتها هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMuted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
