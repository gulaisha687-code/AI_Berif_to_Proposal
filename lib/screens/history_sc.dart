import 'package:flutter/material.dart';
import '../models/save_pro.dart';
import '../services/storage_ser.dart';
import 'result_sc.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  List<SavedProposal>? _items; // null means still loading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.loadAll();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _delete(SavedProposal p) async {
    await _storage.delete(p.id);
    await _load();
  }

  String _date(DateTime d) => d.toLocal().toString().substring(0, 16);

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? const Center(child: Text('No saved proposals yet.'))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final p = items[i];
          return ListTile(
            title: Text(
              p.proposal.projectTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_date(p.createdAt)}  •  '
                  '${p.detail.isEmpty ? '' : '${p.detail}  •  '}'
                  '${p.proposal.totalHours.toStringAsFixed(0)} h',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(p),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResultScreen(proposal: p.proposal),
              ),
            ),
          );
        },
      ),
    );
  }
}