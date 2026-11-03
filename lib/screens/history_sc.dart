import 'package:flutter/material.dart';
import '../models/save_pro.dart';
import '../services/storage_ser.dart';
import '../theme_controller.dart';
import '../widget/account_button.dart';
import '../widget/motion.dart';
import '../widget/toast.dart';
import 'result_sc.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = StorageService();
  final _searchController = TextEditingController();
  List<SavedProposal>? _items; // null means still loading
  String _query = '';
  String _filter = 'all';

  static const _filters = {
    'all': 'All',
    'full_project': 'Full project',
    'module': 'Module',
    'design': 'UI/UX design',
    'testing': 'Testing / QA',
    'fix': 'Bug fix',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.loadAll();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _delete(SavedProposal p) async {
    await _storage.delete(p.id);
    await _load();
    if (mounted) {
      AppToast.show(context, 'Proposal deleted', type: ToastType.info);
    }
  }

  String _date(DateTime d) => d.toLocal().toString().substring(0, 16);

  List<SavedProposal> _visible(List<SavedProposal> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_filter != 'all' && p.proposal.workType != _filter) return false;
      if (q.isEmpty) return true;
      final text = '${p.proposal.projectTitle} ${p.proposal.summary} '
          '${p.proposal.workType} ${p.detail} ${_date(p.createdAt)}'
          .toLowerCase();
      return text.contains(q);
    }).toList();
  }

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

  Widget _empty(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, SavedProposal p) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
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
      child: Material(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(proposal: p.proposal, savedId: p.id),
            ),
          ).then((_) => _load()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.proposal.projectTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (p.proposal.summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.proposal.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _pill(context,
                              '${p.proposal.totalHours.toStringAsFixed(0)} h'),
                          if (p.detail.isNotEmpty) _pill(context, p.detail),
                          if (p.proposal.workType.isNotEmpty)
                            _pill(context,
                                p.proposal.workType.replaceAll('_', ' ')),
                          Text(
                            _date(p.createdAt),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final all = _items;
    final visible = all == null ? <SavedProposal>[] : _visible(all);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: const [AccountButton(), ThemeMenuButton(), SizedBox(width: 4)],
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by title, type or date',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
                    filled: true,
                    fillColor: cardColor(context),
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _filters.entries
                      .map(
                        (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value,
                            style: const TextStyle(fontSize: 12)),
                        selected: _filter == e.key,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        shape: const StadiumBorder(),
                        onSelected: (_) =>
                            setState(() => _filter = e.key),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),

              // Count
              if (all.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 20, 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${visible.length} of ${all.length} proposals',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),

              // List
              Expanded(
                child: all.isEmpty
                    ? _empty(context, Icons.history,
                    'No saved proposals yet')
                    : visible.isEmpty
                    ? _empty(context, Icons.search_off,
                    'No proposals match your search')
                    : ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => FadeSlide(
                    index: i,
                    child: _card(context, visible[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}