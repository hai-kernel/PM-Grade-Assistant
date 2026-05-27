import '../models/ai_models.dart';
import '../models/app_models.dart';

/// Abstract AI service contract — all providers must implement this.
abstract class AIService {
  /// Chấm toàn bộ bài 1 sinh viên. 1 request = 1 student.
  /// Returns list of [AiCriterionResult] — one per criterion.
  Future<List<AiCriterionResult>> gradeSubmission({
    required List<GradingCriterion> criteria,
    required String submissionContent,
    String? examContent,
  });

  /// Tạo nhận xét tổng cho 1 criterion.
  Future<String> generateComment({
    required GradingCriterion criterion,
    required String submissionContent,
  });

  /// Test kết nối API. Returns true nếu thành công.
  Future<bool> testConnection();
}
