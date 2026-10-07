import '../entities/parsed_receipt.dart';

/// Pure-Dart receipt parser that extracts structured data from raw OCR lines.
///
/// Supports Vietnamese receipt formats (VND currency, Vietnamese keywords)
/// and common English receipt formats. Fully unit-testable with no Flutter
/// dependencies.
class ReceiptParser {
  // ─── Total-amount keywords (case/diacritic-insensitive) ────────────
  static const _totalKeywords = [
    'TONG CONG',
    'TỔNG CỘNG',
    'TỔNG TIỀN',
    'TONG TIEN',
    'THANH TOÁN',
    'THANH TOAN',
    'THÀNH TIỀN',
    'THANH TIEN',
    'TOTAL',
    'AMOUNT DUE',
    'GRAND TOTAL',
    'NET TOTAL',
  ];

  // ─── Known Vietnamese chain names (sorted by length descending) ───
  static const Map<String, String> _knownChainMap = {
    'THE COFFEE HOUSE': 'THE COFFEE HOUSE',
    'HIGHLANDS COFFEE': 'HIGHLANDS COFFEE',
    'BÁCH HÓA XANH': 'BÁCH HÓA XANH',
    'BACH HOA XANH': 'BÁCH HÓA XANH',
    'MEGA MARKET': 'MEGA MARKET',
    'FAMILY MART': 'FAMILY MART',
    'SAIGON CO.OP': 'CO.OPMART',
    'LOTTE MART': 'LOTTE MART',
    'FAMILYMART': 'FAMILY MART',
    'CO.OP MART': 'CO.OPMART',
    'PHÚC LONG': 'PHÚC LONG',
    'PHUC LONG': 'PHÚC LONG',
    'CO.OPMART': 'CO.OPMART',
    'LOTTEMART': 'LOTTE MART',
    'MINI STOP': 'MINISTOP',
    'HIGHLANDS': 'HIGHLANDS COFFEE',
    'CIRCLE K': 'CIRCLE K',
    '7-ELEVEN': '7-ELEVEN',
    'GUARDIAN': 'GUARDIAN',
    'MINISTOP': 'MINISTOP',
    'COOPMART': 'CO.OPMART',
    'WIN MART': 'WINMART',
    'WINMART': 'WINMART',
    'BIG C': 'BIG C',
    'AEON': 'AEON',
    'GS25': 'GS25',
    'BHX': 'BÁCH HÓA XANH',
  };

  // Lines to skip for merchant detection
  static final _merchantSkipPatterns = [
    RegExp(r'\b\d{4,}\b'),           // long digit strings
    RegExp(r'\bMST\b', caseSensitive: false),
    RegExp(r'\bHotline\b', caseSensitive: false),
    RegExp(r'\bĐT\b|\bDT\b|\bSDT\b|\bSĐT\b', caseSensitive: false),
    RegExp(r'\bĐịa chỉ\b|\bDia chi\b|\bĐ/C\b|\bDC:', caseSensitive: false),
    RegExp(r'\bAddress\b', caseSensitive: false),
    RegExp(r'\bTel\b|\bPhone\b|\bFax\b', caseSensitive: false),
    RegExp(r'^\d{2}[/\-\.]\d{2}[/\-\.]\d{2,4}'), // date lines
    RegExp(r'www\.|\.com|\.vn', caseSensitive: false),
    RegExp(r'@'),  // email
  ];

