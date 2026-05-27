import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_models.dart';

/// Quản lý cấu hình AI — lưu Base URL và Model của Ollama vào SharedPreferences.
class AiConfigService {
  static AiConfigService? _instance;
  static AiConfigService get instance => _instance ??= AiConfigService._();
  AiConfigService._();

  static const String _keyBaseUrl = 'ollama_base_url';
  static const String _keyModel = 'ollama_model';

  // ─── Provider ──────────────────────────────────────────────
  // Luôn trả về Ollama vì ứng dụng đã chuyển sang chỉ dùng Ollama Local
  Future<AiProvider> getProvider() async => AiProvider.ollama;

  Future<void> saveProvider(AiProvider provider) async {}

  // ─── Base URL ────────────────────────────────────────────────
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_keyBaseUrl);
    if (url != null && url.isNotEmpty) return url;
    return 'http://localhost:11434';
  }

  Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url.trim());
  }

  // ─── Model Name ──────────────────────────────────────────────
  Future<String> getModelName() async {
    final prefs = await SharedPreferences.getInstance();
    final model = prefs.getString(_keyModel);
    if (model != null && model.isNotEmpty) return model;
    return 'qwen2.5:7b';
  }

  Future<void> saveModelName(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModel, model.trim());
  }

  // ─── Composite ───────────────────────────────────────────────
  /// Đọc toàn bộ config 1 lần.
  Future<AiConfig> getConfig() async {
    final model = await getModelName();
    final baseUrl = await getBaseUrl();
    return AiConfig(
      provider: AiProvider.ollama,
      model: model,
      baseUrl: baseUrl,
    );
  }

  /// Lưu toàn bộ config 1 lần.
  Future<void> saveConfig(AiConfig config) async {
    await saveBaseUrl(config.baseUrl);
    await saveModelName(config.model);
  }

  /// Xóa cache (giữ lại signature để không lỗi compile).
  void invalidateCache() {}
}

