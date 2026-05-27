import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../models/app_models.dart';

class ImportedStudentRecord {
  final String alias;
  final String? name;
  final String? marker;

  const ImportedStudentRecord({
    required this.alias,
    this.name,
    this.marker,
  });
}

/// Read and merge real setup data from CSV files and submission folders.
class SetupRealDataService {
  static Future<List<ImportedStudentRecord>> readStudentsFromCsvFiles(
    List<String> csvPaths,
  ) async {
    final merged = <String, ImportedStudentRecord>{};
    print('[SetupRealDataService] Reading from ${csvPaths.length} CSV/Excel files');

    for (final filePath in csvPaths) {
      if (filePath.trim().isEmpty) continue;
      final file = File(filePath);
      if (!await file.exists()) {
        print('[SetupRealDataService] File not found: $filePath');
        continue;
      }

      final ext = _extension(filePath).toLowerCase();
      print('[SetupRealDataService] Reading file: $filePath (ext: $ext)');
      
      List<List<String>> rows;
      try {
        if (ext == '.xlsx' || ext == '.xls') {
          rows = await _readRowsFromExcel(file);
        } else {
          final content = await file.readAsString();
          rows = _parseCsvRows(content);
        }
      } catch (e) {
        print('[SetupRealDataService] Error reading file: $e');
        rows = const [];
      }
      
      print('[SetupRealDataService] Got ${rows.length} rows from file');
      if (rows.isEmpty) continue;

      int headerRowIndex = 0;
      bool hasHeader = false;
      for (var r = 0; r < rows.length && r < 5; r++) {
        if (_looksLikeHeader(rows[r])) {
          headerRowIndex = r;
          hasHeader = true;
          break;
        }
      }

      final header = hasHeader ? rows[headerRowIndex] : rows.first;
      final aliasIndex = _detectAliasColumn(header, hasHeader);
      final nameIndex = _detectNameColumn(header, hasHeader);
      final markerIndex = _detectMarkerColumn(header, hasHeader);
      
      print('[SetupRealDataService] Header detected at row $headerRowIndex: $hasHeader, aliasIdx: $aliasIndex, nameIdx: $nameIndex, markerIdx: $markerIndex');

      final startAt = hasHeader ? headerRowIndex + 1 : 0;
      int rowsAdded = 0;
      for (var i = startAt; i < rows.length; i++) {
        final row = rows[i];
        final alias = _readCell(row, aliasIndex).trim();
        if (alias.isEmpty) continue;
        final normalizedAlias = alias.toLowerCase().replaceAll(RegExp(r'\s+'), '');
        if (normalizedAlias == 'alias' || 
            normalizedAlias == 'masv' || 
            normalizedAlias == 'masinhvien' || 
            normalizedAlias == 'studentid') {
          continue;
        }

        final record = ImportedStudentRecord(
          alias: alias,
          name: _nullIfEmpty(_readCell(row, nameIndex).trim()),
          marker: _nullIfEmpty(_readCell(row, markerIndex).trim()),
        );
        merged.putIfAbsent(alias.toLowerCase(), () => record);
        rowsAdded++;
      }
      
      print('[SetupRealDataService] Added $rowsAdded student records from this file');
    }

    print('[SetupRealDataService] Total merged records: ${merged.length}');
    return merged.values.toList();
  }

