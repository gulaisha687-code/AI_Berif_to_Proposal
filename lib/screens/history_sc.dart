import 'package:flutter/material.dart';
import '../models/save_pro.dart';
import '../services/storage_ser.dart';
import '../widget/motion.dart';
import 'result_sc.dart';
import '../theme_controller.dart';

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

  Widget _pill(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = _items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: const [ThemeMenuButton(), SizedBox(width: 4)],
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              'No saved proposals yet',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      )
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return FadeSlide(
                index: i,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(color: cardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            proposal: p.proposal,
                            savedId: p.id,
                          ),
                        ),
                      ).then((_) => _load()),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.proposal.projectTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _pill(context,
                                          '${p.proposal.totalHours.toStringAsFixed(0)} h'),
                                      if (p.detail.isNotEmpty)
                                        _pill(context, p.detail),
                                      if (p.proposal.workType.isNotEmpty)
                                        _pill(
                                          context,
                                          p.proposal.workType
                                              .replaceAll('_', ' '),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _date(p.createdAt),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                        color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(p),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}