import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/save_pro.dart';
import '../services/llm_service.dart';
import '../services/storage_ser.dart';
import '../widget/motion.dart';
import 'result_sc.dart';
import '../theme_controller.dart';

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
  String _language = 'english';
  String _workType = 'auto';

  static const _details = {
    'short': 'Short',
    'medium': 'Medium',
    'detailed': 'Detailed',
  };
  static const _languages = {
    'english': 'English',
    'match': 'Same as brief',
  };
  static const _workTypes = {
    'auto': 'Auto-detect',
    'full_project': 'Full project',
    'module': 'One module',
    'design': 'UI/UX design',
    'testing': 'Testing / QA',
    'fix': 'Bug fix',
  };

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
      final proposal =
      await _service.generateProposal(brief, _detail, _language, _workType);

      String? savedId;
      try {
        final id = DateTime.now().microsecondsSinceEpoch.toString();
        await StorageService().save(SavedProposal(
          id: id,
          createdAt: DateTime.now(),
          brief: brief,
          proposal: proposal,
          detail: _detail,
        ));
        savedId = id;
      } catch (e) {
        debugPrint('Could not save to history: $e');
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(proposal: proposal, savedId: savedId),
        ),
      );
    } on NotABriefException catch (e) {
      _showError(e.message.isEmpty
          ? "That doesn't look like a project brief."
          : e.message);
    } on TimeoutException {
      _showError('The AI took too long to respond. Please try again.');
    } on http.ClientException {
      _showError('Network problem. Check your internet connection and try again.');
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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // A small labelled group of chips.
  Widget _group(
      String title,
      Map<String, String> options,
      String selected,
      ValueChanged<String> onPick,
      ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.entries
              .map(
                (e) => ChoiceChip(
              label: Text(e.value),
              selected: selected == e.key,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              shape: const StadiumBorder(),
              onSelected: _loading ? null : (_) => onPick(e.key),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New proposal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        actions: const [ThemeMenuButton(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                FadeSlide(
                  child: Text(
                    'Paste the client brief',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A WhatsApp message, email or notes. Messy is fine.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 14),

                // The main thing: a big, soft text box.
                FadeSlide(
                  index: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor(context),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 8,
                      maxLines: 14,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(18),
                        hintText: 'e.g. I need an app for my salon with booking...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // The options: small chips.
                FadeSlide(
                  index: 2,
                  child: _group('Detail', _details, _detail,
                          (v) => setState(() => _detail = v)),
                ),
                const SizedBox(height: 14),
                FadeSlide(
                  index: 3,
                  child: _group('Proposal language', _languages, _language,
                          (v) => setState(() => _language = v)),
                ),
                const SizedBox(height: 14),
                FadeSlide(
                  index: 4,
                  child: _group('Type of work', _workTypes, _workType,
                          (v) => setState(() => _workType = v)),
                ),
                const SizedBox(height: 24),

                // The main button.
                Bouncy(
                  child: FilledButton(
                    onPressed: _loading ? null : _generate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _loading
                          ? const Row(
                        key: ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Flexible(
                            child: Text('Analyzing… can take up to a minute'),
                          ),
                        ],
                      )
                          : const Row(
                        key: ValueKey('idle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text('Generate proposal'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}