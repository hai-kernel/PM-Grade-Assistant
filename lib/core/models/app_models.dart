// lib/core/models/app_models.dart
// Data models for the PMG Grade application

/// Represents a single sub-criteria within a grading criterion
class SubCriteria {
  final String id;       // e.g. "1.1", "1.2"
  final String name;     // e.g. "Project Name"
  final String description;
  final double maxScore;
  double? aiScore;       // AI suggested score
  String? aiReason;      // AI reasoning
  double? manualScore;   // Teacher's final score
  String? deductReason;  // Reason for deduction

  SubCriteria({
    required this.id,
    required this.name,
    required this.description,
    required this.maxScore,
    this.aiScore,
    this.aiReason,
    this.manualScore,
    this.deductReason,
  });

  double get effectiveScore => manualScore ?? aiScore ?? 0;

  SubCriteria copyWith({
    double? manualScore,
    String? deductReason,
    double? aiScore,
    String? aiReason,
  }) {
    return SubCriteria(
      id: id,
      name: name,
      description: description,
      maxScore: maxScore,
      aiScore: aiScore ?? this.aiScore,
      aiReason: aiReason ?? this.aiReason,
      manualScore: manualScore ?? this.manualScore,
      deductReason: deductReason ?? this.deductReason,
    );
  }
}

/// Represents a main grading criterion (Question / Requirement)
class GradingCriterion {
  final String id;       // e.g. "Q1", "Q2" or "Yêu cầu 1"
  final String name;
  final double maxScore;
  final List<SubCriteria> subCriteria;
  String? generalComment;

  GradingCriterion({
    required this.id,
    required this.name,
    required this.maxScore,
    required this.subCriteria,
    this.generalComment,
  });

  double get totalScore => subCriteria.fold(0, (sum, sc) => sum + sc.effectiveScore);
  double get totalMaxScore => subCriteria.fold(0, (sum, sc) => sum + sc.maxScore);

  bool get isFullyGraded => subCriteria.every((sc) => sc.manualScore != null);

  GradingCriterion copyWith({
    String? generalComment,
  }) {
    return GradingCriterion(
      id: id,
      name: name,
      maxScore: maxScore,
      subCriteria: subCriteria,
      generalComment: generalComment ?? this.generalComment,
    );
  }
}

/// Grading status of a student submission
enum GradingStatus { ungraded, inProgress, graded }

/// Represents a student's submission
class StudentSubmission {
  final String alias;        // Student ID / alias (from CSV)
  final String? name;        // Student display name
  final String? marker;      // Assigned marker (teacher)
  final String filePath;     // Path to submission file (.txt)
  String fileContent;        // Loaded file content
  
  GradingStatus status;
  List<GradingCriterion> criteria;  // Filled in during grading
  
  String publicComment;   // Visible to student
  String privateNote;     // Teacher's private note
  
  double? finalScore;          // On scale of 100
  double? finalScaleScore;     // On scale of 10
  bool isExported;

  StudentSubmission({
    required this.alias,
    this.name,
    this.marker,
    required this.filePath,
    this.fileContent = '',
    this.status = GradingStatus.ungraded,
    this.criteria = const [],
    this.publicComment = '',
    this.privateNote = '',
    this.finalScore,
    this.finalScaleScore,
    this.isExported = false,
  });

  double get computedTotal => criteria.fold(0, (sum, c) => sum + c.totalScore);
  double get maxTotal => criteria.fold(0, (sum, c) => sum + c.totalMaxScore);
  double get computedScale10 => maxTotal > 0 ? (computedTotal / maxTotal) * 10 : 0;

  String get autoPublicComment {
    return "";
  }

  String get autoPrivateNote {
    List<String> generalComments = [];
    for (final c in criteria) {
      if (c.generalComment != null && c.generalComment!.trim().isNotEmpty) {
        generalComments.add("${c.id}: ${c.generalComment!.trim()}");
      }
    }
    if (generalComments.isNotEmpty) {
      return "Nhận xét riêng tư:\n- ${generalComments.join('\n- ')}";
    }
    return "";
  }

  String get finalPublicComment => [publicComment, autoPublicComment].where((s) => s.trim().isNotEmpty).join('\n\n');
  String get finalPrivateNote => [privateNote, autoPrivateNote].where((s) => s.trim().isNotEmpty).join('\n\n');
}

/// App-level setup state
class SetupData {
  String? examFilePath;        // .docx exam file
  String? examFileName;
  String examContent;          // Loaded exam content

  String? gradingGuidePath;    // .docx grading guide
  String? gradingGuideFileName;
  
  String? csvFilePath;         // .csv student list
  String? csvFileName;
  
  String? submissionFolderPath; // folder with student .txt files
  
  List<GradingCriterion> parsedCriteria;
  List<StudentSubmission> students;
  
  SetupData({
    this.examFilePath,
    this.examFileName,
    this.examContent = '',
    this.gradingGuidePath,
    this.gradingGuideFileName,
    this.csvFilePath,
    this.csvFileName,
    this.submissionFolderPath,
    this.parsedCriteria = const [],
    this.students = const [],
  });

  bool get isReadyToGrade =>
      csvFilePath != null &&
      submissionFolderPath != null &&
      parsedCriteria.isNotEmpty &&
      students.isNotEmpty;
}
