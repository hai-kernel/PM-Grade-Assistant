import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/app_models.dart';

/// Xuất file Mark Input CSV tổng hợp cuối phiên chấm.
class GradingCsvExportService {
  static String buildCsvContent({
    required List<StudentSubmission> students,
    required List<GradingCriterion> criteriaTemplate,
  }) {
    final criteria = criteriaTemplate.isNotEmpty
        ? criteriaTemplate
        : (students
                .firstWhere(
                  (s) => s.criteria.isNotEmpty,
                  orElse: () => students.first,
                )
                .criteria);

    final rows = <List<dynamic>>[];

    // Header row 1
    rows.add([
      'Alias',
      'Marker',
      ...criteria.map((c) => c.name),
      'Total',
      'Comment',
    ]);

    // Header row 2 — max points
    rows.add([
      '',
      '',
      ...criteria.map((c) => c.totalMaxScore.toStringAsFixed(0)),
      criteria.fold<double>(0, (s, c) => s + c.totalMaxScore).toStringAsFixed(0),
      '',
    ]);

    for (final student in students) {
      final studentCriteria = student.criteria.isNotEmpty
          ? student.criteria
          : criteria;

      final qScores = <String>[];
      for (var i = 0; i < criteria.length; i++) {
        if (i < studentCriteria.length) {
          qScores.add(studentCriteria[i].totalScore.toStringAsFixed(1));
        } else {
          qScores.add('');
        }
      }

      final total = student.status == GradingStatus.graded
          ? (student.finalScore ?? student.computedTotal).toStringAsFixed(1)
          : '';

      rows.add([
        student.alias,
        student.marker ?? '',
        ...qScores,
        total,
        student.publicComment,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Mở hộp thoại lưu file .csv trên máy người dùng.
  static Future<String?> saveCsvWithPicker({
    required String csvContent,
    required String suggestedFileName,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất file điểm CSV',
      fileName: suggestedFileName.endsWith('.csv')
          ? suggestedFileName
          : '$suggestedFileName.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: null,
    );

    if (path == null || path.isEmpty) return null;

    final file = File(path);
    await file.writeAsString(csvContent);
    return file.path;
  }
}
