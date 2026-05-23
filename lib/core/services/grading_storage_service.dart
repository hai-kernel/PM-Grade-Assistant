import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';
import 'grading_result_serializer.dart';

/// Lưu kết quả chấm từng bài vào thư mục phiên (ngoài bộ nhớ app).
class GradingStorageService {
  static String sessionIdFromName(String? sessionName) {
    if (sessionName == null || sessionName.trim().isEmpty) {
      return 'default_session';
    }
    return sessionName
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Future<Directory> _sessionDir(String sessionId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'grading_sessions', sessionId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _safeAliasFileName(String alias) {
    return alias.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// Lưu kết quả 1 bài sau khi xác nhận điểm.
  Future<String> saveStudentResult(
    String sessionId,
    StudentSubmission student,
  ) async {
    final dir = await _sessionDir(sessionId);
    final file = File(
      p.join(dir.path, '${_safeAliasFileName(student.alias)}.json'),
    );
    final json = GradingResultSerializer.studentToJson(student);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );
    return file.path;
  }

  /// Đọc kết quả đã lưu (nếu có).
  Future<Map<String, dynamic>?> loadStudentResult(
    String sessionId,
    String alias,
  ) async {
    final dir = await _sessionDir(sessionId);
    final file = File(p.join(dir.path, '${_safeAliasFileName(alias)}.json'));
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<Directory?> sessionDirectory(String sessionId) async {
    final dir = await _sessionDir(sessionId);
    return dir;
  }
}