  /// Parse raw OCR text lines into a [ParsedReceipt].
  ParsedReceipt parse(List<String> lines) {
    if (lines.isEmpty) {
      return const ParsedReceipt(confidence: 0.0, rawLines: []);
    }

    final totalAmount = _extractTotal(lines);
    final date = _extractDate(lines);
    final merchantName = _extractMerchant(lines);

    // Compute a confidence score based on what we found.
    double confidence = 0.0;
    if (totalAmount != null) confidence += 0.5;
    if (merchantName != null) confidence += 0.25;
    if (date != null) confidence += 0.25;

    return ParsedReceipt(
      totalAmount: totalAmount,
      merchantName: merchantName,
      date: date,
      confidence: confidence,
      rawLines: lines,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TOTAL AMOUNT EXTRACTION
  // ═══════════════════════════════════════════════════════════════════

  double? _extractTotal(List<String> lines) {
    // Strategy 1: look for keyword lines and extract amounts from them
    //             or the next line.
    for (int i = 0; i < lines.length; i++) {
      final normalized = _removeDiacritics(lines[i]).toUpperCase();
      for (final keyword in _totalKeywords) {
        final keyNorm = _removeDiacritics(keyword).toUpperCase();
        if (normalized.contains(keyNorm)) {
          // Try the same line first
          final amount = _extractAmountFromLine(lines[i]);
          if (amount != null && amount > 0) return amount;
          // Try the next line (OCR often splits label and value)
          if (i + 1 < lines.length) {
            final nextAmount = _extractAmountFromLine(lines[i + 1]);
            if (nextAmount != null && nextAmount > 0) return nextAmount;
          }
        }
      }
    }

    // Strategy 2: fallback — pick the largest plausible amount in
    //             the lower half of the receipt.
    final lowerHalfStart = lines.length ~/ 2;
    double? largest;
    for (int i = lowerHalfStart; i < lines.length; i++) {
      if (_isPhoneOrTaxLine(lines[i])) continue;
      final amount = _extractAmountFromLine(lines[i]);
      if (amount != null && amount > 0) {
        if (largest == null || amount > largest) {
          largest = amount;
        }
      }
    }
    return largest;
  }

  /// Extract a VND-style amount from a single text line.
  ///
  /// Supported formats:
  ///   150,000 VND    150.000 đ    150.000đ    150000
  ///   1.250.000 VND  1,250,000    1250000
  double? _extractAmountFromLine(String line) {
    // Strip currency tokens
    String cleaned = line
        .replaceAll(RegExp(r'[₫đ]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bVND\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bd\b'), '') // trailing 'd'
        .trim();

    // Match number patterns with thousand separators.
    // Pattern: digits with optional groups of (. or ,) followed by 3 digits
    final numberPattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*)',
    );

    final matches = numberPattern.allMatches(cleaned).toList();
    if (matches.isEmpty) return null;

    // Take the last match (amounts tend to be at the end of lines)
    double? bestAmount;
    for (final match in matches) {
      final raw = match.group(1)!;
      final amount = _parseVietnameseNumber(raw);
      if (amount != null && amount >= 1000 && amount <= 100000000) {
        // Plausible VND range: 1,000 to 100,000,000
        if (bestAmount == null || amount > bestAmount) {
          bestAmount = amount;
        }
      }
    }
    return bestAmount;
  }

  /// Parse a Vietnamese-formatted number, handling both `.` and `,` as
  /// thousand separators.
  ///
  /// In Vietnamese: 1.250.000 = 1,250,000 = 1250000
  double? _parseVietnameseNumber(String raw) {
    if (raw.isEmpty) return null;

    // Determine separator style.
    // If the string uses dots and the last group is 3 digits → dot = thousands
    // If the string uses commas and the last group is 3 digits → comma = thousands
    // Mixed separators: normalize both to nothing.

    final hasDot = raw.contains('.');
    final hasComma = raw.contains(',');

    String normalized;
    if (hasDot && !hasComma) {
      // All dots → thousand separators (Vietnamese style)
      normalized = raw.replaceAll('.', '');
    } else if (hasComma && !hasDot) {
      // All commas → thousand separators
      normalized = raw.replaceAll(',', '');
    } else if (hasDot && hasComma) {
      // Mixed: remove both (unlikely but handle gracefully)
      normalized = raw.replaceAll('.', '').replaceAll(',', '');
    } else {
      normalized = raw;
    }

    return double.tryParse(normalized);
  }

