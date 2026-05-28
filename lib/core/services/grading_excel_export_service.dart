import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';

/// Service to export grading results to an Excel (.xlsx) file.
class GradingExcelExportService {
  static List<int> buildExcelContent({
    required List<StudentSubmission> students,
    required List<GradingCriterion> criteriaTemplate,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    final String sheetName = defaultSheet ?? 'Sheet1';
    final sheet = excel[sheetName];

    final criteria = criteriaTemplate.isNotEmpty
        ? criteriaTemplate
        : (students
                .firstWhere(
                  (s) => s.criteria.isNotEmpty,
                  orElse: () => students.first,
                )
                .criteria);

    // Build Headers
    // Row 1
    final List<CellValue> headers = [
      TextCellValue('MSSV'),
      TextCellValue('Họ và tên'),
      TextCellValue('Giảng viên'),
      ...criteria.map((c) => TextCellValue(c.name)),
      TextCellValue('Tổng điểm (Thang 100)'),
      TextCellValue('Điểm (Thang 10)'),
      TextCellValue('Nhận xét'),
    ];
    sheet.appendRow(headers);

    // Row 2: Max Points
    final List<CellValue> maxScores = [
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      ...criteria.map((c) => DoubleCellValue(c.totalMaxScore)),
      DoubleCellValue(criteria.fold<double>(0, (s, c) => s + c.totalMaxScore)),
      DoubleCellValue(10.0),
      TextCellValue(''),
    ];
    sheet.appendRow(maxScores);

    // Add student records
    for (final student in students) {
      final studentCriteria = student.criteria.isNotEmpty
          ? student.criteria
          : criteria;

      final List<CellValue> rowValues = [];
      rowValues.add(TextCellValue(student.alias));
      rowValues.add(TextCellValue(student.name ?? ''));
      rowValues.add(TextCellValue(student.marker ?? ''));

      for (var i = 0; i < criteria.length; i++) {
        if (i < studentCriteria.length) {
          rowValues.add(DoubleCellValue(studentCriteria[i].totalScore));
        } else {
          rowValues.add(DoubleCellValue(0.0));
        }
      }

      final double totalScore = student.status == GradingStatus.graded
          ? (student.finalScore ?? student.computedTotal)
          : 0.0;
      
      final double scale10Score = student.status == GradingStatus.graded
          ? (student.finalScaleScore ?? student.computedScale10)
          : 0.0;

      rowValues.add(DoubleCellValue(totalScore));
      rowValues.add(DoubleCellValue(scale10Score));
      rowValues.add(TextCellValue(student.publicComment));

      sheet.appendRow(rowValues);
    }

    return excel.encode() ?? [];
  }

  /// Opens picker and saves Excel file
  static Future<String?> saveExcelWithPicker({
    required List<int> excelBytes,
    required String suggestedFileName,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Xuất file điểm Excel (.xlsx)',
      fileName: suggestedFileName.endsWith('.xlsx')
          ? suggestedFileName
          : '$suggestedFileName.xlsx',
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      bytes: null,
    );

    if (path == null || path.isEmpty) return null;

    final file = File(path);
    await file.writeAsBytes(excelBytes);
    return file.path;
  }
}
