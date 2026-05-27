import '../models/ai_models.dart';
import 'ai_service.dart';
import 'ollama_ai_service.dart';

/// Factory — tạo AIService tương ứng dựa trên config.
class AIServiceFactory {
  /// Tạo [AIService] instance từ [AiConfig].
  static AIService create(AiConfig config) {
    if (!config.isValid) {
      throw const AiServiceException(
        'Chưa cấu hình Ollama. Vào AI Settings để nhập Base URL và Model.',
      );
    }

    switch (config.provider) {
      case AiProvider.ollama:
        return OllamaAiService(baseUrl: config.baseUrl, model: config.model);
    }
  }

  /// Tạo AIService chỉ để test connection (dùng trong Settings dialog).
  static AIService createForTest({
    required String model,
    String baseUrl = 'http://localhost:11434',
  }) {
    return create(AiConfig(
      provider: AiProvider.ollama,
      model: model,
      baseUrl: baseUrl,
    ));
  }
}

