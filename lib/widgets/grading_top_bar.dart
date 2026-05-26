import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/app_state_provider.dart';
import '../core/models/app_models.dart';

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
            label: 'Setup',
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
        ],
      ),
    );
  }
}

class _NavStudentButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final students = state.displayedStudents;
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
