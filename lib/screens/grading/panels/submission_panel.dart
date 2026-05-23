import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/models/app_models.dart';

class SubmissionPanel extends StatefulWidget {
  const SubmissionPanel({super.key});

  @override
  State<SubmissionPanel> createState() => _SubmissionPanelState();
}

class _SubmissionPanelState extends State<SubmissionPanel> {
  final _publicCtrl = TextEditingController();
  final _privateCtrl = TextEditingController();
  String? _lastAlias;
  double? _topHeight;

  @override
  void dispose() {
    _publicCtrl.dispose();
    _privateCtrl.dispose();
    super.dispose();
  }

  void _syncComments(StudentSubmission? student) {
    if (student == null) return;
    if (student.alias != _lastAlias) {
      _publicCtrl.text = student.publicComment;
      _privateCtrl.text = student.privateNote;
      _lastAlias = student.alias;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final student = state.selectedStudent;
    _syncComments(student);

    if (student == null) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.bg1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight;
          const headerHeight = 52.0;
          final usableHeight = totalHeight - headerHeight;

          const minTop = 150.0;
          const minBottom = 200.0;
          final maxTop = usableHeight - minBottom;

          _topHeight ??= usableHeight * 0.55;
          _topHeight = _topHeight!.clamp(minTop, maxTop);

          return Column(
            children: [
              _buildStudentHeader(student),
              SizedBox(
                height: _topHeight,
                child: _buildSubmissionContent(context, state, student),
              ),
              _ResizeDividerVertical(
                onDrag: (dy) => setState(() {
                  _topHeight = (_topHeight! + dy).clamp(minTop, maxTop);
                }),
              ),
              Expanded(
                child: _buildBottomSection(context, state, student),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.bg1,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 56, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Chọn một sinh viên để bắt đầu chấm điểm',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(StudentSubmission student) {
    Color statusColor;
    String statusLabel;
    switch (student.status) {
      case GradingStatus.graded:
        statusColor = AppColors.success;
        statusLabel = 'Đã chấm xong';
        break;
      case GradingStatus.inProgress:
        statusColor = AppColors.warning;
        statusLabel = 'Đang chấm';
        break;
      default:
        statusColor = AppColors.textMuted;
        statusLabel = 'Chưa chấm';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.bg2,
        border: Border(bottom: BorderSide(color: AppColors.border0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.8),
                  AppColors.purple.withOpacity(0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (student.name ?? student.alias)[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    fontFamily: 'Inter'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name ?? student.alias,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                Text(student.alias,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Inter')),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionContent(
      BuildContext context, AppStateProvider state, StudentSubmission student) {
    return Container(
      color: AppColors.bg0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.bg2,
              border: Border(bottom: BorderSide(color: AppColors.border0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.article_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${student.alias}.txt',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showExamDialog(context, state),
                  icon: const Icon(Icons.description_outlined,
                      size: 14, color: AppColors.accent),
                  label: const Text('Xem đề thi',
                      style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                _TabChip(label: 'Bài làm sinh viên', isSelected: true),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  student.fileContent.isEmpty
                      ? '// Nội dung bài làm của sinh viên sẽ hiển thị tại đây\n// File: ${student.filePath}'
                      : student.fileContent,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Consolas',
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExamDialog(BuildContext context, AppStateProvider state) {
    final examPath = state.setupData.examFilePath;
    final examName = state.setupData.examFileName;
    final isImage = _isImagePath(examPath ?? examName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.bg1,
        child: Container(
          width: 900,
          height: 680,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isImage ? Icons.image_outlined : Icons.description_outlined,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      examName ?? 'Nội dung đề thi',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppColors.border0),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg0,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border0),
                  ),
                  child: _buildExamPreview(
                    examPath: examPath,
                    examContent: state.setupData.examContent,
                    isImage: isImage,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white),
                  child:
                      const Text('Đóng', style: TextStyle(fontFamily: 'Inter')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamPreview({
    required String? examPath,
    required String examContent,
    required bool isImage,
  }) {
    if (isImage && examPath != null && examPath.isNotEmpty) {
      final file = File(examPath);
      if (file.existsSync()) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Center(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildExamFallback(
                'Không thể hiển thị ảnh đề thi.\nĐường dẫn: $examPath',
              ),
            ),
          ),
        );
      }
      return _buildExamFallback(
        'Không tìm thấy file đề thi tại:\n$examPath',
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: SelectableText(
          examContent.isEmpty ? 'Chưa tải nội dung đề thi...' : examContent,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildExamFallback(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isImagePath(String pathOrName) {
    final lower = pathOrName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  Widget _buildBottomSection(
      BuildContext context, AppStateProvider state, StudentSubmission student) {
    return Container(
      color: AppColors.bg1,
      child: Column(
        children: [
          // Score summary bar
          _buildScoreSummary(student),
          const Divider(height: 1, color: AppColors.border0),
          // Comments
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentField(
                    context: context,
                    controller: _publicCtrl,
                    label: 'Nhận xét công khai',
                    subtitle: 'Sinh viên sẽ thấy khi nhận bài',
                    icon: Icons.public_rounded,
                    iconColor: AppColors.cyan,
                    bgColor: AppColors.cyanBg,
                    borderColor: AppColors.cyan.withOpacity(0.25),
                    autoText: student.autoPublicComment,
                    onChanged: (v) => state.updateComments(publicComment: v),
                  ),
                  const SizedBox(height: 10),
                  _buildCommentField(
                    context: context,
                    controller: _privateCtrl,
                    label: 'Ghi chú riêng tư',
                    subtitle: 'Chỉ giảng viên thấy',
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.purple,
                    bgColor: AppColors.purpleBg,
                    borderColor: AppColors.purple.withOpacity(0.25),
                    autoText: student.autoPrivateNote,
                    onChanged: (v) => state.updateComments(privateNote: v),
                  ),
                  const SizedBox(height: 12),
                  _buildFinalizeButton(context, state, student),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary(StudentSubmission student) {
    final total = student.computedTotal;
    final max = student.maxTotal;
    final scale10 = student.computedScale10;
    Color scoreColor = scale10 >= 8
        ? AppColors.success
        : scale10 >= 6.5
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: AppColors.bg3),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text('Điểm tổng hợp:',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter')),
          const SizedBox(width: 10),
          Text(
            '${total.toStringAsFixed(1)} / ${max.toStringAsFixed(0)} điểm',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter'),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: scoreColor.withOpacity(0.3)),
            ),
            child: Text(
              '${scale10.toStringAsFixed(2)} / 10',
              style: TextStyle(
                  color: scoreColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter'),
            ),
          ),
          const Spacer(),
          if (student.criteria.isNotEmpty) ...[
            for (final c in student.criteria.take(3)) ...[
              _MiniScoreBadge(
                  label: c.id, score: c.totalScore, max: c.totalMaxScore),
              const SizedBox(width: 6),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCommentField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    String autoText = '',
    required void Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: iconColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter')),
                const SizedBox(width: 6),
                Text('($subtitle)',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Inter')),
              ],
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 3,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontFamily: 'Inter',
                height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Nhập nhận xét...',
              hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Inter'),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 10),
              filled: false,
            ),
          ),
          if (autoText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      autoText,
                      style: TextStyle(
                          color: iconColor,
                          fontSize: 12,
                          fontFamily: 'Inter',
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton(
      BuildContext context, AppStateProvider state, StudentSubmission student) {
    final isGraded = student.status == GradingStatus.graded;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isGraded
            ? null
            : () => _showFinalizeSummaryDialog(context, state, student),
        style: ElevatedButton.styleFrom(
          backgroundColor: isGraded ? AppColors.bg4 : AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(
            isGraded ? Icons.check_circle_rounded : Icons.save_alt_rounded,
            size: 16),
        label: Text(
          isGraded ? 'Đã lưu bài này' : 'Lưu bài này',
          style: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  void _showFinalizeSummaryDialog(
      BuildContext context, AppStateProvider state, StudentSubmission student) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.bg1,
          child: Container(
            width: 600,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_outlined,
                        color: AppColors.accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Xác nhận điểm: ${student.name ?? student.alias}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${student.computedTotal.toStringAsFixed(1)} / ${student.maxTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      // General Comments
                      if (student.finalPublicComment.isNotEmpty) ...[
                        _buildSummaryComment(
                            'Nhận xét công khai',
                            student.finalPublicComment,
                            Icons.public,
                            AppColors.cyan),
                        const SizedBox(height: 12),
                      ],
                      if (student.finalPrivateNote.isNotEmpty) ...[
                        _buildSummaryComment(
                            'Ghi chú riêng tư',
                            student.finalPrivateNote,
                            Icons.lock,
                            AppColors.purple),
                        const SizedBox(height: 16),
                      ],
                      const Divider(color: AppColors.border0),
                      const SizedBox(height: 12),
                      const Text(
                        'Chi tiết điểm từng câu:',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 12),
                      // Criteria details
                      for (final c in student.criteria) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bg2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.id} — ${c.name} (${c.totalScore.toStringAsFixed(1)}/${c.totalMaxScore.toStringAsFixed(0)})',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    fontFamily: 'Inter'),
                              ),
                              const SizedBox(height: 8),
                              for (final sc in c.subCriteria) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8, bottom: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '• ${sc.name}',
                                              style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                  fontFamily: 'Inter'),
                                            ),
                                          ),
                                          Text(
                                            '${sc.effectiveScore.toStringAsFixed(1)}/${sc.maxScore.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: sc.effectiveScore <
                                                      sc.maxScore
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (sc.deductReason != null &&
                                          sc.deductReason!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12, top: 4),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.info_outline,
                                                  size: 12,
                                                  color: AppColors.danger),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Lý do trừ: ${sc.deductReason}',
                                                  style: const TextStyle(
                                                      color: AppColors.danger,
                                                      fontSize: 11,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontFamily: 'Inter'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Kiểm tra lại',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final path = await state.finalizeAndSaveGrading();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              path != null
                                  ? 'Đã lưu bài ${student.alias}. Xuất CSV khi chấm xong tất cả.'
                                  : 'Không lưu được bài ${student.alias}.',
                              style: const TextStyle(fontFamily: 'Inter'),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        final next = state.nextUngradedStudent;
                        if (next != null) {
                          state.selectStudent(next);
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Lưu bài này'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryComment(
      String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.5,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _TabChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
            color: isSelected ? AppColors.accentLight : AppColors.textMuted,
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
    );
  }
}

class _MiniScoreBadge extends StatelessWidget {
  final String label;
  final double score;
  final double max;
  const _MiniScoreBadge(
      {required this.label, required this.score, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? score / max : 0.0;
    final color = pct >= 0.8
        ? AppColors.success
        : pct >= 0.65
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$label: ${score.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ResizeDividerVertical extends StatefulWidget {
  final void Function(double dy) onDrag;
  const _ResizeDividerVertical({required this.onDrag});

  @override
  State<_ResizeDividerVertical> createState() => _ResizeDividerVerticalState();
}

class _ResizeDividerVerticalState extends State<_ResizeDividerVertical> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onVerticalDragUpdate: (d) => widget.onDrag(d.delta.dy),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 6,
          color:
              _hovered ? AppColors.accent.withOpacity(0.6) : AppColors.border0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? Colors.white
                        : AppColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
