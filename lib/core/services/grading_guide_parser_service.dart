import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/app_models.dart';

class GradingGuideParserService {
  /// Parse a .docx file and extract grading criteria.
  /// Never returns an empty list – uses fallback if parsing fails.
  static Future<List<GradingCriterion>> parseDocxGradingGuide(
    String docxFilePath,
  ) async {
    try {
      print('[GradingGuideParser] ══════════════════════════════════════');
      print('[GradingGuideParser] Starting to parse: $docxFilePath');
      final file = File(docxFilePath);
      if (!await file.exists()) {
        print('[GradingGuideParser] ERROR: File does not exist');
        return _emergencyFallbackCriteria();
      }

      final bytes = await file.readAsBytes();
      print('[GradingGuideParser] Read ${bytes.length} bytes');

      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract document.xml from the archive
      ArchiveFile? documentXmlFile;
      for (final entry in archive) {
        if (entry.name == 'word/document.xml') {
          documentXmlFile = entry;
          break;
        }
      }

      if (documentXmlFile == null) {
        print('[GradingGuideParser] ERROR: Could not find word/document.xml');
        return _emergencyFallbackCriteria();
      }

      // Decode as UTF-8 (docx XML is always UTF-8)
      final xmlContent = utf8.decode(documentXmlFile.content as List<int>, allowMalformed: true);
      print('[GradingGuideParser] Extracted XML, length: ${xmlContent.length} chars');

      final document = XmlDocument.parse(xmlContent);
      print('[GradingGuideParser] Parsed XML successfully');

      // Try multiple strategies in order
      final criteria = _extractCriteria(document);

      if (criteria.isNotEmpty) {
        print('[GradingGuideParser] ✓ Successfully parsed ${criteria.length} criteria');
        return criteria;
      }

      print('[GradingGuideParser] ✗ All strategies failed, using emergency fallback');
      return _emergencyFallbackCriteria();
    } catch (e, stack) {
      print('[GradingGuideParser] FATAL Error parsing docx: $e');
      print('[GradingGuideParser] Stack: $stack');
      return _emergencyFallbackCriteria();
    }
  }

  // ─── Main extraction pipeline ─────────────────────────────────

  static List<GradingCriterion> _extractCriteria(XmlDocument document) {
    // Print all document text for debugging
    final allText = _extractAllDocumentText(document);
    print('[GradingGuideParser] ── Document Text Preview (first 2000 chars) ──');
    print(allText.length > 2000 ? allText.substring(0, 2000) : allText);
    print('[GradingGuideParser] ── End Text Preview ──');

    // Strategy 1: Regex patterns in document text
    var criteria = _strategy1_regexPatterns(allText);
    if (criteria.isNotEmpty) {
      print('[GradingGuideParser] Strategy 1 (regex) succeeded: ${criteria.length} criteria');
      _enrichWithSubCriteria(criteria, document);
      return criteria;
    }

    // Strategy 2: Smart table parsing (the main strategy for FPT docs)
    criteria = _strategy2_smartTableParsing(document);
    if (criteria.isNotEmpty) {
      print('[GradingGuideParser] Strategy 2 (smart table) succeeded: ${criteria.length} criteria');
      _enrichWithSubCriteria(criteria, document);
      return criteria;
    }

    // Strategy 3: Any table row with a numeric score
    criteria = _strategy3_anyRowWithScore(document);
    if (criteria.isNotEmpty) {
      print('[GradingGuideParser] Strategy 3 (any row with score) succeeded: ${criteria.length} criteria');
      return criteria;
    }

    // Strategy 4: Text lines with score patterns
    criteria = _strategy4_textLinesWithScores(allText);
    if (criteria.isNotEmpty) {
      print('[GradingGuideParser] Strategy 4 (text lines) succeeded: ${criteria.length} criteria');
      return criteria;
    }

    return [];
  }

  // ─── Strategy 1: Regex patterns ───────────────────────────────

