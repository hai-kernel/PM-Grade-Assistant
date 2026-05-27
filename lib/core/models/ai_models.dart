// lib/core/models/ai_models.dart
// Shared AI types — provider-agnostic

/// AI provider enum
enum AiProvider {
  ollama;

  String get displayName {
    switch (this) {
      case AiProvider.ollama:
        return 'Ollama Local';
    }
  }

  String get keyHint {
    switch (this) {
      case AiProvider.ollama:
        return 'No key required for Ollama';
    }
  }

  String get keyUrl {
    switch (this) {
      case AiProvider.ollama:
        return 'localhost:11434';
    }
  }
}

/// Immutable config read from local storage.
class AiConfig {
  final AiProvider provider;
  final String model;
  final String baseUrl;

  const AiConfig({
    this.provider = AiProvider.ollama,
    required this.model,
    required this.baseUrl,
  });

  bool get isValid {
    return baseUrl.trim().isNotEmpty && model.trim().isNotEmpty;
  }
}

/// Kết quả AI cho 1 sub-criteria.
class AiSubScore {
  final String subId;
  final double score;
  final String reason;

  const AiSubScore({
    required this.subId,
    required this.score,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'subId': subId,
        'score': score,
        'reason': reason,
      };

  factory AiSubScore.fromJson(Map<String, dynamic> json) => AiSubScore(
        subId: json['subId'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String? ?? '',
      );
}

/// Kết quả AI cho 1 criterion.
class AiCriterionResult {
  final String criterionId;
  final List<AiSubScore> subScores;
  final String generalComment;

  const AiCriterionResult({
    required this.criterionId,
    required this.subScores,
    required this.generalComment,
  });

  Map<String, dynamic> toJson() => {
        'criterionId': criterionId,
        'generalComment': generalComment,
        'subScores': subScores.map((s) => s.toJson()).toList(),
      };

  factory AiCriterionResult.fromJson(Map<String, dynamic> json) {
    final subs = (json['subScores'] as List<dynamic>? ?? [])
        .map((e) => AiSubScore.fromJson(e as Map<String, dynamic>))
        .toList();
    return AiCriterionResult(
      criterionId: json['criterionId'] as String? ?? '',
      subScores: subs,
      generalComment: json['generalComment'] as String? ?? '',
    );
  }
}

/// AI service exception.
class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => 'AiServiceException: $message';
}

/// Default model lists per provider.
class AiModelCatalog {
  static List<String> modelsFor(AiProvider provider) {
    switch (provider) {
      case AiProvider.ollama:
        return const [
          'qwen2.5:7b',
          'llama3.2:3b',
          'gemma3:4b',
          'llama3.1:8b',
        ];
    }
  }

  static String defaultModel(AiProvider provider) => modelsFor(provider).first;

  static String modelDescription(AiProvider provider, String model) {
    if (provider == AiProvider.ollama) {
      switch (model) {
        case 'qwen2.5:7b':
          return 'Qwen 2.5 7B (Khuyên dùng/Đang dùng)';
        case 'llama3.2:3b':
          return 'Llama 3.2 3B';
        case 'gemma3:4b':
          return 'Gemma 3 4B';
        case 'llama3.1:8b':
          return 'Llama 3.1 8B';
      }
      return 'Local Ollama Model';
    }
    return '';
  }
}

