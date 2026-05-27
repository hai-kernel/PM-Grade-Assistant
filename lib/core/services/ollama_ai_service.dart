import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ai_models.dart';
import '../models/app_models.dart';
import 'ai_service.dart';

/// Ollama local implementation of [AIService].
class OllamaAiService implements AIService {
  final String baseUrl;
  final String model;

  OllamaAiService({required this.baseUrl, required this.model});

  @override
  Future<List<AiCriterionResult>> gradeSubmission({
    required List<GradingCriterion> criteria,
    required String submissionContent,
    String? examContent,
  }) async {
    final prompt = _buildGradingPrompt(
      criteria: criteria,
      submission: submissionContent,
      examContent: examContent,
    );

    final responseText = await _callOllamaApi(prompt, jsonMode: true);
    return _parseGradingResponse(responseText, criteria);
  }

  @override
  Future<String> generateComment({
    required GradingCriterion criterion,
    required String submissionContent,
  }) async {
    final prompt = _buildCommentPrompt(
      criterion: criterion,
      submission: submissionContent,
    );

    final responseText = await _callOllamaApi(prompt, jsonMode: false);
    return responseText.trim();
  }

  @override
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        throw AiServiceException('Ollama API error (${resp.statusCode}): ${resp.body}');
      }
      
      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      } catch (e) {
        throw AiServiceException('Không parse được JSON từ API tags của Ollama: $e');
      }

      final models = decoded['models'] as List<dynamic>? ?? [];
      final modelNames = models.map((m) => (m['name'] as String? ?? '').toLowerCase()).toList();
      final target = model.toLowerCase();
      
      final exists = modelNames.any((name) =>
          name == target ||
          name == '$target:latest' ||
          '$name:latest' == target ||
          name.startsWith('$target:') ||
          target.startsWith('$name:'));

      if (!exists) {
        throw AiServiceException(
          'Model "$model" chưa được tải về máy.\nVui lòng chạy lệnh: ollama pull $model'
        );
      }
      return true;
    } on SocketException catch (_) {
      throw const AiServiceException(
        'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
      );
    } on http.ClientException catch (_) {
      throw const AiServiceException(
        'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
      );
    } on AiServiceException {
      rethrow;
    } catch (e) {
      final estr = e.toString().toLowerCase();
      if (estr.contains('connection refused') || estr.contains('connection failed') || estr.contains('socketexception')) {
        throw const AiServiceException(
          'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
        );
      }
      throw AiServiceException('Lỗi kết nối tới Ollama: $e');
    }
  }

  // ─── API Call Helper ─────────────────────────────────────────

  Future<String> _callOllamaApi(String prompt, {bool jsonMode = false}) async {
    final url = Uri.parse('$baseUrl/api/generate');
    final body = jsonEncode({
      'model': model,
      'prompt': prompt,
      'stream': false,
      if (jsonMode) 'format': 'json',
      'options': {
        'num_ctx': 16384,
        'num_predict': 4096,
        'temperature': 0.0,
      },
    });

    try {
      print('[OllamaAiService] Sending request to Ollama: $url, Model: $model');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded;
        try {
          decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        } catch (e) {
          throw AiServiceException('Không parse được JSON từ Ollama: $e');
        }
        final responseText = decoded['response'] as String?;
        if (responseText != null) {
          return responseText;
        }
        throw const AiServiceException('Phản hồi từ Ollama không chứa trường "response".');
      }

      if (response.statusCode == 404 || response.statusCode == 400 || response.body.contains('not found')) {
        throw AiServiceException(
          'Model chưa được tải. Vui lòng chạy: ollama pull $model'
        );
      }

      throw AiServiceException('Ollama API error (${response.statusCode}): ${response.body}');
    } on SocketException catch (_) {
      throw const AiServiceException(
        'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
      );
    } on http.ClientException catch (_) {
      throw const AiServiceException(
        'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
      );
    } on FormatException catch (e) {
      throw AiServiceException('Lỗi định dạng phản hồi từ Ollama: $e');
    } on AiServiceException {
      rethrow;
    } catch (e) {
      final estr = e.toString().toLowerCase();
      if (estr.contains('connection refused') || estr.contains('connection failed') || estr.contains('socketexception')) {
        throw const AiServiceException(
          'Ollama chưa chạy. Vui lòng mở Ollama hoặc chạy "ollama serve".'
        );
      } else if (estr.contains('timeout')) {
        throw const AiServiceException(
          'Yêu cầu tới Ollama bị quá hạn (timeout). Vui lòng thử lại.'
        );
      }
      throw AiServiceException('Lỗi khi gọi Ollama: $e');
    }
  }

  // ─── Prompt Builders ─────────────────────────────────────────

  String _buildGradingPrompt({
    required List<GradingCriterion> criteria,
    required String submission,
    String? examContent,
  }) {
    final buf = StringBuffer();
    buf.writeln('Bạn là một trợ lý AI chấm điểm bài thi Project Management chuyên nghiệp, công tâm và chính xác.');
    buf.writeln('Hãy chấm điểm bài làm của sinh viên dựa trên Barem điểm chi tiết dưới đây.');
    buf.writeln();

    buf.writeln('BAREM ĐIỂM CHI TIẾT:');
    for (final c in criteria) {
      buf.writeln('- Yêu cầu lớn: ${c.id} - ${c.name} (Điểm tối đa: ${c.maxScore})');
      for (final sc in c.subCriteria) {
        buf.writeln('  + Tiêu chí phụ: ${sc.id} - ${sc.name} (Điểm tối đa: ${sc.maxScore})');
        if (sc.description.isNotEmpty) {
          buf.writeln('    Quy tắc & Mô tả chấm điểm: ${sc.description}');
        }
      }
    }
    buf.writeln();

    buf.writeln('BÀI LÀM CỦA SINH VIÊN (BẮT BUỘC ĐỌC TOÀN BỘ VÀ KỸ LƯỠNG ĐỂ TRÁNH SÓT Ý):');
    buf.writeln(submission);
    buf.writeln();

    buf.writeln('YÊU CẦU ĐẦU RA:');
    buf.writeln('Trả về DUY NHẤT một đối tượng JSON có định dạng chính xác như sau:');
    buf.writeln('{');
    buf.writeln('  "items": [');
    buf.writeln('    {');
    buf.writeln('      "subCriteriaId": "1.1",');
    buf.writeln('      "aiScore": 1.5,');
    buf.writeln('      "aiReason": "Lý do chấm điểm cụ thể bằng tiếng Việt"');
    buf.writeln('    }');
    buf.writeln('  ],');
    buf.writeln('  "overallComment": "Nhận xét chung toàn bộ bài làm bằng tiếng Việt"');
    buf.writeln('}');
    buf.writeln();

    final requiredIds = criteria.expand((c) => c.subCriteria.map((sc) => sc.id)).toList();
    buf.writeln('QUY TẮC RÀNG BUỘC CỰC KỲ QUAN TRỌNG:');
    buf.writeln('1. Bạn PHẢI chấm điểm và trả về đầy đủ kết quả cho TẤT CẢ các tiêu chí phụ.');
    buf.writeln('   Danh sách các "subCriteriaId" BẮT BUỘC phải có trong kết quả JSON là:');
    buf.writeln('   ${requiredIds.map((id) => '"$id"').join(', ')}');
    buf.writeln('2. Tuyệt đối không được bỏ sót bất kỳ tiêu chí phụ nào trong danh sách trên.');
    buf.writeln('3. Điểm số "aiScore" phải là số thực trong khoảng [0, Điểm tối đa] của tiêu chí phụ đó.');
    buf.writeln('4. Lý do chấm điểm và nhận xét chung viết bằng tiếng Việt ngắn gọn, chuyên nghiệp và có dẫn chứng từ bài làm.');
    buf.writeln('5. Chỉ trả về JSON hợp lệ, không bao gồm bất kỳ văn bản giải thích nào khác ngoài JSON.');

    return buf.toString();
  }

  String _buildCommentPrompt({
    required GradingCriterion criterion,
    required String submission,
  }) {
    final buf = StringBuffer();
    buf.writeln(
        'Viết nhận xét ngắn (2-3 câu tiếng Việt) cho phần "${criterion.id} ${criterion.name}":');

    for (final sc in criterion.subCriteria) {
      final s = sc.manualScore ?? sc.aiScore;
      buf.write(
          ' ${sc.id}:${s?.toStringAsFixed(1) ?? "?"}/${sc.maxScore.toStringAsFixed(0)}');
    }
    buf.writeln();

    final section = _extractRelevantSection(submission, criterion);
    if (section.isNotEmpty) {
      buf.writeln('Trích bài:');
      buf.writeln(section);
    }

    buf.writeln('Nêu điểm mạnh và cần cải thiện. Text thuần, không JSON.');
    return buf.toString();
  }

  String _extractRelevantSection(String submission, GradingCriterion criterion) {
    if (submission.isEmpty) return '';

    final lines = submission.split('\n');
    final idNum = criterion.id.replaceAll(RegExp(r'[^0-9]'), '');

    final patterns = [
      RegExp(r'(QUESTION|CÂU|YÊU CẦU|PHẦN)\s*' + RegExp.escape(idNum),
          caseSensitive: false),
      RegExp(RegExp.escape(criterion.id), caseSensitive: false),
    ];

    int startLine = -1;
    for (int i = 0; i < lines.length; i++) {
      for (final p in patterns) {
        if (p.hasMatch(lines[i])) {
          startLine = i;
          break;
        }
      }
      if (startLine != -1) break;
    }

    if (startLine == -1) {
      return submission.length > 1500
          ? submission.substring(0, 1500)
          : submission;
    }

    final nextNum = (int.tryParse(idNum) ?? 0) + 1;
    final endPatterns = [
      RegExp(r'(QUESTION|CÂU|YÊU CẦU|PHẦN)\s*' + nextNum.toString(),
          caseSensitive: false),
      RegExp(r'═{3,}'),
    ];

    int endLine = lines.length;
    for (int i = startLine + 1; i < lines.length; i++) {
      for (final p in endPatterns) {
        if (p.hasMatch(lines[i])) {
          endLine = i;
          break;
        }
      }
      if (endLine != lines.length) break;
    }

    final section = lines.sublist(startLine, endLine).join('\n');
    return section.length > 2000 ? section.substring(0, 2000) : section;
  }

  // ─── Response Parsers ────────────────────────────────────────

  List<AiCriterionResult> _parseGradingResponse(
    String responseText,
    List<GradingCriterion> criteria,
  ) {
    final cleaned = _extractJson(responseText);
    Map<String, dynamic> responseJson;
    try {
      responseJson = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AiServiceException(
        'Không parse được JSON từ Ollama: $e\nNội dung nhận được: $responseText',
      );
    }

    final itemsRaw = responseJson['items'] as List<dynamic>? ?? [];
    final overallComment = responseJson['overallComment'] as String? ?? '';

    final itemMap = <String, Map<String, dynamic>>{};
    for (final item in itemsRaw) {
      if (item is Map<String, dynamic>) {
        final subId = item['subCriteriaId']?.toString() ?? '';
        if (subId.isNotEmpty) {
          itemMap[subId] = item;
        }
      }
    }

    final results = <AiCriterionResult>[];

    for (var i = 0; i < criteria.length; i++) {
      final criterion = criteria[i];
      final subScores = <AiSubScore>[];

      for (final sub in criterion.subCriteria) {
        var item = itemMap[sub.id];
        if (item == null) {
          String cleanId(String s) {
            return s
                .replaceAll(RegExp(r'[-_:]'), '.')
                .replaceAll(RegExp(r'[^\d.]'), '');
          }
          final subClean = cleanId(sub.id);
          if (subClean.isNotEmpty) {
            for (final entry in itemMap.entries) {
              final keyClean = cleanId(entry.key);
              if (keyClean == subClean) {
                item = entry.value;
                break;
              }
            }
          }
        }
        double score = 0.0;
        String reason = '';

        if (item != null) {
          score = (item['aiScore'] as num?)?.toDouble() ?? 0.0;
          score = score.clamp(0.0, sub.maxScore);
          reason = item['aiReason'] as String? ?? '';
        } else {
          reason = 'Không tìm thấy kết quả chấm cho tiêu chí này.';
        }

        subScores.add(AiSubScore(
          subId: sub.id,
          score: score,
          reason: reason,
        ));
      }

      final generalComment = (i == 0) ? overallComment : '';

      results.add(AiCriterionResult(
        criterionId: criterion.id,
        subScores: subScores,
        generalComment: generalComment,
      ));
    }

    return results;
  }

  String _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      final nl = cleaned.indexOf('\n');
      if (nl != -1) cleaned = cleaned.substring(nl + 1);
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }
    // Also strip potential JSON wrapping if not inside block
    cleaned = cleaned.trim();
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1);
    }
    return cleaned;
  }
}