  static List<GradingCriterion> _strategy1_regexPatterns(String allText) {
    final criteria = <GradingCriterion>[];

    // Pattern set for Vietnamese
    final vnPatterns = [
      RegExp(
        r'Yêu\s+cầu\s+(\d+)\s*[:：.]\s*(.+?)\s*[-–—]\s*(\d+(?:[.,]\d+)?)\s*(?:điểm|đ)?',
        multiLine: true,
      ),
      RegExp(
        r'Câu\s+(\d+)\s*[:：.]\s*(.+?)\s*[-–—]\s*(\d+(?:[.,]\d+)?)\s*(?:điểm|đ)?',
        multiLine: true,
      ),
    ];

    // Pattern set for English
    final enPatterns = [
      RegExp(
        r'Requirement\s+(\d+)\s*[:：.]\s*(.+?)\s*[-–—]\s*(\d+(?:[.,]\d+)?)\s*(?:points?|marks?|pts?)?',
        multiLine: true,
        caseSensitive: false,
      ),
      RegExp(
        r'Task\s+(\d+)\s*[:：.]\s*(.+?)\s*[-–—]\s*(\d+(?:[.,]\d+)?)\s*(?:points?|marks?|pts?)?',
        multiLine: true,
        caseSensitive: false,
      ),
      RegExp(
        r'Q(?:uestion)?\s*(\d+)\s*[:：.]\s*(.+?)\s*[-–—]\s*(\d+(?:[.,]\d+)?)\s*(?:points?|marks?|pts?)?',
        multiLine: true,
        caseSensitive: false,
      ),
    ];

    for (final pattern in [...vnPatterns, ...enPatterns]) {
      for (final match in pattern.allMatches(allText)) {
        final num = match.group(1) ?? '';
        final name = match.group(2)?.trim() ?? 'Criterion';
        final score = _parseScore(match.group(3) ?? '0');
        if (score <= 0 || name.isEmpty) continue;

        print('[GradingGuideParser] Strategy1 found: Q$num "$name" = $score pts');
        criteria.add(_buildCriterion(
          id: 'Q${num.isEmpty ? criteria.length + 1 : num}',
          name: name,
          maxScore: score,
        ));
      }
      if (criteria.isNotEmpty) return criteria;
    }

    return criteria;
  }

  // ─── Strategy 2: Smart table parsing ──────────────────────────

