import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/app_models.dart';
import '../models/ai_models.dart';
import '../services/ai_config_service.dart';
import '../services/ai_service_factory.dart';
import '../services/ai_cache_service.dart';
import '../services/grading_csv_export_service.dart';
import '../services/grading_excel_export_service.dart';
import '../services/grading_storage_service.dart';
import '../services/grading_result_serializer.dart';
import '../services/grading_guide_parser_service.dart';
import '../services/setup_import_storage_service.dart';
import '../services/setup_real_data_service.dart';

enum AppScreen { setup, grading }

class AppStateProvider extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.setup;
  SetupData _setupData = SetupData();
  StudentSubmission? _selectedStudent;
  bool _isLoadingAI = false;
  String? _aiErrorMessage;
  String? _errorMessage;
  String? _currentSessionName;
  String? _currentSessionId;
  Map<String, dynamic>? _currentSession;

  // Track multiple uploaded CSV student lists
  List<Map<String, String>> _uploadedCSVs = [];
  List<Map<String, String>> _uploadedSubmissionFolders = [];
  int _selectedCSVIndex = -1;
  final GradingStorageService _gradingStorage = GradingStorageService();
  final SetupImportStorageService _setupImportStorage =
      SetupImportStorageService();

  AppStateProvider();

  // ─── Getters ────────────────────────────────────────────────
  AppScreen get currentScreen => _currentScreen;
  SetupData get setupData => _setupData;
  StudentSubmission? get selectedStudent => _selectedStudent;
  bool get isLoadingAI => _isLoadingAI;
  String? get aiErrorMessage => _aiErrorMessage;
  String? get errorMessage => _errorMessage;
  String? get currentSessionName => _currentSessionName;
  String? get currentSessionId => _currentSessionId;
  Map<String, dynamic>? get currentSession => _currentSession;
  List<Map<String, String>> get uploadedCSVs => _uploadedCSVs;
  List<Map<String, String>> get uploadedSubmissionFolders =>
      _uploadedSubmissionFolders;
  int get selectedCSVIndex => _selectedCSVIndex;
  SetupImportStorageService get setupImportStorage => _setupImportStorage;

  String get sessionStorageId =>
      GradingStorageService.sessionIdFromName(_currentSessionName);

  void setCurrentSession(Map<String, dynamic>? session) {
    _currentSession = session;
    notifyListeners();
  }

  void setCurrentSessionName(String? name) {
    _currentSessionName = name;
    notifyListeners();
  }

  void setCurrentSessionId(String? id) {
    _currentSessionId = id;
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
  Future<void> setExamFile(String path, String name) async {
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
    if (_currentSessionId != null) {
      await _setupImportStorage.saveExamFile(sessionId: _currentSessionId!, path: path, name: name);
    }
    await _saveImportedDataCache();
    notifyListeners();
  }

  Future<void> setGradingGuide(String path, String name) async {
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
    if (_currentSessionId != null) {
      await _setupImportStorage.saveGradingGuide(sessionId: _currentSessionId!, path: path, name: name);
    }
    await _parseGradingGuide(path);
    await _saveImportedDataCache();
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
      if (_currentSessionId != null) {
        await _setupImportStorage.saveCsvImport(sessionId: _currentSessionId!, path: file.path, name: file.name);
      }
    }
    await _refreshStudentsFromImportedSources();
    await _saveImportedDataCache();
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

    if (_currentSessionId != null) {
      await _setupImportStorage.saveSubmissionFolderImport(
        sessionId: _currentSessionId!,
        path: path,
        name: folderName,
      );
    }
    await _refreshStudentsFromImportedSources();
    await _saveImportedDataCache();
  }

  Future<void> setSubmissionFolder(String path) async {
    await addSubmissionFolder(path);
  }

  // Reload from current imported CSV/folder sources.
  Future<String> refreshImportedData() async {
    final count = await _refreshStudentsFromImportedSources();
    await _saveImportedDataCache();
    return 'Đã nạp lại $count sinh viên từ dữ liệu đã import.';
  }

  String? proceedToGrading() {
    print('[AppStateProvider] Checking data before proceeding to grading...');
    print('[AppStateProvider]   Students: ${_setupData.students.length}');
    print('[AppStateProvider]   Criteria: ${_setupData.parsedCriteria.length}');
    
    if (_setupData.students.isEmpty || _setupData.parsedCriteria.isEmpty) {
      _errorMessage =
          'Thiếu dữ liệu thật để chấm. Hãy import danh sách sinh viên, thư mục bài thi và barem.';
      
      if (_setupData.students.isEmpty) {
        print('[AppStateProvider] ERROR: No students loaded');
      }
      if (_setupData.parsedCriteria.isEmpty) {
        print('[AppStateProvider] ERROR: No criteria parsed');
      }
      
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

    // Update SQLite session progress
    if (_currentSessionId != null) {
      final totalStudents = students.length;
      final graded = gradedCount;
      final pct = totalStudents > 0 ? graded / totalStudents : 0.0;
      final status = graded == totalStudents ? 'graded' : 'grading';
      await _setupImportStorage.updateSessionProgress(_currentSessionId!, pct, totalStudents, status);
      
      if (_currentSession != null) {
        _currentSession!['progress'] = pct;
        _currentSession!['totalSubmissions'] = totalStudents;
        _currentSession!['status'] = status;
      }
    }

    notifyListeners();
    return path;
  }

  /// Xuất toàn bộ điểm ra file CSV (cuối phiên).
  /// Xuất toàn bộ điểm ra file Excel (.xlsx) (cuối phiên).
  Future<String?> exportAllGradesToExcel() async {
    final bytes = GradingExcelExportService.buildExcelContent(
      students: students,
      criteriaTemplate: _setupData.parsedCriteria,
    );

    final baseName = _setupData.csvFileName ?? 'Mark_Output';
    final suggested = baseName.endsWith('.xlsx')
        ? baseName.replaceFirst('.xlsx', '_Output.xlsx')
        : baseName.endsWith('.xls')
            ? baseName.replaceFirst('.xls', '_Output.xlsx')
            : baseName.endsWith('.csv')
                ? baseName.replaceFirst('.csv', '_Output.xlsx')
                : '${baseName}_Output.xlsx';

    return GradingExcelExportService.saveExcelWithPicker(
      excelBytes: bytes,
      suggestedFileName: suggested,
    );
  }

  // Deprecated/Compatibility method: forwards to Excel export
  Future<String?> exportAllGradesToCsv() async {
    return exportAllGradesToExcel();
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


  // ─── AI Grading ──────────────────────────────────────────────

  /// Chạy AI chấm điểm cho 1 sinh viên. Cập nhật aiScore/aiReason.
  /// Dùng cache nếu bài chưa đổi.
  Future<void> runAIGrading(StudentSubmission student) async {
    if (student.fileContent.isEmpty) {
      _aiErrorMessage = 'Sinh viên chưa có bài làm (file content rỗng).';
      notifyListeners();
      return;
    }

    final config = await AiConfigService.instance.getConfig();
    if (!config.isValid) {
      _aiErrorMessage = 'Chưa cấu hình Ollama. Vào AI Settings để nhập Base URL và Model.';
      notifyListeners();
      return;
    }

    _isLoadingAI = true;
    _aiErrorMessage = null;
    notifyListeners();

    try {
      // Check cache first
      final cache = AiCacheService.instance;
      final hash = cache.contentHash(
        student.fileContent,
        student.criteria,
        studentAlias: student.alias,
        modelName: config.model,
      );
      var results = await cache.load(hash);

      if (results == null) {
        // Cache miss → call API
        final service = AIServiceFactory.create(config);
        results = await service.gradeSubmission(
          criteria: student.criteria,
          submissionContent: student.fileContent,
          examContent: _setupData.examContent.isNotEmpty
              ? _setupData.examContent
              : null,
        );
        // Save to cache
        await cache.save(hash, results);
      }

      // Apply AI scores to student criteria
      _applyAIResults(student, results);

      // Auto-save
      await _gradingStorage.saveStudentResult(sessionStorageId, student);

      _isLoadingAI = false;
      notifyListeners();
    } on AiServiceException catch (e) {
      _isLoadingAI = false;
      _aiErrorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isLoadingAI = false;
      _aiErrorMessage = 'Lỗi không xác định: $e';
      notifyListeners();
    }
  }

  /// Apply AI results to student criteria.
  void _applyAIResults(StudentSubmission student, List<AiCriterionResult> results) {
    for (final aiResult in results) {
      final idx = student.criteria.indexWhere((c) => c.id == aiResult.criterionId);
      if (idx == -1) continue;

      if (aiResult.generalComment.isNotEmpty) {
        student.criteria[idx] = student.criteria[idx].copyWith(
          generalComment: aiResult.generalComment,
        );
      }

      final criterion = student.criteria[idx];
      for (final aiSub in aiResult.subScores) {
        final subIdx = criterion.subCriteria.indexWhere((sc) => sc.id == aiSub.subId);
        if (subIdx == -1) continue;
        criterion.subCriteria[subIdx] = criterion.subCriteria[subIdx].copyWith(
          aiScore: aiSub.score,
          aiReason: aiSub.reason,
        );
      }
    }
  }

  /// Tạo nhận xét AI cho 1 criterion.
  Future<String?> runAICommentSuggestion(
    StudentSubmission student,
    String criterionId,
  ) async {
    final config = await AiConfigService.instance.getConfig();
    if (!config.isValid) {
      _aiErrorMessage = 'Chưa cấu hình Ollama. Vào AI Settings để nhập Base URL và Model.';
      notifyListeners();
      return null;
    }

    final criterion = student.criteria
        .where((c) => c.id == criterionId)
        .firstOrNull;
    if (criterion == null) return null;

    _isLoadingAI = true;
    _aiErrorMessage = null;
    notifyListeners();

    try {
      final service = AIServiceFactory.create(config);
      final comment = await service.generateComment(
        criterion: criterion,
        submissionContent: student.fileContent,
      );

      final idx = student.criteria.indexWhere((c) => c.id == criterionId);
      if (idx != -1) {
        student.criteria[idx] = student.criteria[idx].copyWith(
          generalComment: comment,
        );
      }

      _isLoadingAI = false;
      notifyListeners();
      return comment;
    } on AiServiceException catch (e) {
      _isLoadingAI = false;
      _aiErrorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoadingAI = false;
      _aiErrorMessage = 'Lỗi: $e';
      notifyListeners();
      return null;
    }
  }

  void clearAIError() {
    _aiErrorMessage = null;
    notifyListeners();
  }

  // ─── Grading Guide Parsing ───────────────────────────────────
  Future<void> _parseGradingGuide(String path) async {
    try {
      print('[AppStateProvider] Parsing grading guide from: $path');
      final criteria = await GradingGuideParserService.parseDocxGradingGuide(path);
      print('[AppStateProvider] Successfully parsed ${criteria.length} criteria');
      
      for (int i = 0; i < criteria.length; i++) {
        print('[AppStateProvider]   Q${i+1}: ${criteria[i].name} (max: ${criteria[i].maxScore} pts, sub-criteria: ${criteria[i].subCriteria.length})');
      }
      
      // Update setupData with parsed criteria
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
      
      notifyListeners();
    } catch (e) {
      print('[AppStateProvider] Error parsing grading guide: $e');
    }
  }

  Future<void> _saveImportedDataCache() async {
    if (_currentSessionId == null) return;
    try {
      final dir = await _gradingStorage.sessionDirectory(_currentSessionId!);
      if (dir == null) return;
      
      // Save students list cache
      final studentsFile = File(p.join(dir.path, 'imported_students.json'));
      final studentsJson = _setupData.students.map((s) => {
        'alias': s.alias,
        'name': s.name,
        'marker': s.marker,
        'filePath': s.filePath,
        'status': s.status.name,
        'publicComment': s.publicComment,
        'privateNote': s.privateNote,
        'finalScore': s.finalScore,
        'finalScaleScore': s.finalScaleScore,
        'isExported': s.isExported,
      }).toList();
      await studentsFile.writeAsString(jsonEncode(studentsJson));

      // Save criteria cache
      final criteriaFile = File(p.join(dir.path, 'parsed_criteria.json'));
      final criteriaJson = _setupData.parsedCriteria.map((c) => GradingResultSerializer.criterionToJson(c)).toList();
      await criteriaFile.writeAsString(jsonEncode(criteriaJson));
      print('[AppStateProvider] Saved imported data cache for session $_currentSessionId');
    } catch (e) {
      print('[AppStateProvider] Error saving imported data cache: $e');
    }
  }

  Future<void> loadSessionData(String sessionId) async {
    print('[AppStateProvider] Loading session data for: $sessionId');
    _currentSessionId = sessionId;

    // Load active session metadata
    final allSessions = await _setupImportStorage.loadSessions();
    Map<String, dynamic>? matched;
    for (final s in allSessions) {
      if (s['id'] == sessionId) {
        matched = s;
        break;
      }
    }
    if (matched != null) {
      _currentSession = matched;
    }

    // Check if we have cached imported students and criteria
    final dir = await _gradingStorage.sessionDirectory(sessionId);
    File? studentsFile;
    File? criteriaFile;
    if (dir != null) {
      studentsFile = File(p.join(dir.path, 'imported_students.json'));
      criteriaFile = File(p.join(dir.path, 'parsed_criteria.json'));
    }

    if (studentsFile != null && await studentsFile.exists() &&
        criteriaFile != null && await criteriaFile.exists()) {
      print('[AppStateProvider] Loading imported data cache from disk for session: $sessionId');
      try {
        final studentsText = await studentsFile.readAsString();
        final criteriaText = await criteriaFile.readAsString();
        
        final List<dynamic> studentsList = jsonDecode(studentsText);
        final List<dynamic> criteriaList = jsonDecode(criteriaText);
        
        final List<GradingCriterion> criteria = criteriaList
            .map((c) => GradingResultSerializer.criterionFromJson(c as Map<String, dynamic>))
            .toList();

        final List<StudentSubmission> students = studentsList.map((item) {
          final sMap = item as Map<String, dynamic>;
          final statusName = sMap['status'] as String?;
          final status = GradingStatus.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => GradingStatus.ungraded,
          );
          
          final student = StudentSubmission(
            alias: sMap['alias'] as String,
            name: sMap['name'] as String?,
            marker: sMap['marker'] as String?,
            filePath: sMap['filePath'] as String? ?? '',
            status: status,
            publicComment: sMap['publicComment'] as String? ?? '',
            privateNote: sMap['privateNote'] as String? ?? '',
            finalScore: (sMap['finalScore'] as num?)?.toDouble(),
            finalScaleScore: (sMap['finalScaleScore'] as num?)?.toDouble(),
            isExported: sMap['isExported'] as bool? ?? false,
          );
          
          student.criteria = _deepCopyCriteria(criteria);
          return student;
        }).toList();

        final csvs = await _setupImportStorage.loadCsvImports(sessionId);
        final folders = await _setupImportStorage.loadSubmissionFolderImports(sessionId);
        final savedGuide = await _setupImportStorage.loadGradingGuide(sessionId);
        final savedExam = await _setupImportStorage.loadExamFile(sessionId);

        _uploadedCSVs = csvs;
        _uploadedSubmissionFolders = folders;
        _selectedCSVIndex = _uploadedCSVs.isEmpty ? -1 : _uploadedCSVs.length - 1;

        final selectedCsv = _selectedCSVIndex >= 0 ? _uploadedCSVs[_selectedCSVIndex] : null;
        final lastFolder = _uploadedSubmissionFolders.isEmpty ? null : _uploadedSubmissionFolders.last;

        _setupData = SetupData(
          examFilePath: savedExam?['path'],
          examFileName: savedExam?['name'],
          examContent: '',
          gradingGuidePath: savedGuide?['path'],
          gradingGuideFileName: savedGuide?['name'],
          csvFilePath: selectedCsv?['path'],
          csvFileName: selectedCsv?['name'],
          submissionFolderPath: lastFolder?['path'],
          parsedCriteria: criteria,
          students: students,
        );

        await _restoreAllSavedGrades();
        notifyListeners();
        return;
      } catch (e) {
        print('[AppStateProvider] Error loading cache, falling back to files: $e');
      }
    }

    final csvs = await _setupImportStorage.loadCsvImports(sessionId);
    final folders = await _setupImportStorage.loadSubmissionFolderImports(sessionId);
    final savedGuide = await _setupImportStorage.loadGradingGuide(sessionId);
    final savedExam = await _setupImportStorage.loadExamFile(sessionId);

    _uploadedCSVs = csvs;
    _uploadedSubmissionFolders = folders;
    _selectedCSVIndex = _uploadedCSVs.isEmpty ? -1 : _uploadedCSVs.length - 1;

    final selectedCsv =
        _selectedCSVIndex >= 0 ? _uploadedCSVs[_selectedCSVIndex] : null;
    final lastFolder = _uploadedSubmissionFolders.isEmpty
        ? null
        : _uploadedSubmissionFolders.last;

    _setupData = SetupData(
      examFilePath: savedExam?['path'],
      examFileName: savedExam?['name'],
      examContent: '',
      gradingGuidePath: savedGuide?['path'],
      gradingGuideFileName: savedGuide?['name'],
      csvFilePath: selectedCsv?['path'],
      csvFileName: selectedCsv?['name'],
      submissionFolderPath: lastFolder?['path'],
      parsedCriteria: const [],
      students: const [],
    );

    if (savedGuide != null && savedGuide['path']!.isNotEmpty) {
      await _parseGradingGuide(savedGuide['path']!);
    }

    if (csvs.isNotEmpty || folders.isNotEmpty) {
      await _refreshStudentsFromImportedSources();
      await _saveImportedDataCache();
    } else {
      notifyListeners();
    }
  }

  Future<int> _refreshStudentsFromImportedSources() async {
    print('[AppStateProvider] Refreshing students from imported sources...');
    print('[AppStateProvider]   CSV files: ${_uploadedCSVs.length}');
    print('[AppStateProvider]   Submission folders: ${_uploadedSubmissionFolders.length}');
    
    final csvPaths =
        _uploadedCSVs.map((csv) => csv['path']).whereType<String>().toList();
    final folderPaths = _uploadedSubmissionFolders
        .map((folder) => folder['path'])
        .whereType<String>()
        .toList();

    final importedStudents =
        await SetupRealDataService.readStudentsFromCsvFiles(csvPaths);
    print('[AppStateProvider] Read ${importedStudents.length} student records from CSV');
    
    final indexedFiles =
        await SetupRealDataService.indexSubmissionFiles(folderPaths);
    print('[AppStateProvider] Indexed ${indexedFiles.length} submission files');
    
    final rebuilt = SetupRealDataService.buildStudents(
      records: importedStudents,
      indexedSubmissionPaths: indexedFiles,
    );
    print('[AppStateProvider] Built ${rebuilt.length} student objects');

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
    print('[AppStateProvider] Merged to ${merged.length} students');

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

    print('[AppStateProvider] Updated setupData: ${merged.length} students, ${_setupData.parsedCriteria.length} criteria');
    await _restoreAllSavedGrades();
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
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
