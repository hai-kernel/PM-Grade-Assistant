import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../widgets/ai_settings_dialog.dart';

class AISuggestionTab extends StatelessWidget {
  final StudentSubmission student;

  const AISuggestionTab({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final hasAnyAIScore = student.criteria.any(
      (c) => c.subCriteria.any((sc) => sc.aiScore != null),
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // AI Grading Action Card
        _AiActionCard(student: student, state: state),

        // Error message
        if (state.aiErrorMessage != null) ...[
          const SizedBox(height: 8),
          _AiErrorBanner(
            message: state.aiErrorMessage!,
            onDismiss: () => state.clearAIError(),
            onOpenSettings: () => AiSettingsDialog.show(context),
          ),
        ],

        const SizedBox(height: 12),

        // Results
        if (!hasAnyAIScore && !state.isLoadingAI)
          _EmptyStateCard()
        else
          ...student.criteria.map(
            (criterion) => _AICriterionCard(
              criterion: criterion,
              student: student,
              state: state,
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }
}

/// Card with "Run AI Grading" button + apply all scores button
class _AiActionCard extends StatelessWidget {
  final StudentSubmission student;
  final AppStateProvider state;

  const _AiActionCard({required this.student, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.isLoadingAI;
    final hasAnyAIScore = student.criteria.any(
      (c) => c.subCriteria.any((sc) => sc.aiScore != null),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg4,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chấm điểm tự động',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? 'Đang phân tích bài làm...'
                          : hasAnyAIScore
                              ? 'Đã có kết quả AI. Bấm lại để chấm lại.'
                              : 'Gọi AI để chấm bài sinh viên này.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => state.runAIGrading(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.purple.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    isLoading
                        ? 'Đang chạy AI...'
                        : hasAnyAIScore
                            ? 'Chạy lại AI'
                            : 'Chạy AI chấm bài',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ),
              if (hasAnyAIScore) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _applyAllAIScores(context, state, student),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(
                        color: AppColors.success.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text(
                    'Áp dụng tất cả',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _applyAllAIScores(
      BuildContext context, AppStateProvider state, StudentSubmission student) {
    for (final criterion in student.criteria) {
      for (final sub in criterion.subCriteria) {
        if (sub.aiScore != null) {
          state.updateSubCriteriaScore(
            criterion.id,
            sub.id,
            sub.aiScore,
            null,
          );
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã áp dụng tất cả điểm AI → điểm giáo viên.',
            style: TextStyle(fontFamily: 'Inter')),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Error banner with dismiss + settings link
class _AiErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onOpenSettings;

  const _AiErrorBanner({
    required this.message,
    required this.onDismiss,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final showSettingsLink = message.contains('cấu hình') ||
        message.contains('Ollama') ||
        message.contains('Model') ||
        message.contains('kết nối') ||
        message.contains('API');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.danger,
                    height: 1.4,
                  ),
                ),
                if (showSettingsLink) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onOpenSettings,
                    child: const Text(
                      '→ Mở AI Settings',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 14, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no AI scores yet
class _EmptyStateCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border0),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined,
              size: 36, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có kết quả AI',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bấm "Chạy AI chấm bài" ở trên để bắt đầu.',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _AICriterionCard extends StatefulWidget {
  final GradingCriterion criterion;
  final StudentSubmission student;
  final AppStateProvider state;

  const _AICriterionCard({
    required this.criterion,
    required this.student,
    required this.state,
  });

  @override
  State<_AICriterionCard> createState() => _AICriterionCardState();
}

class _AICriterionCardState extends State<_AICriterionCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final criterion = widget.criterion;
    final totalAI = criterion.subCriteria
        .fold<double>(0.0, (sum, sc) => sum + (sc.aiScore ?? 0));
    final max = criterion.totalMaxScore;
    final pct = max > 0 ? totalAI / max : 0.0;
    final hasAnyScore = criterion.subCriteria.any((sc) => sc.aiScore != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border0),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(8),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bg4,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: _isExpanded
                      ? Radius.zero
                      : const Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${criterion.id} — ${criterion.name}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (hasAnyScore)
                        Text(
                          'AI gợi ý: ${totalAI.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        )
                      else
                        const Text(
                          'Chưa chấm',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                    ],
                  ),
                  if (hasAnyScore) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: AppColors.bg2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.purple),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Sub criteria items
          if (_isExpanded && hasAnyScore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: criterion.subCriteria.map((sub) {
                  return _SubCriteriaRow(
                    sub: sub,
                    criterion: criterion,
                    state: widget.state,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubCriteriaRow extends StatelessWidget {
  final SubCriteria sub;
  final GradingCriterion criterion;
  final AppStateProvider state;

  const _SubCriteriaRow({
    required this.sub,
    required this.criterion,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final hasAIScore = sub.aiScore != null;
    final isApplied =
        sub.manualScore != null && sub.manualScore == sub.aiScore;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border0, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.bg4,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  sub.id,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sub.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (hasAIScore)
                Text(
                  '${sub.aiScore!.toStringAsFixed(1)}/${sub.maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                )
              else
                Text(
                  '—/${sub.maxScore.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            sub.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontFamily: 'Inter',
              height: 1.4,
            ),
          ),
          if (sub.aiReason != null && sub.aiReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.purpleBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.purple.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.0),
                    child: Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.purple),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sub.aiReason!,
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Apply single score button
          if (hasAIScore) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: isApplied
                    ? null
                    : () {
                        state.updateSubCriteriaScore(
                          criterion.id,
                          sub.id,
                          sub.aiScore,
                          null,
                        );
                      },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isApplied
                        ? AppColors.successBg
                        : AppColors.accentBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isApplied
                              ? AppColors.success
                              : AppColors.accent)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApplied
                            ? Icons.check
                            : Icons.arrow_forward_rounded,
                        size: 12,
                        color: isApplied
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isApplied
                            ? 'Đã áp dụng'
                            : 'Dùng điểm AI này',
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: isApplied
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