  bool _isPhoneOrTaxLine(String line) {
    final upper = line.toUpperCase();
    // Phone number patterns
    if (RegExp(r'0\d{9,10}').hasMatch(line)) return true;
    if (RegExp(r'\+84').hasMatch(line)) return true;
    // Tax code
    if (upper.contains('MST') || upper.contains('TAX')) return true;
    // Barcode / very long digits
    if (RegExp(r'\d{10,}').hasMatch(line)) return true;
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DATE EXTRACTION
  // ═══════════════════════════════════════════════════════════════════

  DateTime? _extractDate(List<String> lines) {
    // Patterns: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY
    // Optionally followed by HH:mm or HH:mm:ss
    final datePattern = RegExp(
      r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})'
      r'(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
    );

    for (final line in lines) {
      final match = datePattern.firstMatch(line);
      if (match != null) {
        final day = int.tryParse(match.group(1)!) ?? 0;
        final month = int.tryParse(match.group(2)!) ?? 0;
        var year = int.tryParse(match.group(3)!) ?? 0;
        final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
        final minute = int.tryParse(match.group(5) ?? '0') ?? 0;

        // Handle 2-digit year
        if (year < 100) {
          year += 2000;
        }

        // Validate ranges
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 &&
            year >= 2000 && year <= 2100 &&
            hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          try {
            return DateTime(year, month, day, hour, minute);
          } catch (_) {
            // Invalid date combination (e.g. Feb 30)
            continue;
          }
        }
      }
    }

    // Fallback: today's date
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MERCHANT EXTRACTION
  // ═══════════════════════════════════════════════════════════════════

  String? _extractMerchant(List<String> lines) {
    // Check known chains first across ALL lines
    for (final line in lines) {
      final upperLine = _removeDiacritics(line).toUpperCase().trim();
      for (final entry in _knownChainMap.entries) {
        final upperChain = _removeDiacritics(entry.key).toUpperCase();
        if (upperLine.contains(upperChain)) {
          return entry.value; // Return the canonical chain name
        }
      }
    }

    // Heuristic: look at the first ~7 non-empty lines, pick the best
    // candidate based on scoring.
    String? bestCandidate;
    double bestScore = -1;

    final candidateLines = lines.take(7).toList();
    for (int i = 0; i < candidateLines.length; i++) {
      final line = candidateLines[i].trim();
      if (line.isEmpty || line.length < 3) continue;

      // Skip lines matching unwanted patterns
      bool skip = false;
      for (final pattern in _merchantSkipPatterns) {
        if (pattern.hasMatch(line)) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      // Skip lines containing total keywords
      final normalizedLine = _removeDiacritics(line).toUpperCase();
      for (final kw in _totalKeywords) {
        if (normalizedLine.contains(_removeDiacritics(kw).toUpperCase())) {
          skip = true;
          break;
        }
      }
      if (skip) continue;

      // Score the candidate
      double score = 0;

      // Prefer lines near the top
      score += (5 - i) * 2.0;

      // Prefer uppercase lines (store names are often all-caps)
      final upperRatio = line.runes
          .where((r) => String.fromCharCode(r) ==
              String.fromCharCode(r).toUpperCase() &&
              String.fromCharCode(r) !=
              String.fromCharCode(r).toLowerCase())
          .length / line.length;
      score += upperRatio * 10;

      // Prefer shorter lines (store name vs. address)
      if (line.length < 30) score += 3;
      if (line.length < 20) score += 2;

      // Penalize lines with too many digits
      final digitRatio =
          line.runes.where((r) => r >= 48 && r <= 57).length / line.length;
      score -= digitRatio * 15;

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = line;
      }
    }

    return bestCandidate;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UTILITIES
  // ═══════════════════════════════════════════════════════════════════

  /// Remove Vietnamese diacritics for case/diacritic-insensitive comparison.
  static String _removeDiacritics(String input) {
    const withDiacritics =
        'àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ'
        'ÀÁẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÈÉẺẼẸÊẾỀỂỄỆÌÍỈĨỊÒÓỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÙÚỦŨỤƯỨỪỬỮỰỲÝỶỸỴĐ';
    const withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final index = withDiacritics.indexOf(char);
      buffer.write(index >= 0 ? withoutDiacritics[index] : char);
    }
    return buffer.toString();
  }
}
