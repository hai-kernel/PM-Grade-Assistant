import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/app_models.dart';

class AISuggestionTab extends StatelessWidget {
  final StudentSubmission student;

  const AISuggestionTab({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: student.criteria.length,
      itemBuilder: (context, index) {
        final criterion = student.criteria[index];
        return _AICriterionCard(criterion: criterion);
      },
    );
  }
}

class _AICriterionCard extends StatefulWidget {
  final GradingCriterion criterion;

  const _AICriterionCard({required this.criterion});

  @override
  State<_AICriterionCard> createState() => _AICriterionCardState();
}

class _AICriterionCardState extends State<_AICriterionCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final criterion = widget.criterion;
    final totalAI = criterion.subCriteria.fold<double>(0.0, (sum, sc) => sum + (sc.aiScore ?? 0));
    final max = criterion.totalMaxScore;
    final pct = max > 0 ? totalAI / max : 0.0;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bg4,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(8),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
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
                      Text(
                        'AI gợi ý: ${totalAI.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: AppColors.bg2,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sub criteria items
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: criterion.subCriteria.map((sub) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.bg4,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                sub.id,
                                style: const TextStyle(
                                  color: AppColors.accentLight,
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
                            Text(
                              '${sub.aiScore?.toStringAsFixed(1) ?? '—'}/${sub.maxScore.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                        if (sub.aiReason != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.purple.withOpacity(0.15)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1.0),
                                  child: Icon(Icons.auto_awesome, size: 12, color: AppColors.purple),
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
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
