import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../core/utils/vnd_formatter.dart';
import '../../../../core/utils/date_utils.dart';

/// Reusable list tile displaying a single transaction with category icon,
/// merchant name, date, thumbnail preview, and formatted amount.
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = transaction.category;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Category icon badge or thumbnail
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: !kIsWeb &&
                        transaction.imagePath != null &&
                        transaction.imagePath!.isNotEmpty &&
                        File(transaction.imagePath!).existsSync()
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(transaction.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              category.icon,
                              color: category.color,
                              size: 24,
                            ),
                          ),
                          Container(
                            color: Colors.black.withAlpha(40),
                          ),
                          Center(
                            child: Icon(
                              category.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        category.icon,
                        color: category.color,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),

              // Merchant and date / category chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchant.isNotEmpty
                          ? transaction.merchant
                          : 'Receipt Expense',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          DateUtilsFormat.formatDisplay(transaction.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: category.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Formatted VND Amount
              Text(
                VndFormatter.format(transaction.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
