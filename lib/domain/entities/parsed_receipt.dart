/// Result of parsing a receipt image via OCR + regex heuristics.
class ParsedReceipt {
  /// The extracted total amount in VND (e.g. 150000.0 for 150,000 VND).
  final double? totalAmount;

  /// The merchant / store name extracted from the receipt header.
  final String? merchantName;

  /// The transaction date parsed from the receipt.
  final DateTime? date;

  /// Confidence score from 0.0 (low) to 1.0 (high) indicating how
  /// reliable the extraction is.
  final double confidence;

  /// All raw text lines returned by the OCR engine, for debugging.
  final List<String> rawLines;

  /// How long the OCR engine took in milliseconds.
  final int ocrDurationMs;

  const ParsedReceipt({
    this.totalAmount,
    this.merchantName,
    this.date,
    this.confidence = 0.0,
    this.rawLines = const [],
    this.ocrDurationMs = 0,
  });

  ParsedReceipt copyWith({
    double? totalAmount,
    String? merchantName,
    DateTime? date,
    double? confidence,
    List<String>? rawLines,
    int? ocrDurationMs,
  }) {
    return ParsedReceipt(
      totalAmount: totalAmount ?? this.totalAmount,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      confidence: confidence ?? this.confidence,
      rawLines: rawLines ?? this.rawLines,
      ocrDurationMs: ocrDurationMs ?? this.ocrDurationMs,
    );
  }

  @override
  String toString() =>
      'ParsedReceipt(total: $totalAmount, merchant: $merchantName, '
      'date: $date, confidence: $confidence, lines: ${rawLines.length})';
}