  static Future<List<List<String>>> _readRowsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final firstSheet = excel.tables.values.first;
    final rows = <List<String>>[];
    for (final row in firstSheet.rows) {
      final cells = row.map((cell) => cell?.value?.toString() ?? '').toList();
      if (cells.any((c) => c.trim().isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
  }

  static Future<Map<String, String>> indexSubmissionFiles(
    List<String> folderPaths,
  ) async {
    final byExact = <String, String>{};
    final byContains = <String, String>{};
    const allowedExt = {'.txt', '.md', '.markdown', '.log'};
    
    print('[SetupRealDataService] Indexing submission files from ${folderPaths.length} folders');

    for (final folderPath in folderPaths) {
      if (folderPath.trim().isEmpty) continue;
      final folder = Directory(folderPath);
      if (!await folder.exists()) {
        print('[SetupRealDataService] Folder not found: $folderPath');
        continue;
      }
      
      print('[SetupRealDataService] Scanning folder: $folderPath');
      int filesInFolder = 0;

      await for (final entity
          in folder.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final ext = _extension(entity.path).toLowerCase();
        if (!allowedExt.contains(ext)) continue;

        final baseName = _basenameWithoutExtension(entity.path);
        final normalized = _normalizeKey(baseName);
        if (normalized.isEmpty) continue;

        byExact.putIfAbsent(normalized, () => entity.path);
        byContains.putIfAbsent(normalized, () => entity.path);
        filesInFolder++;
      }
      
      print('[SetupRealDataService] Found $filesInFolder submission files in this folder');
    }

    print('[SetupRealDataService] Total indexed files: ${byContains.length}');
    return {...byContains, ...byExact};
  }

  static List<StudentSubmission> buildStudents({
    required List<ImportedStudentRecord> records,
    required Map<String, String> indexedSubmissionPaths,
  }) {
    final students = <StudentSubmission>[];
    for (final record in records) {
      final aliasKey = _normalizeKey(record.alias);
      final exactPath = indexedSubmissionPaths[aliasKey];
      final fuzzyPath = exactPath ??
          _findFirstContainsPath(
            indexedSubmissionPaths,
            aliasKey,
          );

      students.add(
        StudentSubmission(
          alias: record.alias,
          name: record.name,
          marker: record.marker,
          filePath: fuzzyPath ?? '',
          fileContent: '',
          status: GradingStatus.ungraded,
          criteria: const [],
        ),
      );
    }
    return students;
  }

  static List<List<String>> _parseCsvRows(String content) {
    if (content.trim().isEmpty) return [];
    final parsed = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);
    return parsed
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList();
  }

  static String _readCell(List<String> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return row[index];
  }

  static bool _looksLikeHeader(List<String> row) {
    return row.any((cell) {
      final n = _normalizeKey(cell);
      return n.contains('alias') ||
          n.contains('masv') ||
          n.contains('mssv') ||
          n.contains('masinhvien') ||
          n.contains('studentid') ||
          n.contains('hoten') ||
          n.contains('hovaten') ||
          n.contains('tensinhvien') ||
          n.contains('tensv') ||
          n.contains('name') ||
          n.contains('fullname') ||
          n.contains('marker') ||
          n.contains('giaovien') ||
          n.contains('giangvien') ||
          n.contains('gv') ||
          n.contains('stt');
    });
  }

  static int _detectAliasColumn(List<String> header, bool hasHeader) {
    if (!hasHeader) return 0;
    for (var i = 0; i < header.length; i++) {
      final n = _normalizeKey(header[i]);
      if (n.contains('alias') ||
          n.contains('masv') ||
          n.contains('mssv') ||
          n.contains('masinhvien') ||
          n == 'id' ||
          n.contains('studentid')) {
        return i;
      }
    }
    return 0;
  }

  static int _detectNameColumn(List<String> header, bool hasHeader) {
    if (!hasHeader) return 1;
    for (var i = 0; i < header.length; i++) {
      final n = _normalizeKey(header[i]);
      if (n.contains('hoten') ||
          n.contains('hovaten') ||
          n.contains('tensinhvien') ||
          n.contains('tensv') ||
          n == 'ten' ||
          n.contains('name') ||
          n.contains('fullname')) return i;
    }
    return 1;
  }

  static int _detectMarkerColumn(List<String> header, bool hasHeader) {
    if (!hasHeader) return 2;
    for (var i = 0; i < header.length; i++) {
      final n = _normalizeKey(header[i]);
      if (n.contains('marker') ||
          n.contains('giaovien') ||
          n.contains('giangvien') ||
          n.contains('gv')) return i;
    }
    return -1;
  }

  static String? _findFirstContainsPath(
    Map<String, String> indexedPaths,
    String aliasKey,
  ) {
    if (aliasKey.isEmpty) return null;
    for (final entry in indexedPaths.entries) {
      if (entry.key.contains(aliasKey) || aliasKey.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _basenameWithoutExtension(String path) {
    final normalized = path.replaceAll('\\', '/');
    final base = normalized.split('/').last;
    final dot = base.lastIndexOf('.');
    if (dot <= 0) return base;
    return base.substring(0, dot);
  }

  static String _extension(String path) {
    final normalized = path.replaceAll('\\', '/');
    final base = normalized.split('/').last;
    final dot = base.lastIndexOf('.');
    if (dot < 0) return '';
    return base.substring(dot);
  }

  static String? _nullIfEmpty(String value) {
    return value.isEmpty ? null : value;
  }

  static String _normalizeKey(String value) {
    final lower = value.toLowerCase();
    final deAccented = lower
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y')
        .replaceAll('đ', 'd');
    return deAccented.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
