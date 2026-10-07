import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/parser/receipt_parser.dart';
import '../../../domain/entities/parsed_receipt.dart';
import '../../../domain/entities/category.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/image_storage_service.dart';
import '../../../core/utils/vnd_formatter.dart';
import '../../transactions/providers/transaction_provider.dart';

/// Screen to review OCR results and edit before saving.
class ReviewScreen extends ConsumerStatefulWidget {
  final File imageFile;

  const ReviewScreen({super.key, required this.imageFile});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  final _parser = ReceiptParser();
  final _imageService = ImageStorageService();

  DateTime _selectedDate = DateTime.now();
  Category _selectedCategory = Category.other;
  ParsedReceipt? _parsedReceipt;
  bool _isProcessing = true;
  bool _isSaving = false;
  String? _ocrError;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _runOcr() async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(widget.imageFile);
      final stopwatch = Stopwatch()..start();

      final recognized = await recognizer.processImage(inputImage);

      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      debugPrint('OCR completed in ${duration}ms');

      // Extract lines
      final lines = <String>[];
      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }

      debugPrint('OCR lines: ${lines.length}');
      for (final line in lines) {
        debugPrint('  > $line');
      }

      // Parse
      final result = _parser.parse(lines);
      final receipt = result.copyWith(ocrDurationMs: duration);

      if (mounted) {
        setState(() {
          _parsedReceipt = receipt;
          _isProcessing = false;

          if (receipt.totalAmount != null) {
            _amountController.text = receipt.totalAmount!.round().toString();
          }
          if (receipt.merchantName != null) {
            _merchantController.text = receipt.merchantName!;
          }
          if (receipt.date != null) {
            _selectedDate = receipt.date!;
          }
        });
      }
    } catch (e) {
      debugPrint('OCR error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _ocrError = e.toString();
        });
      }
    } finally {
      await recognizer.close();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final id = const Uuid().v4();
      final amount = int.tryParse(_amountController.text) ?? 0;

      // Save images
      final paths = await _imageService.saveReceiptImage(
        widget.imageFile,
        id,
      );

      final transaction = TransactionModel(
        id: id,
        amount: amount,
        merchant: _merchantController.text.trim(),
        date: _selectedDate,
        category: _selectedCategory,
        note: _noteController.text.trim(),
        imagePath: paths.imagePath,
        thumbnailPath: paths.thumbnailPath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(transactionListProvider.notifier)
          .addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved: ${VndFormatter.format(amount)} at ${_merchantController.text}'),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to the home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          if (_parsedReceipt != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'Confidence: ${(_parsedReceipt!.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _parsedReceipt!.confidence >= 0.5
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                backgroundColor: _parsedReceipt!.confidence >= 0.5
                    ? Colors.green.withAlpha(30)
                    : Colors.orange.withAlpha(30),
              ),
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing receipt...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.imageFile,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    if (_ocrError != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: theme.colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'OCR Error: $_ocrError',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_parsedReceipt != null &&
                        _parsedReceipt!.ocrDurationMs > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'OCR: ${_parsedReceipt!.ocrDurationMs}ms • ${_parsedReceipt!.rawLines.length} lines detected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Amount field
                    _buildField(
                      label: 'Amount (VND)',
                      controller: _amountController,
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      isLowConfidence:
                          _parsedReceipt?.totalAmount == null,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Amount is required';
                        }
                        final amount = int.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Merchant field
                    _buildField(
                      label: 'Merchant / Store',
                      controller: _merchantController,
                      icon: Icons.store,
                      isLowConfidence:
                          _parsedReceipt?.merchantName == null,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Merchant name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: _parsedReceipt?.date == null
                                ? Colors.orange
                                : null,
                          ),
                          suffixIcon:
                              const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          _selectedCategory.icon,
                          color: _selectedCategory.color,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Category.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.icon,
                                  size: 20, color: cat.color),
                              const SizedBox(width: 8),
                              Text(cat.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (cat) {
                        if (cat != null) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Note field
                    _buildField(
                      label: 'Note (optional)',
                      controller: _noteController,
                      icon: Icons.note,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Retake'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                                _isSaving ? 'Saving...' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool isLowConfidence = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isLowConfidence ? Colors.orange : null,
        ),
        suffixIcon: isLowConfidence
            ? const Tooltip(
                message: 'Low confidence — please verify',
                child: Icon(Icons.warning_amber, color: Colors.orange),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
