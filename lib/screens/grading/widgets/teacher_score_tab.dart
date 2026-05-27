import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/app_models.dart';
import '../../../core/providers/app_state_provider.dart';

class TeacherScoreTab extends StatefulWidget {
  final StudentSubmission student;

  const TeacherScoreTab({super.key, required this.student});

  @override
  State<TeacherScoreTab> createState() => _TeacherScoreTabState();
}

class _TeacherScoreTabState extends State<TeacherScoreTab> {
  final Map<String, TextEditingController> _scoreControllers = {};
  String _lastAlias = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(TeacherScoreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.student.alias != _lastAlias) {
      _initControllers();
    }
  }

  void _initControllers() {
    for (final ctrl in _scoreControllers.values) {
      ctrl.dispose();
    }
    _scoreControllers.clear();

    for (final criterion in widget.student.criteria) {
      for (final sub in criterion.subCriteria) {
        final key = '${criterion.id}_${sub.id}';
        
        final currentScore = sub.manualScore ?? sub.aiScore;
        final scoreText = currentScore != null
            ? currentScore.toStringAsFixed(currentScore == currentScore.roundToDouble() ? 0 : 1)
            : '';
            
        _scoreControllers[key] = TextEditingController(text: scoreText);
      }
    }
    _lastAlias = widget.student.alias;
  }

  @override
  void dispose() {
    for (final ctrl in _scoreControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.student.criteria.length,
      itemBuilder: (context, index) {
        final criterion = widget.student.criteria[index];
        return _TeacherCriterionCard(
          criterion: criterion,
          student: widget.student,
          scoreControllers: _scoreControllers,
          state: state,
        );
      },
    );
  }
}

class _TeacherCriterionCard extends StatelessWidget {
  final GradingCriterion criterion;
  final StudentSubmission student;
  final Map<String, TextEditingController> scoreControllers;
  final AppStateProvider state;

  const _TeacherCriterionCard({
    required this.criterion,
    required this.student,
    required this.scoreControllers,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final total = criterion.totalScore;
    final max = criterion.totalMaxScore;
    final pct = max > 0 ? total / max : 0.0;
    final barColor = pct >= 0.8 ? AppColors.success : pct >= 0.65 ? AppColors.warning : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border0),
      ),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bg4,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_shared_outlined, size: 14, color: AppColors.textSecondary),
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
                      '${total.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: barColor,
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
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          
          // Rubrics list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: criterion.subCriteria.map((sub) {
                final key = '${criterion.id}_${sub.id}';
                final scoreCtrl = scoreControllers[key];

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
                      // First Row: ID, Title, Max Score, Input Field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Score Input
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 28,
                                child: TextField(
                                  controller: scoreCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: AppColors.bg2,
                                    filled: true,
                                    hintText: '—',
                                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.border0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.border0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: AppColors.accent),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    state.updateSubCriteriaScore(
                                      criterion.id,
                                      sub.id,
                                      val,
                                      null,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${sub.maxScore.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      // Sub description
                      Text(
                        sub.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'Inter',
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      // Second Row: Quick Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildQuickScoreButton('Full', sub.maxScore, sub, scoreCtrl, criterion.id),
                          _buildQuickScoreButton('75%', sub.maxScore * 0.75, sub, scoreCtrl, criterion.id),
                          _buildQuickScoreButton('50%', sub.maxScore * 0.5, sub, scoreCtrl, criterion.id),
                          _buildQuickScoreButton('0', 0, sub, scoreCtrl, criterion.id, isDanger: true),
                        ],
                      ),
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

  Widget _buildQuickScoreButton(
    String label,
    double value,
    SubCriteria sub,
    TextEditingController? scoreCtrl,
    String criterionId, {
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: () {
        final valText = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
        scoreCtrl?.text = valText;
        state.updateSubCriteriaScore(criterionId, sub.id, value, null);
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isDanger ? AppColors.dangerBg : AppColors.bg4,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDanger ? AppColors.danger.withOpacity(0.2) : AppColors.border0),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDanger ? AppColors.danger : AppColors.textSecondary,
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
