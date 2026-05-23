import '../models/app_models.dart';

/// Serialize / deserialize kết quả chấm để lưu file JSON từng bài.
class GradingResultSerializer {
  static Map<String, dynamic> studentToJson(StudentSubmission s) {
    return {
      'alias': s.alias,
      'name': s.name,
      'marker': s.marker,
      'filePath': s.filePath,
      'status': s.status.name,
      'publicComment': s.publicComment,
      'privateNote': s.privateNote,
      'finalScore': s.finalScore,
      'finalScaleScore': s.finalScaleScore,
      'gradedAt': DateTime.now().toIso8601String(),
      'criteria': s.criteria.map(_criterionToJson).toList(),
    };
  }

  static void applyJsonToStudent(
    StudentSubmission student,
    Map<String, dynamic> json,
  ) {
    student.publicComment =
        json['publicComment'] as String? ?? student.publicComment;
    student.privateNote =
        json['privateNote'] as String? ?? student.privateNote;
    student.finalScore = (json['finalScore'] as num?)?.toDouble();
    student.finalScaleScore = (json['finalScaleScore'] as num?)?.toDouble();

    final statusName = json['status'] as String?;
    if (statusName != null) {
      student.status = GradingStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => student.status,
      );
    }

    final criteriaJson = json['criteria'] as List<dynamic>?;
    if (criteriaJson != null && criteriaJson.isNotEmpty) {
      student.criteria = criteriaJson
          .map((e) => _criterionFromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  static Map<String, dynamic> _criterionToJson(GradingCriterion c) {
    return {
      'id': c.id,
      'name': c.name,
      'maxScore': c.maxScore,
      'generalComment': c.generalComment,
      'subCriteria': c.subCriteria.map((sc) => {
            'id': sc.id,
            'name': sc.name,
            'description': sc.description,
            'maxScore': sc.maxScore,
            'aiScore': sc.aiScore,
            'aiReason': sc.aiReason,
            'manualScore': sc.manualScore,
            'deductReason': sc.deductReason,
          }).toList(),
    };
  }

  static GradingCriterion _criterionFromJson(Map<String, dynamic> json) {
    final subs = (json['subCriteria'] as List<dynamic>? ?? [])
        .map((e) => _subFromJson(e as Map<String, dynamic>))
        .toList();
    return GradingCriterion(
      id: json['id'] as String,
      name: json['name'] as String,
      maxScore: (json['maxScore'] as num).toDouble(),
      subCriteria: subs,
      generalComment: json['generalComment'] as String?,
    );
  }

  static SubCriteria _subFromJson(Map<String, dynamic> json) {
    return SubCriteria(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      maxScore: (json['maxScore'] as num).toDouble(),
      aiScore: (json['aiScore'] as num?)?.toDouble(),
      aiReason: json['aiReason'] as String?,
      manualScore: (json['manualScore'] as num?)?.toDouble(),
      deductReason: json['deductReason'] as String?,
    );
  }
}
