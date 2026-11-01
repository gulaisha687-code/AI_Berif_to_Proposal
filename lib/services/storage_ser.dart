import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/save_pro.dart';

class StorageService {
  static const _key = 'saved_proposals';

  Future<List<SavedProposal>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = <SavedProposal>[];
    for (final s in raw) {
      try {
        items.add(SavedProposal.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Skip any corrupted entry instead of crashing the whole screen.
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
    return items;
  }

  Future<void> save(SavedProposal item) async {
    final items = await loadAll();
    items.add(item);
    await _writeAll(items);
  }

  Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((p) => p.id == id);
    await _writeAll(items);
  }

  Future<void> _writeAll(List<SavedProposal> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      items.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }
}