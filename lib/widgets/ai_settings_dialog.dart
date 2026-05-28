import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/models/ai_models.dart';
import '../core/services/ai_config_service.dart';
import '../core/services/ai_service_factory.dart';

/// Dialog cấu hình AI: chọn Provider (cố định Ollama), nhập Base URL, chọn Model.
class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AiSettingsDialog(),
    );
  }

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testingConnection = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await AiConfigService.instance.getConfig();
    if (mounted) {
      setState(() {
        _baseUrlController.text = config.baseUrl.isNotEmpty ? config.baseUrl : 'http://localhost:11434';
        _modelController.text = config.model.isNotEmpty ? config.model : 'qwen2.5:7b';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AiConfigService.instance.saveConfig(AiConfig(
      model: _modelController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
    ));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình AI thành công!',
              style: TextStyle(fontFamily: 'Inter')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    final baseUrl = _baseUrlController.text.trim();
    final modelName = _modelController.text.trim();
    if (baseUrl.isEmpty || modelName.isEmpty) {
      setState(() {
        _testResult = 'Vui lòng nhập Base URL và Model trước.';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _testingConnection = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      final service = AIServiceFactory.createForTest(
        model: modelName,
        baseUrl: baseUrl,
      );
      final ok = await service.testConnection();

      if (mounted) {
        setState(() {
          if (ok) {
            _testResult =
                'Kết nối Ollama thành công! Model "$modelName" sẵn sàng.';
            _testSuccess = true;
          } else {
            _testResult =
                'Không kết nối được tới Ollama. Vui lòng kiểm tra lại URL hoặc chạy "ollama serve".';
            _testSuccess = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = 'Lỗi: ${e is AiServiceException ? e.message : e.toString()}';
          _testSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        fillColor: AppColors.bg2,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  BoxDecoration _dropdownBox() => BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border0),
      );

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.bg1,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildProviderSelector(),
                    const SizedBox(height: 16),
                    _buildBaseUrlField(),
                    const SizedBox(height: 16),
                    _buildModelSelector(),
                    const SizedBox(height: 16),
                    _buildTestButton(),
                    if (_testResult != null) ...[
                      const SizedBox(height: 8),
                      _buildTestResult(),
                    ],
                    const SizedBox(height: 20),
                    _buildInstructionsBox(),
                    const SizedBox(height: 20),
                    _buildActions(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.purpleBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.purple, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình AI Local',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cấu hình kết nối tới server Ollama cục bộ',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 18,
                color: AppColors.textMuted),
            splashRadius: 16,
          ),
        ],
      );

  Widget _buildProviderSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('AI Provider'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: _dropdownBox(),
            child: const Row(
              children: [
                Icon(Icons.computer_rounded, size: 16, color: AppColors.purple),
                const SizedBox(width: 8),
                Text(
                  'Ollama Local (Offline)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildBaseUrlField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ollama Base URL'),
          TextField(
            controller: _baseUrlController,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hint: 'http://localhost:11434',
            ),
          ),
        ],
      );

  Widget _buildModelSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Model AI'),
          TextField(
            controller: _modelController,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            decoration: _inputDecoration(
              hint: 'qwen2.5:7b',
            ),
          ),
        ],
      );

  Widget _buildTestButton() => Row(
        children: [
          OutlinedButton.icon(
            onPressed: _testingConnection ? null : _testConnection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              side: const BorderSide(color: AppColors.purple),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: _testingConnection
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.purple),
                  )
                : const Icon(Icons.network_check, size: 16),
            label: Text(
              _testingConnection ? 'Đang kiểm tra...' : 'Kiểm tra kết nối',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
        ],
      );

  Widget _buildTestResult() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              _testSuccess == true ? AppColors.successBg : AppColors.dangerBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: (_testSuccess == true ? AppColors.success : AppColors.danger)
                .withOpacity(0.3),
          ),
        ),
        child: Text(
          _testResult!,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color:
                _testSuccess == true ? AppColors.success : AppColors.danger,
            height: 1.4,
          ),
        ),
      );

  Widget _buildInstructionsBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, size: 14, color: AppColors.purple),
                const SizedBox(width: 6),
                const Text(
                  'Hướng dẫn cài đặt AI Local:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '1. Cài đặt Ollama từ trang chủ (https://ollama.com)\n'
              '2. Mở terminal và chạy lệnh tải model:\n'
              '   ollama pull qwen2.5:7b\n'
              '3. Đảm bảo Ollama đang chạy trên máy (ollama serve)\n'
              '4. Nhập URL & model ở trên và bấm "Kiểm tra kết nối" để thử nghiệm.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );

  Widget _buildActions() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              _saving ? 'Đang lưu...' : 'Lưu cấu hình',
              style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
}
