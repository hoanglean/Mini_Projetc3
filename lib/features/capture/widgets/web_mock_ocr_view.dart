import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/ocr/sample_receipts.dart';
import '../../review/screens/review_screen.dart';

/// Web simulator for receipt scanning allowing users to select sample
/// Vietnamese receipts or paste custom receipt text to test the heuristic parser.
class WebMockOcrView extends StatefulWidget {
  const WebMockOcrView({super.key});

  @override
  State<WebMockOcrView> createState() => _WebMockOcrViewState();
}

class _WebMockOcrViewState extends State<WebMockOcrView> {
  late final TextEditingController _textController;
  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: SampleReceipts.presets.first.rawText.trim(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _selectPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      _textController.text = SampleReceipts.presets[index].rawText.trim();
    });
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _selectedPresetIndex = -1;
        _textController.text = data.text!.trim();
      });
    }
  }

  void _processReceipt() {
    final rawText = _textController.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste receipt text')),
      );
      return;
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScreen(initialLines: lines),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt OCR Simulator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Web UI Demo Mode',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select a sample Vietnamese receipt or paste your own invoice text to run the on-device ReceiptParser.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withAlpha(220),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preset Chips
            Text(
              'Sample Vietnamese Receipts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(SampleReceipts.presets.length, (i) {
                final preset = SampleReceipts.presets[i];
                final isSelected = _selectedPresetIndex == i;
                return ChoiceChip(
                  label: Text(preset.title),
                  selected: isSelected,
                  onSelected: (_) => _selectPreset(i),
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Editor Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Receipt Raw Text',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pasteClipboard,
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: const Text('Paste'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPresetIndex = -1;
                          _textController.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Raw Text Card / Input
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 12,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter or paste receipt text here...',
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Run OCR / Parse button
            FilledButton.icon(
              onPressed: _processReceipt,
              icon: const Icon(Icons.document_scanner),
              label: const Text(
                'Run Receipt Parser & Review',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
