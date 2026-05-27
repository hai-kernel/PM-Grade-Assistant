import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/ai_models.dart';
import '../models/app_models.dart';

/// Cache AI grading results locally by content hash.
///
/// - Hash = md5(fileContent + criteriaIds)
/// - Lưu vào AppData/pmg_grade/ai_cache/<hash>.json
/// - Nếu bài chưa đổi → trả cache, không gọi API
class AiCacheService {
  static AiCacheService? _instance;
  static AiCacheService get instance => _instance ??= AiCacheService._();
  AiCacheService._();

  Future<Directory> _cacheDir() async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'pmg_grade', 'ai_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Tạo content hash từ bài làm + criteria IDs + student alias + modelName.
  String contentHash(
    String fileContent,
    List<GradingCriterion> criteria, {
    String studentAlias = '',
    String modelName = '',
  }) {
    final criteriaKey =
        criteria.map((c) => '${c.id}:${c.subCriteria.map((sc) => sc.id).join(",")}').join('|');
    final data = '$studentAlias|$modelName|$fileContent\n---\n$criteriaKey';
    return md5.convert(utf8.encode(data)).toString();
  }

  /// Lưu kết quả AI vào cache.
  Future<void> save(
      String hash, List<AiCriterionResult> results) async {
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, '$hash.json'));
    final json = results.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }

  /// Load kết quả AI từ cache. Trả null nếu chưa có.
  Future<List<AiCriterionResult>?> load(String hash) async {
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, '$hash.json'));
    if (!await file.exists()) return null;

    try {
      final text = await file.readAsString();
      final list = jsonDecode(text) as List<dynamic>;
      return list
          .map((e) => AiCriterionResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Kiểm tra cache có tồn tại không.
  Future<bool> has(String hash) async {
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, '$hash.json'));
    return file.exists();
  }

  /// Xóa toàn bộ cache.
  Future<void> clearAll() async {
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
