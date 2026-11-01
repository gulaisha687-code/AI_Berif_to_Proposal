import 'package:flutter/material.dart';
import '../models/proposel.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
class ResultScreen extends StatefulWidget {
  final Proposal proposal;

  const ResultScreen({super.key, required this.proposal});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}
class _ResultScreenState extends State<ResultScreen> {
  final _rateController = TextEditingController();

  Proposal get proposal => widget.proposal;

  double? get _rate => double.tryParse(_rateController.text.trim());

  String get _text => proposal.toPlainText(hourlyRate: _rate);

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }
  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposal'),
        actions: [
          IconButton(
            tooltip: 'Copy as text',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied. Paste it into your proposal.')),
              );
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(_text),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            proposal.projectTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(proposal.summary),

          _heading(context, 'Tasks'),
          ...proposal.tasks.map(
                (t) => Card(
              child: ListTile(
                title: Text(t.name),
                subtitle: Text(t.description),
                trailing: Text('${t.hours.toStringAsFixed(1)} h'),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: ${proposal.totalHours.toStringAsFixed(1)} hours',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Your hourly rate',
              border: OutlineInputBorder(),
            ),
          ),
          if (_rate != null && _rate! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Estimated price: ${(proposal.totalHours * _rate!).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

          if (proposal.milestones.isNotEmpty) ...[
            _heading(context, 'Milestones'),
            ...proposal.sortedMilestones.asMap().entries.map(
                  (e) => ListTile(
                leading: CircleAvatar(child: Text('${e.key + 1}')),
                title: Text(e.value.name),
                subtitle: Text('Week ${e.value.week}'),
              ),
            ),
          ],

          if (proposal.assumptions.isNotEmpty) ...[
            _heading(context, 'Assumptions'),
            ...proposal.assumptions.map((a) => Text('• $a')),
          ],

          if (proposal.questionsForClient.isNotEmpty) ...[
            _heading(context, 'Questions for the client'),
            ...proposal.questionsForClient.map((q) => Text('• $q')),
          ],
        ],
      ),
    );
  }
}