  static List<GradingCriterion> _strategy2_smartTableParsing(XmlDocument document) {
    final criteria = <GradingCriterion>[];
    final tables = document.findAllElements('w:tbl').toList();

    print('[GradingGuideParser] ── Smart Table Parsing ──');
    print('[GradingGuideParser] Found ${tables.length} tables');

    final subIdPattern = RegExp(
      r'^(?:[qQcC]âu\s*|[qQ]\s*|[rR]eq\s*|[rR]equirement\s*|\s*)*(\d+)\.(\d+)(.*)$',
      caseSensitive: false,
    );

    for (var tableIdx = 0; tableIdx < tables.length; tableIdx++) {
      final table = tables[tableIdx];
      final rows = table.findElements('w:tr').toList();
      if (rows.isEmpty) {
        final allRows = table.findAllElements('w:tr').toList();
        if (allRows.isEmpty) continue;
        rows.addAll(allRows);
      }

      final parsedRows = <List<String>>[];
      for (final row in rows) {
        final cells = row.findAllElements('w:tc').toList();
        final cellTexts = cells.map((c) => _extractCellText(c).trim()).toList();
        parsedRows.add(cellTexts);
      }

      final scoreColIdx = _detectScoreColumn(parsedRows);
      if (scoreColIdx == -1) continue;

      final headerRowIdx = _detectHeaderRow(parsedRows);
      final nameColIdx = _detectNameColumn(parsedRows, scoreColIdx, headerRowIdx);

      final startRow = headerRowIdx + 1;
      for (var rowIdx = startRow; rowIdx < parsedRows.length; rowIdx++) {
        final row = parsedRows[rowIdx];
        if (row.isEmpty) continue;

        final nameText = nameColIdx >= 0 && nameColIdx < row.length ? row[nameColIdx].trim() : '';
        final scoreText = scoreColIdx >= 0 && scoreColIdx < row.length ? row[scoreColIdx].trim() : '';

        if (nameText.isEmpty && scoreText.isEmpty) continue;
        if (_isHeaderOrTotalRow(nameText)) continue;

        final score = _parseScore(scoreText);
        if (score <= 0) continue;

        final cleanName = _cleanCriterionName(nameText);
        if (cleanName.isEmpty) continue;

        // Check if this row is a subcriterion
        RegExpMatch? subMatch;
        int matchedIdx = -1;
        for (var i = 0; i < row.length && i < 2; i++) {
          final m = subIdPattern.firstMatch(row[i]);
          if (m != null) {
            subMatch = m;
            matchedIdx = i;
            break;
          }
        }

        if (subMatch != null) {
          final mainIdx = int.tryParse(subMatch.group(1) ?? '');
          final subIdx = int.tryParse(subMatch.group(2) ?? '');

          var subName = subMatch.group(3)?.trim() ?? '';
          subName = subName.replaceFirst(RegExp(r'^[:：.\s\-–—]+'), '').trim();
          if (subName.isEmpty) {
            for (var colIdx = 0; colIdx < row.length; colIdx++) {
              if (colIdx != scoreColIdx && colIdx != matchedIdx && row[colIdx].isNotEmpty) {
                subName = row[colIdx];
                break;
              }
            }
            if (subName.isEmpty) subName = cleanName;
          }

          // Group under the corresponding main criterion
          GradingCriterion? parent;

          if (mainIdx != null) {
            for (final c in criteria) {
              final cDigits = c.id.replaceAll(RegExp(r'[^\d]'), '');
              if (cDigits == mainIdx.toString()) {
                parent = c;
                break;
              }
            }
          }

          parent ??= criteria.isNotEmpty ? criteria.last : null;

          if (parent == null) {
            final parentId = 'Q${mainIdx ?? 1}';
            parent = GradingCriterion(
              id: parentId,
              name: 'Câu ${mainIdx ?? 1}',
              maxScore: 0.0,
              subCriteria: [],
            );
            criteria.add(parent);
          }

          final scId = mainIdx != null && subIdx != null ? '$mainIdx.$subIdx' : 'S${parent.subCriteria.length + 1}';

          if (!parent.subCriteria.any((sc) => sc.id == scId)) {
            print('[GradingGuideParser] SmartTable found SubCriterion $scId under ${parent.id}: "$subName" = $score pts');
            parent.subCriteria.add(SubCriteria(
              id: scId,
              name: subName,
              description: row.join(' | '),
              maxScore: score,
            ));
          }
        } else {
          final digitMatch = RegExp(r'\d+').firstMatch(cleanName);
          final idNum = digitMatch != null ? digitMatch.group(0) : '${criteria.length + 1}';
          final cId = 'Q$idNum';

          if (!criteria.any((c) => c.id == cId)) {
            print('[GradingGuideParser] SmartTable found MainCriterion $cId: "$cleanName" = $score pts');
            criteria.add(GradingCriterion(
              id: cId,
              name: cleanName,
              maxScore: score,
              subCriteria: [],
            ));
          }
        }
      }

      if (criteria.isNotEmpty) {
        for (final c in criteria) {
          if (c.subCriteria.isEmpty) {
            c.subCriteria.add(SubCriteria(
              id: 'S1',
              name: c.name,
              description: '',
              maxScore: c.maxScore,
            ));
          }
        }
        print('[GradingGuideParser] ✓ Found ${criteria.length} criteria from Table ${tableIdx + 1}');
        return criteria;
      }
    }

    return criteria;
  }

  // ─── Strategy 3: Any row with a numeric score ─────────────────

