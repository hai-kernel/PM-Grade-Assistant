import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/grading_csv_export_service.dart';
import '../services/grading_storage_service.dart';
import '../services/grading_result_serializer.dart';

enum AppScreen { login, setup, grading }

class AppStateProvider extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.login;
  SetupData _setupData = SetupData();
  StudentSubmission? _selectedStudent;
  bool _isLoadingAI = false;
  String? _errorMessage;
  String? _currentSessionName;

  // Track multiple uploaded CSV student lists
  List<Map<String, String>> _uploadedCSVs = [];
  int _selectedCSVIndex = -1;
  final GradingStorageService _gradingStorage = GradingStorageService();

  // ─── Getters ────────────────────────────────────────────────
  AppScreen get currentScreen => _currentScreen;
  SetupData get setupData => _setupData;
  StudentSubmission? get selectedStudent => _selectedStudent;
  bool get isLoadingAI => _isLoadingAI;
  String? get errorMessage => _errorMessage;
  String? get currentSessionName => _currentSessionName;
  List<Map<String, String>> get uploadedCSVs => _uploadedCSVs;
  int get selectedCSVIndex => _selectedCSVIndex;

  String get sessionStorageId =>
      GradingStorageService.sessionIdFromName(_currentSessionName);

  void setCurrentSessionName(String? name) {
    _currentSessionName = name;
    notifyListeners();
  }

  List<StudentSubmission> get students => _setupData.students;
  List<GradingCriterion> get criteria => _setupData.parsedCriteria;

  static const double passScaleThreshold = 5.0;

  int get assignedCount => students.length;
  int get gradedCount =>
      students.where((s) => s.status == GradingStatus.graded).length;
  int get ungradedCount =>
      students.where((s) => s.status == GradingStatus.ungraded).length;
  int get inProgressCount =>
      students.where((s) => s.status == GradingStatus.inProgress).length;
  /// Chưa chấm xong (chưa chấm + đang chấm).
  int get pendingGradeCount => ungradedCount + inProgressCount;
  int get passCount => students
      .where((s) =>
          s.status == GradingStatus.graded &&
          s.finalScaleScore != null &&
          s.finalScaleScore! >= passScaleThreshold)
      .length;
  int get failCount => students
      .where((s) =>
          s.status == GradingStatus.graded &&
          s.finalScaleScore != null &&
          s.finalScaleScore! < passScaleThreshold)
      .length;

  // ─── Navigation ─────────────────────────────────────────────
  void navigateTo(AppScreen screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  // ─── Setup Actions ───────────────────────────────────────────
  void setExamFile(String path, String name) {
    _setupData = SetupData(
      examFilePath: path,
      examFileName: name,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: _setupData.csvFilePath,
      csvFileName: _setupData.csvFileName,
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: _setupData.parsedCriteria,
      students: _setupData.students,
    );
    notifyListeners();
  }

  void setGradingGuide(String path, String name) {
    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: path,
      gradingGuideFileName: name,
      csvFilePath: _setupData.csvFilePath,
      csvFileName: _setupData.csvFileName,
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: _setupData.parsedCriteria,
      students: _setupData.students,
    );
    _parseGradingGuide(path);
    notifyListeners();
  }

  void setCSVFile(String path, String name) {
    final Map<String, String> newCsv = {'path': path, 'name': name};
    final existsIdx = _uploadedCSVs.indexWhere((c) => c['name'] == name);
    if (existsIdx == -1) {
      _uploadedCSVs.add(newCsv);
      _selectedCSVIndex = _uploadedCSVs.length - 1;
    } else {
      _selectedCSVIndex = existsIdx;
    }

    final int index = _selectedCSVIndex;
    final List<StudentSubmission> list = MockData.getSampleStudents().map((s) {
      return StudentSubmission(
        alias: '${s.alias}_L${index + 1}',
        name: '${s.name} (List ${index + 1})',
        marker: s.marker,
        filePath: s.filePath,
        status: s.status,
        publicComment: s.publicComment,
        privateNote: s.privateNote,
        finalScore: s.finalScore,
        finalScaleScore: s.finalScaleScore,
        isExported: s.isExported,
      );
    }).toList();

    // Check duplicates by alias
    final List<StudentSubmission> currentStudents = List.from(_setupData.students);
    for (final student in list) {
      final isDuplicate = currentStudents.any((s) => s.alias == student.alias);
      if (!isDuplicate) {
        currentStudents.add(student);
      }
    }

    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: path,
      csvFileName: name,
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: _setupData.parsedCriteria,
      students: currentStudents,
    );
    notifyListeners();
  }

  void selectCSVFile(int index) {
    if (index < 0 || index >= _uploadedCSVs.length) return;
    _selectedCSVIndex = index;
    notifyListeners();
  }

  void setSubmissionFolder(String path) {
    final segments = path.split(RegExp(r'[/\\]'));
    final folderName = segments.isNotEmpty ? segments.last : 'folder';

    final List<StudentSubmission> list = MockData.getSampleStudents().map((s) {
      final newAlias = '${s.alias}_$folderName';
      return StudentSubmission(
        alias: newAlias,
        name: '${s.name} ($folderName)',
        marker: s.marker,
        filePath: '$path/$newAlias.txt',
        status: s.status,
        publicComment: s.publicComment,
        privateNote: s.privateNote,
        finalScore: s.finalScore,
        finalScaleScore: s.finalScaleScore,
        isExported: s.isExported,
      );
    }).toList();

    // Check duplicates by alias
    final List<StudentSubmission> currentStudents = List.from(_setupData.students);
    for (final student in list) {
      final isDuplicate = currentStudents.any((s) => s.alias == student.alias);
      if (!isDuplicate) {
        currentStudents.add(student);
      }
    }

    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: _setupData.csvFilePath,
      csvFileName: _setupData.csvFileName,
      submissionFolderPath: path,
      parsedCriteria: _setupData.parsedCriteria,
      students: currentStudents,
    );
    notifyListeners();
  }

  // Load demo data for UI showcase
  void loadDemoData() {
    final criteria = MockData.getSampleCriteria();
    final students = MockData.getSampleStudents();

    _uploadedCSVs = [
      {
        'path': '/demo/PMG201c_SP26_2ndFE_PE_Mark_Input.csv',
        'name': 'PMG201c_SP26_2ndFE_PE_Mark_Input.csv'
      }
    ];
    _selectedCSVIndex = 0;

    _setupData = SetupData(
      examFilePath: '/demo/PMG201c-Exam.docx',
      examFileName: 'PMG201c-Exam.docx',
      gradingGuidePath: '/demo/PMG201c-GradingGuide.docx',
      gradingGuideFileName: 'PMG201c-GradingGuide.docx',
      examContent: '''
ĐỀ THI MÔN PROJECT MANAGEMENT
Mã học phần: PMG201c

PHẦN 1: TỔNG QUAN DỰ ÁN (20 điểm)
Yêu cầu sinh viên tạo một tài liệu mô tả tóm tắt về dự án.
- 1.1 Trình bày tổng quan về dự án.
- 1.2 Xác định mục tiêu của dự án.
- 1.3 Lập danh sách các stakeholder.

PHẦN 2: WORK BREAKDOWN STRUCTURE (20 điểm)
Phân rã dự án thành các gói công việc chi tiết.
- 2.1 Cấu trúc WBS (tối thiểu 3 mức).
- 2.2 Từ điển WBS (WBS Dictionary).

PHẦN 3: ESTIMATE & SCHEDULE (30 điểm)
- 3.1 Ước lượng chi phí (Cost Estimate).
- 3.2 Ước lượng thời gian (Time Estimate).
- 3.3 Sơ đồ Gantt (Gantt Chart).
''',
      csvFilePath: '/demo/PMG201c_SP26_2ndFE_PE_Mark_Input.csv',
      csvFileName: 'PMG201c_SP26_2ndFE_PE_Mark_Input.csv',
      submissionFolderPath: '/demo/submissions',
      parsedCriteria: criteria,
      students: students,
    );

    notifyListeners();
  }

  void proceedToGrading() {
    if (_setupData.students.isEmpty) {
      loadDemoData();
    }
    _currentScreen = AppScreen.grading;
    _restoreAllSavedGrades();
    notifyListeners();
  }

  Future<void> _restoreAllSavedGrades() async {
    final sessionId = sessionStorageId;
    for (final student in _setupData.students) {
      final saved =
          await _gradingStorage.loadStudentResult(sessionId, student.alias);
      if (saved != null) {
        GradingResultSerializer.applyJsonToStudent(student, saved);
      }
    }
    notifyListeners();
  }

  // ─── Grading Actions ────────────────────────────────────────
  void selectStudent(StudentSubmission student) {
    _selectedStudent = student;
    _hydrateStudentFromDisk(student);
  }

  Future<void> _hydrateStudentFromDisk(StudentSubmission student) async {
    final saved = await _gradingStorage.loadStudentResult(
      sessionStorageId,
      student.alias,
    );

    if (saved != null) {
      GradingResultSerializer.applyJsonToStudent(student, saved);
      if (student.fileContent.isEmpty) {
        student.fileContent = MockData.sampleSubmission;
      }
    } else if (student.criteria.isEmpty) {
      student.criteria = _deepCopyCriteria(_setupData.parsedCriteria);
      student.fileContent = MockData.sampleSubmission;
      if (student.status == GradingStatus.ungraded) {
        student.status = GradingStatus.inProgress;
      }
    }

    notifyListeners();
  }

  void updateSubCriteriaScore(
    String criterionId,
    String subCriteriaId,
    double? score,
    String? reason,
  ) {
    if (_selectedStudent == null) return;

    for (final criterion in _selectedStudent!.criteria) {
      if (criterion.id == criterionId) {
        final idx =
            criterion.subCriteria.indexWhere((sc) => sc.id == subCriteriaId);
        if (idx != -1) {
          criterion.subCriteria[idx] = criterion.subCriteria[idx].copyWith(
            manualScore: score,
            deductReason: reason,
          );
        }
      }
    }

    _updateStudentStatus();
    notifyListeners();
  }

  void updateCriterionGeneralComment(String criterionId, String? comment) {
    if (_selectedStudent == null) return;
    
    final idx = _selectedStudent!.criteria.indexWhere((c) => c.id == criterionId);
    if (idx != -1) {
      _selectedStudent!.criteria[idx] = _selectedStudent!.criteria[idx].copyWith(
        generalComment: comment,
      );
      notifyListeners();
    }
  }

  void updateComments({String? publicComment, String? privateNote}) {
    if (_selectedStudent == null) return;
    if (publicComment != null) _selectedStudent!.publicComment = publicComment;
    if (privateNote != null) _selectedStudent!.privateNote = privateNote;
    notifyListeners();
  }

  /// Xác nhận điểm và lưu bài này ra disk (JSON trong thư mục phiên).
  Future<String?> finalizeAndSaveGrading() async {
    if (_selectedStudent == null) return null;

    final student = _selectedStudent!;
    final total = student.computedTotal;
    final maxTotal = student.maxTotal;

    student.finalScore = total;
    student.finalScaleScore = maxTotal > 0 ? (total / maxTotal) * 10 : 0;
    student.status = GradingStatus.graded;

    final path = await _gradingStorage.saveStudentResult(
      sessionStorageId,
      student,
    );

    notifyListeners();
    return path;
  }

  /// Xuất toàn bộ điểm ra file CSV (cuối phiên).
  Future<String?> exportAllGradesToCsv() async {
    final csv = GradingCsvExportService.buildCsvContent(
      students: students,
      criteriaTemplate: _setupData.parsedCriteria,
    );

    final baseName = _setupData.csvFileName ?? 'Mark_Output';
    final suggested = baseName.endsWith('.csv')
        ? baseName.replaceFirst('.csv', '_Output.csv')
        : '${baseName}_Output.csv';

    return GradingCsvExportService.saveCsvWithPicker(
      csvContent: csv,
      suggestedFileName: suggested,
    );
  }

  StudentSubmission? get nextUngradedStudent {
    if (_selectedStudent == null) return null;
    final idx = students.indexWhere((s) => s.alias == _selectedStudent!.alias);
    for (var i = idx + 1; i < students.length; i++) {
      if (students[i].status != GradingStatus.graded) return students[i];
    }
    for (var i = 0; i < idx; i++) {
      if (students[i].status != GradingStatus.graded) return students[i];
    }
    return null;
  }

  void _updateStudentStatus() {
    if (_selectedStudent == null) return;
    final allGraded = _selectedStudent!.criteria
        .every((c) => c.subCriteria.every((sc) => sc.manualScore != null));
    if (allGraded && _selectedStudent!.status != GradingStatus.graded) {
      _selectedStudent!.status = GradingStatus.inProgress;
    }
  }

  // ─── Mock parsing (real impl would use actual parsers) ───────
  void _parseGradingGuide(String path) {
    // In real implementation: parse .docx to extract criteria
    // For now, load demo criteria
    final criteria = MockData.getSampleCriteria();
    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: _setupData.csvFilePath,
      csvFileName: _setupData.csvFileName,
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: criteria,
      students: _setupData.students,
    );
  }

  void _parseCSV(String path) {
    // In real implementation: parse .csv to get student list
    final students = MockData.getSampleStudents();
    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: _setupData.csvFilePath,
      csvFileName: _setupData.csvFileName,
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: _setupData.parsedCriteria,
      students: students,
    );
  }

  List<GradingCriterion> _deepCopyCriteria(List<GradingCriterion> src) {
    return src
        .map((c) => GradingCriterion(
              id: c.id,
              name: c.name,
              maxScore: c.maxScore,
              subCriteria: c.subCriteria
                  .map((sc) => SubCriteria(
                        id: sc.id,
                        name: sc.name,
                        description: sc.description,
                        maxScore: sc.maxScore,
                        aiScore: sc.aiScore,
                        aiReason: sc.aiReason,
                      ))
                  .toList(),
            ))
        .toList();
  }

  void resetSetupData() {
    _setupData = SetupData();
    _selectedStudent = null;
    _uploadedCSVs = [];
    _selectedCSVIndex = -1;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
