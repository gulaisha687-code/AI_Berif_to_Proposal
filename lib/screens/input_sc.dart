import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/save_pro.dart';
import '../services/llm_service.dart';
import '../services/storage_ser.dart';
import '../theme_controller.dart';
import '../widget/account_button.dart';
import '../widget/motion.dart';
import '../widget/toast.dart';
import 'result_sc.dart';

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

  static const _examples = {
    'Mobile login QA':
    'Need comprehensive testing of login functionality including positive '
        'and negative scenarios, session management and password reset flows '
        'for a mobile app.',
    'Salon booking app':
    'I want an app for my salon where customers can book appointments, get '
        'reminders on WhatsApp, and staff can see their daily schedule. '
        'Budget is small and I need it in one month.',
    'Photo upload crash':
    'Our app crashes when users upload a profile photo. Please fix it.',
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
    AppToast.show(
      context,
      message,
      type: ToastType.error,
      duration: const Duration(seconds: 5),
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
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: options.entries
              .map(
                (e) => ChoiceChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
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
        actions: const [AccountButton(), ThemeMenuButton(), SizedBox(width: 4)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                FadeSlide(
                  child: Text(
                    'Turn a client brief into a proposal',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A WhatsApp message, email or notes. Messy is fine.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                // The main thing: a soft text box.
                FadeSlide(
                  index: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor(context),
                      borderRadius: BorderRadius.circular(20),
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
                      minLines: 6,
                      maxLines: 10,
                      maxLength: 8000,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        hintText: 'e.g. I need an app for my salon with booking...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick examples
                FadeSlide(
                  index: 2,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Try:',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      ..._examples.entries.map(
                            (e) => ActionChip(
                          avatar: const Icon(Icons.bolt, size: 14),
                          label: Text(e.key, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                          onPressed: _loading
                              ? null
                              : () => setState(() => _controller.text = e.value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Options card
                FadeSlide(
                  index: 3,
                  child: Container(
                    padding: const EdgeInsets.all(14),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _group('Detail level', _details, _detail,
                                (v) => setState(() => _detail = v)),
                        const SizedBox(height: 12),
                        _group('Proposal language', _languages, _language,
                                (v) => setState(() => _language = v)),
                        const SizedBox(height: 12),
                        _group('Type of work', _workTypes, _workType,
                                (v) => setState(() => _workType = v)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // The main button.
                Bouncy(
                  child: FilledButton(
                    onPressed: _loading ? null : _generate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 15.5,
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