  static List<GradingCriterion> _strategy3_anyRowWithScore(XmlDocument document) {
    final criteria = <GradingCriterion>[];
    final tables = document.findAllElements('w:tbl').toList();

    print('[GradingGuideParser] ── Strategy 3: Any Row With Score ──');

    for (var tableIdx = 0; tableIdx < tables.length; tableIdx++) {
      final table = tables[tableIdx];
      final rows = table.findAllElements('w:tr').toList();

      for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        final row = rows[rowIdx];
        final cells = row.findAllElements('w:tc').toList();
        if (cells.length < 2) continue;

        final cellTexts = cells.map((c) => _extractCellText(c).trim()).toList();

        // Find the first cell with meaningful text and any cell with a score
        String bestName = '';
        double bestScore = 0;

        for (var i = 0; i < cellTexts.length; i++) {
          final text = cellTexts[i];
          final score = _parseScore(text);

          if (score > 0 && _looksLikeScoreCell(text)) {
            bestScore = score;
          } else if (text.length > 2 && bestName.isEmpty && !_isHeaderOrTotalRow(text)) {
            bestName = text;
          }
        }

        if (bestName.isNotEmpty && bestScore > 0) {
          final cleanName = _cleanCriterionName(bestName);
          if (cleanName.isNotEmpty && cleanName.length > 1) {
            print('[GradingGuideParser]   Table ${tableIdx + 1} Row ${rowIdx + 1}: "$cleanName" = $bestScore');
            criteria.add(_buildCriterion(
              id: 'Q${criteria.length + 1}',
              name: cleanName,
              maxScore: bestScore,
            ));
          }
        }
      }

      if (criteria.isNotEmpty) return criteria;
    }

