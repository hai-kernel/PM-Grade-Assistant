import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import '../models/app_models.dart';
import '../services/grading_csv_export_service.dart';
import '../services/grading_storage_service.dart';
import '../services/grading_result_serializer.dart';
import '../services/setup_import_storage_service.dart';
import '../services/setup_real_data_service.dart';

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
  List<Map<String, String>> _uploadedSubmissionFolders = [];
  int _selectedCSVIndex = -1;
  final GradingStorageService _gradingStorage = GradingStorageService();
  final SetupImportStorageService _setupImportStorage =
      SetupImportStorageService();

  AppStateProvider() {
    _restoreSetupImportsFromLocalDb();
  }

  // ─── Getters ────────────────────────────────────────────────
  AppScreen get currentScreen => _currentScreen;
  SetupData get setupData => _setupData;
  StudentSubmission? get selectedStudent => _selectedStudent;
  bool get isLoadingAI => _isLoadingAI;
  String? get errorMessage => _errorMessage;
  String? get currentSessionName => _currentSessionName;
  List<Map<String, String>> get uploadedCSVs => _uploadedCSVs;
  List<Map<String, String>> get uploadedSubmissionFolders =>
      _uploadedSubmissionFolders;
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

  Future<void> addCSVFiles(List<({String path, String name})> files) async {
    if (files.isEmpty) return;

    for (final file in files) {
      final existsIdx =
          _uploadedCSVs.indexWhere((csv) => csv['path'] == file.path);
      if (existsIdx == -1) {
        _uploadedCSVs.add({'path': file.path, 'name': file.name});
        _selectedCSVIndex = _uploadedCSVs.length - 1;
      } else {
        _selectedCSVIndex = existsIdx;
      }
      await _setupImportStorage.saveCsvImport(path: file.path, name: file.name);
    }
    await _refreshStudentsFromImportedSources();
  }

  Future<void> setCSVFile(String path, String name) async {
    await addCSVFiles([(path: path, name: name)]);
  }

  void selectCSVFile(int index) {
    if (index < 0 || index >= _uploadedCSVs.length) return;
    _selectedCSVIndex = index;
    final selected = _uploadedCSVs[index];
    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: selected['path'],
      csvFileName: selected['name'],
      submissionFolderPath: _setupData.submissionFolderPath,
      parsedCriteria: _setupData.parsedCriteria,
      students: _setupData.students,
    );
    notifyListeners();
  }

  Future<void> addSubmissionFolder(String path) async {
    final segments = path.split(RegExp(r'[/\\]'));
    final folderName = segments.isNotEmpty ? segments.last : 'folder';
    final exists =
        _uploadedSubmissionFolders.any((folder) => folder['path'] == path);
    if (!exists) {
      _uploadedSubmissionFolders.add({'path': path, 'name': folderName});
    }

    await _setupImportStorage.saveSubmissionFolderImport(
      path: path,
      name: folderName,
    );
    await _refreshStudentsFromImportedSources();
  }

  Future<void> setSubmissionFolder(String path) async {
    await addSubmissionFolder(path);
  }

  // Reload from current imported CSV/folder sources.
  Future<String> loadDemoData() async {
    final count = await _refreshStudentsFromImportedSources();
    return 'Đã nạp lại $count sinh viên từ dữ liệu đã import.';
  }

  String? proceedToGrading() {
    if (_setupData.students.isEmpty || _setupData.parsedCriteria.isEmpty) {
      _errorMessage =
          'Thiếu dữ liệu thật để chấm. Hãy import danh sách sinh viên, thư mục bài thi và barem.';
      notifyListeners();
      return _errorMessage;
    }
    _errorMessage = null;
    _currentScreen = AppScreen.grading;
    _restoreAllSavedGrades();
    notifyListeners();
    return null;
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
      if (student.fileContent.isEmpty && student.filePath.isNotEmpty) {
        student.fileContent = await _readSubmissionText(student.filePath);
      }
    } else if (student.criteria.isEmpty) {
      student.criteria = _deepCopyCriteria(_setupData.parsedCriteria);
      if (student.filePath.isNotEmpty) {
        student.fileContent = await _readSubmissionText(student.filePath);
      }
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

    final idx =
        _selectedStudent!.criteria.indexWhere((c) => c.id == criterionId);
    if (idx != -1) {
      _selectedStudent!.criteria[idx] =
          _selectedStudent!.criteria[idx].copyWith(
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

  Future<void> _restoreSetupImportsFromLocalDb() async {
    final csvs = await _setupImportStorage.loadCsvImports();
    final folders = await _setupImportStorage.loadSubmissionFolderImports();
    if (csvs.isEmpty && folders.isEmpty) return;

    _uploadedCSVs = csvs;
    _uploadedSubmissionFolders = folders;
    _selectedCSVIndex = _uploadedCSVs.isEmpty ? -1 : _uploadedCSVs.length - 1;

    final selectedCsv =
        _selectedCSVIndex >= 0 ? _uploadedCSVs[_selectedCSVIndex] : null;
    final lastFolder = _uploadedSubmissionFolders.isEmpty
        ? null
        : _uploadedSubmissionFolders.last;

    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: selectedCsv?['path'],
      csvFileName: selectedCsv?['name'],
      submissionFolderPath: lastFolder?['path'],
      parsedCriteria: _setupData.parsedCriteria,
      students: const [],
    );

    await _refreshStudentsFromImportedSources();
  }

  Future<int> _refreshStudentsFromImportedSources() async {
    final csvPaths =
        _uploadedCSVs.map((csv) => csv['path']).whereType<String>().toList();
    final folderPaths = _uploadedSubmissionFolders
        .map((folder) => folder['path'])
        .whereType<String>()
        .toList();

    final importedStudents =
        await SetupRealDataService.readStudentsFromCsvFiles(csvPaths);
    final indexedFiles =
        await SetupRealDataService.indexSubmissionFiles(folderPaths);
    final rebuilt = SetupRealDataService.buildStudents(
      records: importedStudents,
      indexedSubmissionPaths: indexedFiles,
    );

    final prevByAlias = <String, StudentSubmission>{
      for (final student in _setupData.students) student.alias: student,
    };
    final merged = rebuilt.map((student) {
      final prev = prevByAlias[student.alias];
      if (prev == null) return student;
      return StudentSubmission(
        alias: student.alias,
        name: student.name ?? prev.name,
        marker: student.marker ?? prev.marker,
        filePath:
            student.filePath.isNotEmpty ? student.filePath : prev.filePath,
        fileContent: prev.fileContent,
        status: prev.status,
        criteria: prev.criteria,
        publicComment: prev.publicComment,
        privateNote: prev.privateNote,
        finalScore: prev.finalScore,
        finalScaleScore: prev.finalScaleScore,
        isExported: prev.isExported,
      );
    }).toList();

    final selectedCsv =
        _selectedCSVIndex >= 0 && _selectedCSVIndex < _uploadedCSVs.length
            ? _uploadedCSVs[_selectedCSVIndex]
            : null;
    final latestFolder = _uploadedSubmissionFolders.isNotEmpty
        ? _uploadedSubmissionFolders.last
        : null;

    _setupData = SetupData(
      examFilePath: _setupData.examFilePath,
      examFileName: _setupData.examFileName,
      examContent: _setupData.examContent,
      gradingGuidePath: _setupData.gradingGuidePath,
      gradingGuideFileName: _setupData.gradingGuideFileName,
      csvFilePath: selectedCsv?['path'],
      csvFileName: selectedCsv?['name'],
      submissionFolderPath: latestFolder?['path'],
      parsedCriteria: _setupData.parsedCriteria,
      students: merged,
    );

    notifyListeners();
    return merged.length;
  }

  Future<String> _readSubmissionText(String filePath) async {
    if (filePath.isEmpty) return '';
    final file = File(filePath);
    if (!await file.exists()) return '';
    try {
      return await file.readAsString();
    } catch (_) {
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    }
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
    _uploadedSubmissionFolders = [];
    _selectedCSVIndex = -1;
    _setupImportStorage.clearAll();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
