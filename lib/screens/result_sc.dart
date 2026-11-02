import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/proposel.dart';
import '../services/pdf_ser.dart';
import '../widget/motion.dart';

class ResultScreen extends StatefulWidget {
  final Proposal proposal;

  const ResultScreen({super.key, required this.proposal});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _rateController = TextEditingController();
  String _currency = r'$';

  Proposal get proposal => widget.proposal;

  double? get _rate => double.tryParse(_rateController.text.trim());

  String get _text =>
      proposal.toPlainText(hourlyRate: _rate, currency: _currency);

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
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

  // A soft white card.
  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final milestones = proposal.sortedMilestones;
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
                              '${proposal.totalHours.toStringAsFixed(0)} hours',
                            ),
                            if (milestones.isNotEmpty)
                              _headerPill(
                                Icons.calendar_today_outlined,
                                '${milestones.last.week} weeks',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Tasks
                _heading('Tasks'),
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
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${t.hours.toStringAsFixed(0)} h',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
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
                              '${proposal.totalHours.toStringAsFixed(0)} hours',
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
                if (milestones.isNotEmpty) ...[
                  _heading('Timeline'),
                  FadeSlide(
                    index: i++,
                    child: _card(
                      Column(
                        children: [
                          for (var k = 0; k < milestones.length; k++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: k == milestones.length - 1 ? 0 : 14,
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
                                          milestones[k].name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Week ${milestones[k].week}',
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