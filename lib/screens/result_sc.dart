import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/proposel.dart';
import '../services/pdf_ser.dart';
import '../services/storage_ser.dart';
import '../theme_controller.dart';
import '../widget/motion.dart';

class ResultScreen extends StatefulWidget {
  final Proposal proposal;

  // The id of the saved history item. When set, edits are saved back to it.
  final String? savedId;

  const ResultScreen({super.key, required this.proposal, this.savedId});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _rateController = TextEditingController();
  late final TextEditingController _paceController;
  String _currency = r'$';

  // Used to rescale the timeline when the hours change.
  late List<Milestone> _ms;
  late List<int> _baseWeeks;
  late double _baseHours;
  late double _basePace; // hours per week implied by the original plan
  double? _paceOverride; // set when the user types their own pace

  Proposal get proposal => widget.proposal;

  double? get _rate => double.tryParse(_rateController.text.trim());

  double get _pace => _paceOverride ?? _basePace;

  String get _text =>
      proposal.toPlainText(hourlyRate: _rate, currency: _currency);

  @override
  void initState() {
    super.initState();
    _ms = proposal.sortedMilestones;
    _baseWeeks = _ms.map((m) => m.week).toList();
    _baseHours = proposal.totalHours;
    final lastWeek = _ms.isEmpty ? 1 : max(1, _baseWeeks.last);
    _basePace = _baseHours > 0 ? _baseHours / lastWeek : 20;
    _paceController =
        TextEditingController(text: _basePace.round().toString());
  }

  @override
  void dispose() {
    _rateController.dispose();
    _paceController.dispose();
    super.dispose();
  }

  String _fmt(double h) =>
      h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

  // Recalculates milestone weeks from the current total hours and pace.
  void _applyWeeks() {
    if (_ms.isEmpty || _baseHours <= 0) return;
    final scale = (proposal.totalHours / _baseHours) * (_basePace / _pace);
    for (var k = 0; k < _ms.length; k++) {
      _ms[k].week = max(1, (_baseWeeks[k] * scale).round());
    }
  }

  // Saves the edited proposal back to History.
  void _persist() {
    final id = widget.savedId;
    if (id == null) return;
    StorageService().updateProposal(id, proposal).catchError((e) {
      debugPrint('Could not save edits: $e');
    });
  }

  void _setHours(TaskItem t, double value) {
    setState(() {
      t.hours = value.clamp(0.0, 1000.0).toDouble();
      _applyWeeks();
    });
    _persist();
  }

  Future<void> _typeHours(TaskItem t) async {
    final controller = TextEditingController(text: _fmt(t.hours));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Hours',
            suffixText: 'h',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(controller.text.trim().replaceAll(',', '.')),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) _setHours(t, result);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    _snack('Copied. Paste it into your proposal.');
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(ShareParams(text: _text));
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  Future<void> _exportPdf() async {
    // Urdu script cannot be drawn in the PDF yet, so tell the user.
    final hasUrduScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F]')
        .hasMatch(proposal.toPlainText());
    if (hasUrduScript) {
      _snack('PDF export supports English and Roman Urdu. '
          'For Urdu script, use Copy or Share.');
      return;
    }
    try {
      final bytes = await PdfService().build(
        proposal,
        hourlyRate: _rate,
        currency: _currency,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'proposal.pdf');
    } catch (e) {
      _snack('Could not create the PDF: $e');
    }
  }

  // A soft card that works in light and dark mode.
  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor(context),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  // A small pill shown on the gradient header.
  Widget _headerPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x2EFFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
      ),
    );
  }

  // The − [hours] + control on each task.
  Widget _hoursEditor(TaskItem t) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(Icons.remove, () => _setHours(t, t.hours - 1)),
          InkWell(
            onTap: () => _typeHours(t),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                '${_fmt(t.hours)} h',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ),
          _stepButton(Icons.add, () => _setHours(t, t.hours + 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    var i = 0; // used to stagger the animations

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proposal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Copy as text',
            icon: const Icon(Icons.copy),
            onPressed: _copy,
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                // Header
                FadeSlide(
                  index: i++,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.projectTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          proposal.summary,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xE6FFFFFF),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (proposal.workType.isNotEmpty)
                              _headerPill(
                                Icons.category_outlined,
                                proposal.workType.replaceAll('_', ' '),
                              ),
                            _headerPill(
                              Icons.schedule,
                              '${_fmt(proposal.totalHours)} hours',
                            ),
                            if (_ms.isNotEmpty)
                              _headerPill(
                                Icons.calendar_today_outlined,
                                '${_ms.last.week} weeks',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tasks
                _heading('Tasks'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Tap − / + or the number to edit hours. '
                        'The total, price and timeline update automatically.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                ...proposal.tasks.map(
                      (t) => FadeSlide(
                    index: i++,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _card(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (t.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      t.description,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _hoursEditor(t),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Estimate and price
                FadeSlide(
                  index: i++,
                  child: _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total estimate',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${_fmt(proposal.totalHours)} hours',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rateController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Your hourly rate',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<String>(
                              value: _currency,
                              underline: const SizedBox.shrink(),
                              items: const [
                                DropdownMenuItem(value: r'$', child: Text(r'$')),
                                DropdownMenuItem(value: 'Rs ', child: Text('Rs')),
                                DropdownMenuItem(value: '€', child: Text('€')),
                                DropdownMenuItem(value: '£', child: Text('£')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _currency = v ?? r'$'),
                            ),
                          ],
                        ),
                        if (_rate != null && _rate! > 0) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Estimated price: $_currency${(proposal.totalHours * _rate!).toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Timeline
                if (_ms.isNotEmpty) ...[
                  _heading('Timeline'),
                  FadeSlide(
                    index: i++,
                    child: _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _paceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Hours you work per week',
                              helperText:
                              'Weeks follow your hours and this pace.',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onChanged: (v) {
                              final p = double.tryParse(v.trim());
                              setState(() {
                                _paceOverride = (p != null && p > 0) ? p : null;
                                _applyWeeks();
                              });
                              _persist();
                            },
                          ),
                          const SizedBox(height: 16),
                          for (var k = 0; k < _ms.length; k++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: k == _ms.length - 1 ? 0 : 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: cs.primaryContainer,
                                    child: Text(
                                      '${k + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _ms[k].name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Week ${_ms[k].week}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Assumptions
                if (proposal.assumptions.isNotEmpty) ...[
                  _heading('Assumptions'),
                  FadeSlide(
                    index: i++,
                    child: _card(
                      Column(
                        children: proposal.assumptions
                            .map(
                              (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 18, color: cs.primary),
                                const SizedBox(width: 10),
                                Expanded(child: Text(a)),
                              ],
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ],

                // Questions
                if (proposal.questionsForClient.isNotEmpty) ...[
                  _heading('Questions for the client'),
                  FadeSlide(
                    index: i++,
                    child: _card(
                      Column(
                        children: proposal.questionsForClient
                            .map(
                              (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.help_outline,
                                    size: 18, color: cs.tertiary),
                                const SizedBox(width: 10),
                                Expanded(child: Text(q)),
                              ],
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}