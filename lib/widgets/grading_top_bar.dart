import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/app_state_provider.dart';
import 'ai_settings_dialog.dart';

class GradingTopBar extends StatelessWidget {
  final bool studentPanelVisible;
  final VoidCallback? onToggleStudentPanel;

  const GradingTopBar({
    super.key,
    this.studentPanelVisible = true,
    this.onToggleStudentPanel,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final pct = state.students.isEmpty ? 0.0 : state.gradedCount / state.students.length;

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(bottom: BorderSide(color: AppColors.border0)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          if (onToggleStudentPanel != null) ...[
            Tooltip(
              message: studentPanelVisible
                  ? 'Ẩn danh sách sinh viên'
                  : 'Hiện danh sách sinh viên',
              child: _TopBarButton(
                icon: studentPanelVisible
                    ? Icons.vertical_split_outlined
                    : Icons.people_alt_outlined,
                label: studentPanelVisible ? 'Ẩn DS SV' : 'DS SV',
                onTap: onToggleStudentPanel,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: AppColors.border0),
            const SizedBox(width: 8),
          ],
          // Back to setup
          _TopBarButton(
            icon: Icons.arrow_back,
            label: 'Quay lại',
            onTap: () => state.navigateTo(AppScreen.setup),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 20, color: AppColors.border0),
          const SizedBox(width: 12),
          // Current file context
          const Icon(Icons.folder_open_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(state.currentSessionName ?? 'PMG201c / SP26',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
          const SizedBox(width: 16),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg4,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 13, color: AppColors.success),
                const SizedBox(width: 5),
                Text('${state.gradedCount}/${state.students.length} đã chấm',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Inter')),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.bg2,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.successLight, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Spacer(),
          // Nav buttons for prev/next student
          _NavStudentButtons(),
          const SizedBox(width: 12),
          Container(width: 1, height: 20, color: AppColors.border0),
          const SizedBox(width: 12),
          // AI Settings
          _TopBarButton(
            icon: Icons.auto_awesome,
            label: 'AI Settings',
            onTap: () => AiSettingsDialog.show(context),
          ),
          const SizedBox(width: 8),
          // (Export button removed)
        ],
      ),
    );
  }

  void _showExportAllDialog(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bg1,
        child: Container(
          width: 500,
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
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Xuất toàn bộ điểm Excel', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiến độ chấm điểm:', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 14)),
                        Text('${state.gradedCount} / ${state.students.length} bài', style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: state.students.isEmpty ? 0 : state.gradedCount / state.students.length,
                      backgroundColor: AppColors.bg4,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    if (state.gradedCount < state.students.length) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cảnh báo: Chưa chấm hết. Các bài chưa lưu sẽ để trống trong file Excel.',
                              style: TextStyle(color: AppColors.warning, fontFamily: 'Inter', fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final path = await state.exportAllGradesToExcel();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            path != null
                                ? 'Đã xuất Excel: $path'
                                : 'Hủy xuất file hoặc không lưu được.',
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Xác nhận Xuất File', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcelPreviewTable(AppStateProvider state) {
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

    // Row 3+: Student rows (take up to 6 students)
    final demoStudents = state.students;

    for (final student in demoStudents.take(6)) {
      final qScores = <String>[];
      final currentCriteria = student.criteria;

      for (int i = 0; i < 5; i++) {
        if (currentCriteria.length > i) {
          final earned = currentCriteria[i].totalScore;
          qScores.add(earned.toStringAsFixed(1));
        } else {
          qScores.add('0.0');
        }
      }

      final studentTotal = student.computedTotal;

      rows.add(
        TableRow(
          children: [
            cell(student.alias, align: Alignment.center),
            cell(student.marker ?? '', align: Alignment.center),
            cell(qScores[0]),
            cell(qScores[1]),
            cell(qScores[2]),
            cell(qScores[3]),
            cell(qScores[4]),
            cell(studentTotal.toStringAsFixed(1), isBold: true, textColor: totalColor),
            cell(student.finalPublicComment, align: Alignment.centerLeft),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border0),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 850,
          child: Table(
            border: TableBorder.all(color: AppColors.border0.withOpacity(0.5), width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(90),   // Alias
              1: FixedColumnWidth(90),   // Marker
              2: FixedColumnWidth(85),   // Q1
              3: FixedColumnWidth(85),   // Q2
              4: FixedColumnWidth(85),   // Q3
              5: FixedColumnWidth(85),   // Q4
              6: FixedColumnWidth(85),   // Q5
              7: FixedColumnWidth(75),   // Total
              8: FlexColumnWidth(),      // Comment
            },
            children: rows,
          ),
        ),
      ),
    );
  }
}

class _NavStudentButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final students = state.students;
    final selected = state.selectedStudent;
    final idx = selected == null ? -1 : students.indexWhere((s) => s.alias == selected.alias);

    return Row(
      children: [
        _TopBarButton(
          icon: Icons.chevron_left,
          label: 'Trước',
          onTap: idx > 0 ? () => state.selectStudent(students[idx - 1]) : null,
        ),
        const SizedBox(width: 4),
        if (selected != null)
          Text('${idx + 1} / ${students.length}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter')),
        const SizedBox(width: 4),
        _TopBarButton(
          icon: Icons.chevron_right,
          label: 'Tiếp',
          onTap: idx >= 0 && idx < students.length - 1
              ? () => state.selectStudent(students[idx + 1])
              : null,
        ),
      ],
    );
  }
}

class _TopBarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;

  const _TopBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.accent
                ? (_hovered ? AppColors.accentDark : AppColors.accent)
                : (_hovered && !disabled ? AppColors.bg4 : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border: widget.accent ? null : Border.all(color: _hovered && !disabled ? AppColors.border1 : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: disabled
                    ? AppColors.textDisabled
                    : widget.accent
                        ? Colors.white
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  color: disabled
                      ? AppColors.textDisabled
                      : widget.accent
                          ? Colors.white
                          : AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
