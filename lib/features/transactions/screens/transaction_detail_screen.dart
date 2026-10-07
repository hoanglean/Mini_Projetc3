import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../domain/entities/category.dart';
import '../../../../core/utils/vnd_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../providers/transaction_provider.dart';

/// Screen showing full details of a transaction with edit and delete capabilities.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  late TransactionModel _currentTx;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late Category _selectedCategory;

  @override
  void initState() {
    super.initState();
    _currentTx = widget.transaction;
    _initEditFields();
  }

  void _initEditFields() {
    _merchantController =
        TextEditingController(text: _currentTx.merchant);
    _amountController =
        TextEditingController(text: _currentTx.amount.toStringAsFixed(0));
    _selectedDate = _currentTx.date;
    _selectedCategory = _currentTx.category;
  }

  @override
  void dispose() {
    _merchantController.disposeValidate();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'[,.\s]'), '')) ??
            _currentTx.amount;

    final updated = _currentTx.copyWith(
      merchant: _merchantController.text.trim(),
      amount: parsedAmount,
      date: _selectedDate,
      category: _selectedCategory,
    );

    await ref.read(transactionListProvider.notifier).updateTransaction(updated);

    setState(() {
      _currentTx = updated;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(transactionListProvider.notifier)
          .deleteTransaction(_currentTx.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = _currentTx.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Expense Details'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                _initEditFields();
                setState(() => _isEditing = false);
              },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saveChanges,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing ? _buildEditForm(theme) : _buildViewMode(theme, category),
      ),
    );
  }

  Widget _buildViewMode(ThemeData theme, Category category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Amount Banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                category.color.withAlpha(40),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: category.color.withAlpha(50),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.color.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                _currentTx.merchant.isNotEmpty
                    ? _currentTx.merchant
                    : 'Receipt Expense',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                VndFormatter.format(_currentTx.amount),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: category.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.displayName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: category.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Information Details Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  theme,
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: DateUtilsFormat.formatDisplay(_currentTx.date),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  theme,
                  icon: Icons.access_time_outlined,
                  label: 'Created At',
                  value: DateUtilsFormat.formatWithTime(_currentTx.createdAt),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  theme,
                  icon: Icons.fingerprint,
                  label: 'Reference ID',
                  value: _currentTx.id.length > 12
                      ? _currentTx.id.substring(0, 12)
                      : _currentTx.id,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Receipt Image Preview (if available)
        if (_currentTx.imagePath != null &&
            File(_currentTx.imagePath!).existsSync()) ...[
          Text(
            'Receipt Photo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_currentTx.imagePath!)),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton.filled(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),
                ),
                child: Image.file(
                  File(_currentTx.imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: 'Merchant Name',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Merchant cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (VND)',
              prefixIcon: Icon(Icons.payments_outlined),
              suffixText: 'đ',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Amount required';
              final amt = double.tryParse(v.replaceAll(RegExp(r'[,.\s]'), ''));
              if (amt == null || amt <= 0) return 'Enter a valid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Transaction Date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                DateUtilsFormat.formatDisplay(_selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(
                _selectedCategory.icon,
                color: _selectedCategory.color,
              ),
            ),
            items: Category.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 20),
                    const SizedBox(width: 8),
                    Text(cat.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (cat) {
              if (cat != null) setState(() => _selectedCategory = cat);
            },
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

extension on TextEditingController {
  void disposeValidate() {
    dispose();
  }
}
