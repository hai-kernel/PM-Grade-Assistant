import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/providers/app_state_provider.dart';

class ScoringOverviewTab extends StatefulWidget {
  final StudentSubmission student;

  const ScoringOverviewTab({super.key, required this.student});

  @override
  State<ScoringOverviewTab> createState() => _ScoringOverviewTabState();
}

class _ScoringOverviewTabState extends State<ScoringOverviewTab> {
  final Map<String, TextEditingController> _commentControllers = {};
  String _lastAlias = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(ScoringOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.alias != _lastAlias) {
      _initControllers();
    }
  }

  void _initControllers() {
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    _commentControllers.clear();

    for (final criterion in widget.student.criteria) {
      _commentControllers[criterion.id] = TextEditingController(text: criterion.generalComment ?? '');
    }
    _lastAlias = widget.student.alias;
  }

  @override
  void dispose() {
    for (final ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _fillAIComment(GradingCriterion criterion, AppStateProvider state) {
    final parts = criterion.subCriteria
        .where((sc) => sc.aiReason != null && sc.aiReason!.trim().isNotEmpty)
        .map((sc) => sc.aiReason!.trim())
        .toList();
        
    final comment = parts.isNotEmpty 
        ? parts.join(' ') 
        : 'Yêu cầu đáp ứng tốt, không phát hiện lỗi trừ điểm.';
        
    final ctrl = _commentControllers[criterion.id];
    if (ctrl != null) {
      ctrl.text = comment;
      state.updateCriterionGeneralComment(criterion.id, comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final total = widget.student.computedTotal;
    final maxTotal = widget.student.maxTotal;
    final scaleScore = widget.student.computedScale10;

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Total Score Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'TỔNG ĐIỂM CHẤM',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      scaleScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/10',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Điểm chi tiết: ${total.toStringAsFixed(1)} / ${maxTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Question summary list
          ...widget.student.criteria.map((criterion) {
            final key = criterion.id;
            final ctrl = _commentControllers[key];
            
            final qTotal = criterion.totalScore;
            final qMax = criterion.totalMaxScore;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Criterion Summary Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${criterion.id} — ${criterion.name}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${qTotal.toStringAsFixed(1)} / ${qMax.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Comment Label + AI Sugest Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhận xét riêng tư câu:',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                      
                      // AI suggestion populator button
                      InkWell(
                        onTap: () => _fillAIComment(criterion, state),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purpleBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.purple.withOpacity(0.15)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 10, color: AppColors.purple),
                              SizedBox(width: 3),
                              Text(
                                'Lấy nhận xét gợi ý AI',
                                style: TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Comment Text Field
                  TextField(
                    controller: ctrl,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontFamily: 'Inter',
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập nhận xét riêng tư cho câu hỏi này...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      fillColor: AppColors.bg2,
                      filled: true,
                      contentPadding: const EdgeInsets.all(8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.border0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                    onChanged: (v) {
                      state.updateCriterionGeneralComment(
                        criterion.id,
                        v.isEmpty ? null : v,
                      );
                    },
                  ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Save / Finalize Button
          ElevatedButton.icon(
            onPressed: widget.student.status == GradingStatus.graded
                ? null
                : () async {
                    final path = await state.finalizeAndSaveGrading();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          path != null
                              ? 'Đã lưu bài ${widget.student.alias}. Xuất CSV khi chấm xong tất cả.'
                              : 'Không lưu được bài ${widget.student.alias}.',
                          style: const TextStyle(fontFamily: 'Inter'),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    final next = state.nextUngradedStudent;
                    if (next != null) state.selectStudent(next);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: Icon(
              widget.student.status == GradingStatus.graded
                  ? Icons.check_circle_rounded
                  : Icons.save_rounded,
              size: 18,
            ),
            label: Text(
              widget.student.status == GradingStatus.graded
                  ? 'Đã lưu bài này'
                  : 'Lưu bài này',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
