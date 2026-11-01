import 'package:flutter/material.dart';
import '../services/llm_service.dart';
import 'result_sc.dart';
import 'dart:async';
import '../models/save_pro.dart';
import '../services/storage_ser.dart';
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _controller = TextEditingController();
  final _service = LlmService();
  bool _loading = false;
  String _detail = 'medium';

  Future<void> _generate() async {
    final brief = _controller.text.trim();
    if (brief.isEmpty) {
      _showError('Please paste a client brief first.');
      return;
    }
    if (brief.length > 8000) {
      _showError('Brief is too long. Keep it under 8000 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      final proposal = await _service.generateProposal(brief, _detail);
      try {
        await StorageService().save(SavedProposal(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          createdAt: DateTime.now(),
          brief: brief,
          proposal: proposal,
          detail: _detail,
        ));
      } catch (e) {
        debugPrint('Could not save to history: $e'); // never block showing the result
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(proposal: proposal)),
      );
    } on NotABriefException catch (e) {
      _showError(e.message.isEmpty
          ? "That doesn't look like a project brief."
          : e.message);
    } on TimeoutException {
      _showError('The AI took too long to respond. Please try again.');
    } on ApiException catch (e) {
      if (e.statusCode == 503) {
        _showError('The AI service is busy right now. Please try again in a minute.');
      } else if (e.statusCode == 429) {
        _showError('Free usage limit reached. Please wait a minute and try again.');
      } else {
        _showError('AI service error (${e.statusCode}). Check your API key and model name.');
      }
    } catch (e) {
      _showError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    debugPrint('UI ERROR: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Proposal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste the client brief (WhatsApp message, email, notes):',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. I need an app for my salon with booking...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'short', label: Text('Short')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'detailed', label: Text('Detailed')),
              ],
              selected: {_detail},
              onSelectionChanged: (s) => setState(() => _detail = s.first),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Analyzing brief… this can take up to a minute', style: TextStyle(fontSize: 12)),
                  ],
                )
                    : const Text('Generate Proposal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}