    return criteria;
  }

  // ─── Strategy 4: Text lines with score patterns ───────────────

  static List<GradingCriterion> _strategy4_textLinesWithScores(String allText) {
    final criteria = <GradingCriterion>[];

    // Pattern: "Some text ... number" or "Some text (number)" or "Some text: number"
    final patterns = [
      RegExp(r'^(.{3,80}?)\s*[-–—:]\s*(\d+(?:[.,]\d+)?)\s*(?:điểm|points?|marks?|pts?|đ)?\s*$',
          multiLine: true, caseSensitive: false),
      RegExp(r'^(.{3,80}?)\s*\((\d+(?:[.,]\d+)?)\s*(?:điểm|points?|marks?|pts?|đ)?\)\s*$',
          multiLine: true, caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(allText)) {
        final name = match.group(1)?.trim() ?? '';
        final score = _parseScore(match.group(2) ?? '0');

        if (name.isEmpty || score <= 0 || name.length < 3) continue;
        if (_isHeaderOrTotalRow(name)) continue;

        final cleanName = _cleanCriterionName(name);
        if (cleanName.isEmpty) continue;

        print('[GradingGuideParser] Strategy4: "$cleanName" = $score');
        criteria.add(_buildCriterion(
          id: 'Q${criteria.length + 1}',
          name: cleanName,
          maxScore: score,
        ));
      }
      if (criteria.isNotEmpty) return criteria;
    }

    return criteria;
  }

  // ─── Column detection helpers ─────────────────────────────────

  /// Detect which column contains scores by finding the column
  /// where the most cells contain pure numeric values.
  static int _detectScoreColumn(List<List<String>> rows) {
    if (rows.isEmpty) return -1;

    final maxCols = rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);
    if (maxCols < 2) return -1;

    int bestCol = -1;
    int bestCount = 0;

    for (var col = 0; col < maxCols; col++) {
      int scoreCount = 0;
      for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        if (col >= rows[rowIdx].length) continue;
        final text = rows[rowIdx][col].trim();
        if (_looksLikeScoreCell(text)) {
          scoreCount++;
        }
      }

      if (scoreCount > bestCount) {
        bestCount = scoreCount;
        bestCol = col;
      }
    }

    // Need at least 2 numeric values in the column to consider it a score column
    return bestCount >= 2 ? bestCol : -1;
  }

  /// Detect the header row (first row where cells contain ONLY header labels,
  /// not actual criteria data). A header row typically has short, generic labels
  /// like "Tiêu chí", "Điểm", "Score" rather than specific criterion descriptions.
  static int _detectHeaderRow(List<List<String>> rows) {
    // Header-only keywords: these are pure column labels, not part of data
    final pureHeaderLabels = RegExp(
      r'^(tiêu\s*chí(\s*đánh\s*giá)?|criteria|criterion|rubric|score|marks?|points?|điểm|nội\s*dung|description|no\.?|stt|#|đạt|chưa\s*đạt|chấp\s*nhận)$',
      caseSensitive: false,
    );

    for (var i = 0; i < rows.length && i < 3; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      // Count how many cells in this row are pure header labels
      int headerLabelCount = 0;
      for (final cell in row) {
        final trimmed = cell.trim();
        if (trimmed.isEmpty) continue;
        if (pureHeaderLabels.hasMatch(trimmed)) {
          headerLabelCount++;
        }
      }

      // A row is a header if majority of non-empty cells are pure labels
      final nonEmptyCells = row.where((c) => c.trim().isNotEmpty).length;
      if (nonEmptyCells > 0 && headerLabelCount >= (nonEmptyCells * 0.5)) {
        return i;
      }
    }
    return -1; // No header detected → all rows are data rows
  }

  /// Detect the name column (the column with the longest average text, excluding the score column).
  static int _detectNameColumn(List<List<String>> rows, int scoreCol, int headerRow) {
    if (rows.isEmpty) return 0;

    final maxCols = rows.fold<int>(0, (max, row) => row.length > max ? row.length : max);
    int bestCol = 0;
    double bestAvgLen = 0;

    for (var col = 0; col < maxCols; col++) {
      if (col == scoreCol) continue;

      double totalLen = 0;
      int count = 0;
      for (var rowIdx = headerRow + 1; rowIdx < rows.length; rowIdx++) {
        if (col >= rows[rowIdx].length) continue;
        totalLen += rows[rowIdx][col].trim().length;
        count++;
      }

      final avgLen = count > 0 ? totalLen / count : 0.0;
      if (avgLen > bestAvgLen) {
        bestAvgLen = avgLen;
        bestCol = col;
      }
    }

    return bestCol;
  }

  // ─── Helper methods ───────────────────────────────────────────

  /// Check if a cell text looks like it contains a score value.
  static bool _looksLikeScoreCell(String text) {
    var trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Remove surrounding parentheses or brackets if present
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }

    // Pure number: "2", "2.0", "0.5", "1,5"
    if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(trimmed)) return true;

    // Number with unit (Vietnamese): "2 điểm", "9 đ", "2.0 Đ"
    if (RegExp(r'^\d+([.,]\d+)?\s*(điểm|đ|Đ|Điểm|ĐIỂM)$').hasMatch(trimmed)) return true;

    // Number with unit (English): "2 points", "2 marks", "2 pts"
    if (RegExp(r'^\d+([.,]\d+)?\s*(points?|marks?|pts?)$', caseSensitive: false)
        .hasMatch(trimmed)) return true;

    return false;
  }

  /// Check if row is a header or total row that should be skipped.
  static bool _isHeaderOrTotalRow(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return true;

    final skipPatterns = [
      'total', 'tổng', 'sum', 'cộng', 'tong',
      'header', 'criteria', 'criterion',
      'score', 'mark', 'point', 'điểm',
      'no.', 'stt', '#',
      'nội dung', 'yêu cầu chung',
      'requirement', 'task name',
      'rubric', 'grading',
      'tiêu chí', 'description',
    ];

    // Exact match with common skip words
    for (final pattern in skipPatterns) {
      if (lower == pattern) return true;
    }

    // "Tổng điểm", "Total score", etc.
    if (RegExp(r'^(tổng|total|sum|cộng)\s', caseSensitive: false).hasMatch(lower)) return true;

    // Pure number row (like row numbering "1", "2", "3")
    if (RegExp(r'^\d{1,2}$').hasMatch(lower)) return true;

    return false;
  }

  /// Clean up criterion name text.
  static String _cleanCriterionName(String name) {
    var clean = name.trim();

    // Remove leading numbering: "1.", "1)", "1:", "Q1.", "a.", etc.
    clean = clean.replaceFirst(RegExp(r'^[QqRr]?\d+[.):\s]+\s*'), '');

    // Remove leading bullets
    clean = clean.replaceFirst(RegExp(r'^[-–—•*]\s*'), '');

    // Remove trailing score references
    clean = clean.replaceFirst(
        RegExp(r'\s*[-–—:]\s*\d+([.,]\d+)?\s*(điểm|points?|marks?|pts?|đ)?\s*$',
            caseSensitive: false),
        '');

    // Remove trailing parenthesized scores
    clean = clean.replaceFirst(
        RegExp(r'\s*\(\d+([.,]\d+)?\s*(điểm|points?|marks?|pts?|đ)?\)\s*$',
            caseSensitive: false),
        '');

    // Trim and cap length
    clean = clean.trim();
    if (clean.length > 120) clean = clean.substring(0, 120);

    return clean;
  }

  /// Build a GradingCriterion with a single sub-criteria matching the main criterion.
  static GradingCriterion _buildCriterion({
    required String id,
    required String name,
    required double maxScore,
  }) {
    return GradingCriterion(
      id: id,
      name: name,
      maxScore: maxScore,
      subCriteria: [
        SubCriteria(
          id: 'S1',
          name: name,
          description: '',
          maxScore: maxScore,
        ),
      ],
    );
  }

  /// Extract all text from document for regex matching.
  static String _extractAllDocumentText(XmlDocument document) {
    final buffer = StringBuffer();
    for (final para in document.findAllElements('w:p')) {
      final text = _extractParagraphText(para);
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }
    return buffer.toString();
  }

  /// Extract text from a table cell.
  static String _extractCellText(XmlElement cell) {
    final texts = <String>[];
    for (final para in cell.findAllElements('w:p')) {
      final t = _extractParagraphText(para);
      if (t.isNotEmpty) texts.add(t);
    }
    return texts.join(' ');
  }

  /// Extract all text from a paragraph.
  static String _extractParagraphText(XmlElement paragraph) {
    final texts = <String>[];
    for (final run in paragraph.findAllElements('w:r')) {
      for (final text in run.findAllElements('w:t')) {
        texts.add(text.text);
      }
    }
    return texts.join('');
  }

  /// Parse score from text safely. Handles: "2", "2.0", "0,5", "2 điểm"
  static double _parseScore(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    final text = value.toString().replaceAll(',', '.').trim();
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    if (match == null) return 0.0;
    return double.tryParse(match.group(1) ?? '0') ?? 0.0;
  }

  static void _enrichWithSubCriteria(List<GradingCriterion> criteria, XmlDocument document) {
    final tables = document.findAllElements('w:tbl').toList();
    print('[GradingGuideParser] Enriched sub-criteria search starting over ${tables.length} tables');

    final Map<int, List<SubCriteria>> subCriteriaMap = {};

    final subIdPattern = RegExp(
      r'^(?:[qQcC]âu\s*|[qQ]\s*|[rR]eq\s*|[rR]equirement\s*|\s*)*(\d+)\.(\d+)(.*)$',
      caseSensitive: false,
    );

    for (var tableIdx = 0; tableIdx < tables.length; tableIdx++) {
      final table = tables[tableIdx];
      final rows = table.findAllElements('w:tr').toList();
      if (rows.isEmpty) continue;

      for (final row in rows) {
        final cells = row.findAllElements('w:tc').toList();
        if (cells.length < 2) continue;

        final cellTexts = cells.map((c) => _extractCellText(c).trim()).toList();
        if (cellTexts.isEmpty) continue;

        RegExpMatch? match;
        int matchedCellIdx = -1;
        for (var i = 0; i < cellTexts.length && i < 2; i++) {
          final m = subIdPattern.firstMatch(cellTexts[i]);
          if (m != null) {
            match = m;
            matchedCellIdx = i;
            break;
          }
        }
        if (match == null) continue;

        final mainIdx = int.tryParse(match.group(1) ?? '');
        final subIdx = int.tryParse(match.group(2) ?? '');
        if (mainIdx == null || subIdx == null) continue;

        var subName = match.group(3)?.trim() ?? '';
        subName = subName.replaceFirst(RegExp(r'^[:：.\s\-–—]+'), '').trim();
        if (subName.isEmpty) {
          for (var colIdx = 0; colIdx < cellTexts.length; colIdx++) {
            if (colIdx != matchedCellIdx && cellTexts[colIdx].isNotEmpty && !_looksLikeScoreCell(cellTexts[colIdx])) {
              subName = cellTexts[colIdx];
              break;
            }
          }
          if (subName.isEmpty && cellTexts.length > 1) {
            subName = cellTexts[1];
          }
          if (subName.isEmpty) {
            subName = cellTexts[matchedCellIdx];
          }
        }

        // Try to find the score in this row.
        double score = 0.0;
        for (var i = 0; i < cellTexts.length; i++) {
          if (i == matchedCellIdx) continue;
          final s = _parseScore(cellTexts[i]);
          if (s > 0 && _looksLikeScoreCell(cellTexts[i])) {
            score = s;
            break;
          }
        }

        if (score == 0.0) {
          for (final cellText in cellTexts) {
            final s = _parseScore(cellText);
            if (s > 0) {
              score = s;
              break;
            }
          }
        }

        if (score > 0.0) {
          final scId = '$mainIdx.$subIdx';
          final subCriteriaList = subCriteriaMap.putIfAbsent(mainIdx, () => []);
          if (!subCriteriaList.any((sc) => sc.id == scId)) {
            print('[GradingGuideParser]   Enrichment found sub-criteria $scId: "$subName" = $score pts');
            subCriteriaList.add(SubCriteria(
              id: scId,
              name: subName,
              description: cellTexts.join(' | '),
              maxScore: score,
            ));
          }
        }
      }
    }

    // Now, associate these sub-criteria back to the parsed main criteria
    for (final criterion in criteria) {
      int? mainIdx;
      final digitMatch = RegExp(r'\d+').firstMatch(criterion.id);
      if (digitMatch != null) {
        mainIdx = int.tryParse(digitMatch.group(0) ?? '');
      }

      if (mainIdx == null) {
        final nameDigitMatch = RegExp(r'\d+').firstMatch(criterion.name);
        if (nameDigitMatch != null) {
          mainIdx = int.tryParse(nameDigitMatch.group(0) ?? '');
        }
      }

      mainIdx ??= criteria.indexOf(criterion) + 1;

      final subs = subCriteriaMap[mainIdx];
      if (subs != null && subs.isNotEmpty) {
        print('[GradingGuideParser] Enriching criterion ${criterion.id} (${criterion.name}) with ${subs.length} sub-criteria');
        criterion.subCriteria.clear();
        criterion.subCriteria.addAll(subs);
      }
    }
  }

  // ─── Emergency fallback criteria ──────────────────────────────

  /// Returns sample criteria so the grading screen can always proceed.
  static List<GradingCriterion> _emergencyFallbackCriteria() {
    print('[GradingGuideParser] ⚠ Using emergency fallback criteria');
    return [
      _buildCriterion(id: 'Q1', name: 'Project Setup & Structure', maxScore: 1.0),
      _buildCriterion(id: 'Q2', name: 'UI Implementation', maxScore: 2.0),
      _buildCriterion(id: 'Q3', name: 'Navigation & Routing', maxScore: 1.5),
      _buildCriterion(id: 'Q4', name: 'Data Management', maxScore: 2.0),
      _buildCriterion(id: 'Q5', name: 'Business Logic', maxScore: 1.5),
      _buildCriterion(id: 'Q6', name: 'Code Quality & Best Practices', maxScore: 1.0),
      _buildCriterion(id: 'Q7', name: 'Error Handling', maxScore: 0.5),
      _buildCriterion(id: 'Q8', name: 'Overall Completeness', maxScore: 0.5),
    ];
  }
}
