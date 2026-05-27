import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/models/app_models.dart';
import '../widgets/scoring_overview_tab.dart';
import '../widgets/teacher_score_tab.dart';
import '../widgets/ai_suggestion_tab.dart';

class ScoringPanel extends StatefulWidget {
  const ScoringPanel({super.key});

  @override
  State<ScoringPanel> createState() => _ScoringPanelState();
}

class _ScoringPanelState extends State<ScoringPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final student = state.selectedStudent;

    return Container(
      color: AppColors.bg2,
      child: Column(
        children: [
          _buildHeader(student),
          if (student != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Điểm giáo viên'),
                  Tab(text: 'AI gợi ý'),
                ],
              ),
            ),
          if (student == null)
            const Expanded(
              child: Center(
                child: Text(
                  'Chọn sinh viên để xem barem điểm',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Inter'),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ScoringOverviewTab(student: student),
                        TeacherScoreTab(student: student),
                        AISuggestionTab(student: student),
                      ],
                    ),
                  ),
                  if (student.status != GradingStatus.graded)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _buildGradingHint(context, state, student),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(StudentSubmission? student) {
    final total = student?.computedTotal ?? 0;
    final max = student?.maxTotal ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.bg3,
        border: Border(bottom: BorderSide(color: AppColors.border0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rule_folder_outlined, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text(
            'Barem chấm điểm',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          if (student != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Text(
                '${total.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradingHint(
    BuildContext context,
    AppStateProvider state,
    StudentSubmission student,
  ) {
    final isGraded = student.status == GradingStatus.graded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isGraded ? AppColors.successBg : AppColors.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGraded
              ? AppColors.success.withOpacity(0.25)
              : AppColors.border0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGraded ? Icons.check_circle_outline : Icons.info_outline,
            size: 16,
            color: isGraded ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isGraded
                  ? 'Bài đã lưu. Dùng「Export All CSV」trên thanh menu khi chấm xong.'
                  : 'Chấm xong → bấm「Lưu bài này」ở panel giữa. Không cần export từng bài.',
              style: TextStyle(
                fontSize: 11,
                color: isGraded ? AppColors.success : AppColors.textSecondary,
                fontFamily: 'Inter',
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

