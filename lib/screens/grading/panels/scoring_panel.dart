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
                labelColor: AppColors.accentLight,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildExportButton(context, state),
                    ),
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
                  color: AppColors.accentLight,
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

  Widget _buildExportButton(BuildContext context, AppStateProvider state) {
    final student = state.selectedStudent;
    return ElevatedButton.icon(
      onPressed: student == null ? null : () => _showExportDialog(context, student),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.upload_file_rounded, size: 16),
      label: const Text(
        'Export to CSV',
        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  void _showExportDialog(BuildContext context, StudentSubmission student) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bg1,
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.upload_file_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Lưu điểm sinh viên này',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Bạn có muốn ghi đè điểm của sinh viên này vào file Mark Input CSV ban đầu không?',
                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xem trước dữ liệu bảng điểm Excel:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildExcelPreviewSingleTable(student),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã ghi đè vào file gốc thành công!', style: TextStyle(fontFamily: 'Inter')),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bg4,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                    ),
                    child: const Text('Ghi đè file gốc', style: TextStyle(fontFamily: 'Inter')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã tạo file CSV mới!', style: TextStyle(fontFamily: 'Inter')),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Tạo file mới', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildExcelPreviewSingleTable(StudentSubmission student) {
  const headerBg = Color(0xFFFCE4D6);
  const commentBg = Color(0xFFFFFF00);
  const totalColor = Color(0xFF002060);

  Widget cell(String text, {Color? bg, bool isBold = false, Color? textColor, Alignment align = Alignment.center}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: bg ?? AppColors.bg0,
      alignment: align,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  final rows = <TableRow>[];

  // Row 1: Headers
  rows.add(
    TableRow(
      children: [
        cell('Alias', bg: headerBg, isBold: true),
        cell('Marker', bg: headerBg, isBold: true),
        cell('Question 1', bg: headerBg, isBold: true),
        cell('Question 2', bg: headerBg, isBold: true),
        cell('Question 3', bg: headerBg, isBold: true),
        cell('Question 4', bg: headerBg, isBold: true),
        cell('Question 5', bg: headerBg, isBold: true),
        cell('Total', bg: headerBg, isBold: true, textColor: totalColor),
        cell('Comment', bg: commentBg, isBold: true, align: Alignment.centerLeft),
      ],
    ),
  );

  // Row 2: Max Points
  rows.add(
    TableRow(
      children: [
        cell('', bg: headerBg),
        cell('', bg: headerBg),
        cell('20', bg: headerBg, isBold: true),
        cell('20', bg: headerBg, isBold: true),
        cell('20', bg: headerBg, isBold: true),
        cell('20', bg: headerBg, isBold: true),
        cell('20', bg: headerBg, isBold: true),
        cell('100', bg: headerBg, isBold: true, textColor: totalColor),
        cell('', bg: commentBg),
      ],
    ),
  );

  // Student score
  final qScores = <String>[];
  final currentCriteria = student.criteria.isNotEmpty 
      ? student.criteria 
      : MockData.getSampleCriteria();

  for (int i = 0; i < 5; i++) {
    if (currentCriteria.length > i) {
      qScores.add(currentCriteria[i].totalScore.toStringAsFixed(1));
    } else {
      qScores.add('0.0');
    }
  }

  rows.add(
    TableRow(
      children: [
        cell(student.alias, align: Alignment.center),
        cell(student.marker ?? 'HungLD5', align: Alignment.center),
        cell(qScores[0]),
        cell(qScores[1]),
        cell(qScores[2]),
        cell(qScores[3]),
        cell(qScores[4]),
        cell(student.computedTotal.toStringAsFixed(1), isBold: true, textColor: totalColor),
        cell(student.finalPublicComment, align: Alignment.centerLeft),
      ],
    ),
  );

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border0),
      borderRadius: BorderRadius.circular(8),
    ),
    clipBehavior: Clip.antiAlias,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 650,
        child: Table(
          border: TableBorder.all(color: AppColors.border0.withOpacity(0.5), width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(80),   // Alias
            1: FixedColumnWidth(80),   // Marker
            2: FixedColumnWidth(70),   // Q1
            3: FixedColumnWidth(70),   // Q2
            4: FixedColumnWidth(70),   // Q3
            5: FixedColumnWidth(70),   // Q4
            6: FixedColumnWidth(70),   // Q5
            7: FixedColumnWidth(60),   // Total
            8: FlexColumnWidth(),      // Comment
          },
          children: rows,
        ),
      ),
    ),
  );
}
