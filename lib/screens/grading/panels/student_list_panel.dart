import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/models/app_models.dart';

class StudentListPanel extends StatefulWidget {
  final VoidCallback? onHidePanel;

  const StudentListPanel({super.key, this.onHidePanel});

  @override
  State<StudentListPanel> createState() => _StudentListPanelState();
}

class _StudentListPanelState extends State<StudentListPanel> {
  String _searchQuery = '';
  String _filter = 'all'; // all | ungraded | graded | inProgress

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final students = state.students.where((s) {
      final matchSearch = _searchQuery.isEmpty ||
          s.alias.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchFilter = _filter == 'all' ||
          (_filter == 'graded' && s.status == GradingStatus.graded) ||
          (_filter == 'ungraded' && s.status == GradingStatus.ungraded) ||
          (_filter == 'inProgress' && s.status == GradingStatus.inProgress);
      return matchSearch && matchFilter;
    }).toList();

    return Container(
      color: AppColors.bg2,
      child: Column(
        children: [
          _buildHeader(state),
          _buildSearch(),
          _buildFilterTabs(state),
          const Divider(height: 1, color: AppColors.border0),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, i) => _StudentTile(
                student: students[i],
                isSelected: state.selectedStudent?.alias == students[i].alias,
                onTap: () => state.selectStudent(students[i]),
              ),
            ),
          ),
          _buildFooter(state),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStateProvider state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border0)),
      ),
      child: Row(
        children: [
          if (widget.onHidePanel != null)
            Tooltip(
              message: 'Ẩn panel (kéo divider trái hoặc double-click)',
              child: IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    size: 18, color: AppColors.textMuted),
                onPressed: widget.onHidePanel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                splashRadius: 16,
              ),
            ),
          const Icon(Icons.people_alt_outlined,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Sinh viên',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${state.students.length}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sinh viên...',
          prefixIcon: const Icon(Icons.search, size: 15, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          fillColor: AppColors.bg3,
          filled: true,
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
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter'),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AppStateProvider state) {
    final tabs = [
      ('all', 'Tất cả', state.students.length),
      ('ungraded', 'Chưa chấm', state.ungradedCount),
      ('inProgress', 'Đang chấm', state.inProgressCount),
      ('graded', 'Đã chấm', state.gradedCount),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _filter == tab.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = tab.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.accent.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              child: Text(
                '${tab.$2} (${tab.$3})',
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(AppStateProvider state) {
    final pct = state.students.isEmpty ? 0.0 : state.gradedCount / state.students.length;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border0)),
        color: AppColors.bg2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Tiến độ chấm: ${state.gradedCount}/${state.students.length}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Inter')),
                    const Spacer(),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.bg4,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatefulWidget {
  final StudentSubmission student;
  final bool isSelected;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.isSelected, required this.onTap});

  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (widget.student.status) {
      case GradingStatus.graded:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case GradingStatus.inProgress:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusIcon = Icons.radio_button_unchecked;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent.withOpacity(0.12)
                : _hovered
                    ? AppColors.bg3
                    : Colors.transparent,
            border: widget.isSelected
                ? const Border(left: BorderSide(color: AppColors.accent, width: 2))
                : const Border(left: BorderSide(color: Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, size: 13, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.student.alias,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.student.finalScaleScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _scoreColor(widget.student.finalScaleScore!).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.student.finalScaleScore!.toStringAsFixed(1),
                    style: TextStyle(
                      color: _scoreColor(widget.student.finalScaleScore!),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8) return AppColors.success;
    if (score >= 6.5) return AppColors.warning;
    return AppColors.danger;
  }
}
