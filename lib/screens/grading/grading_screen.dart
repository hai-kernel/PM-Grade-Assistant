import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'panels/student_list_panel.dart';
import 'panels/submission_panel.dart';
import 'panels/scoring_panel.dart';
import '../../widgets/grading_top_bar.dart';

class GradingScreen extends StatefulWidget {
  const GradingScreen({super.key});

  @override
  State<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends State<GradingScreen> {
  static const double _defaultLeftWidth = 260;
  static const double _minLeft = 200;
  static const double _collapseThreshold = 140;
  static const double _railWidth = 40;

  double _leftPanelWidth = _defaultLeftWidth;
  bool _leftPanelVisible = true;

  double _rightPanelWidth = 380;
  static const double _minRight = 280;
  static const double _maxRight = 560;

  void _toggleLeftPanel() {
    setState(() => _leftPanelVisible = !_leftPanelVisible);
  }

  void _finishLeftDrag(double maxLeft) {
    if (_leftPanelWidth < _collapseThreshold) {
      setState(() {
        _leftPanelVisible = false;
        _leftPanelWidth = _defaultLeftWidth;
      });
    } else if (_leftPanelWidth < _minLeft) {
      setState(() => _leftPanelWidth = _minLeft);
    } else if (_leftPanelWidth > maxLeft) {
      setState(() => _leftPanelWidth = maxLeft);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradingTopBar(
          studentPanelVisible: _leftPanelVisible,
          onToggleStudentPanel: _toggleLeftPanel,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxLeft =
                  (constraints.maxWidth * 0.48).clamp(_minLeft, 520.0);

              return Row(
                children: [
                  if (_leftPanelVisible) ...[
                    SizedBox(
                      width: _leftPanelWidth.clamp(
                          _collapseThreshold, maxLeft),
                      child: StudentListPanel(
                        onHidePanel: _toggleLeftPanel,
                      ),
                    ),
                    _ResizeDivider(
                      onDrag: (dx) => setState(() {
                        _leftPanelWidth =
                            (_leftPanelWidth + dx).clamp(80, maxLeft);
                      }),
                      onDragEnd: () => _finishLeftDrag(maxLeft),
                      onDoubleTap: _toggleLeftPanel,
                      tooltip: 'Kéo để đổi độ rộng · Double-click để ẩn',
                    ),
                  ] else
                    _CollapsedPanelRail(
                      width: _railWidth,
                      onExpand: _toggleLeftPanel,
                    ),
                  const Expanded(child: SubmissionPanel()),
                  _ResizeDivider(
                    onDrag: (dx) => setState(() {
                      _rightPanelWidth =
                          (_rightPanelWidth - dx).clamp(_minRight, _maxRight);
                    }),
                    tooltip: 'Kéo để đổi độ rộng barem',
                  ),
                  SizedBox(
                    width: _rightPanelWidth,
                    child: const ScoringPanel(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Thanh mỏng khi panel sinh viên đang ẩn — bấm để mở lại.
class _CollapsedPanelRail extends StatefulWidget {
  final double width;
  final VoidCallback onExpand;

  const _CollapsedPanelRail({
    required this.width,
    required this.onExpand,
  });

  @override
  State<_CollapsedPanelRail> createState() => _CollapsedPanelRailState();
}

class _CollapsedPanelRailState extends State<_CollapsedPanelRail> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? AppColors.bg4 : AppColors.bg2,
        child: InkWell(
          onTap: widget.onExpand,
          child: Container(
            width: widget.width,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border0)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Mở danh sách sinh viên',
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _hovered ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Sinh viên',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _hovered
                          ? AppColors.accent
                          : AppColors.textMuted,
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: _hovered ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeDivider extends StatefulWidget {
  final void Function(double dx) onDrag;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDoubleTap;
  final String? tooltip;

  const _ResizeDivider({
    required this.onDrag,
    this.onDragEnd,
    this.onDoubleTap,
    this.tooltip,
  });

  @override
  State<_ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends State<_ResizeDivider> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final divider = MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _dragging = false;
      }),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd?.call();
        },
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: _dragging || _hovered ? 8 : 5,
          color: _dragging
              ? AppColors.accent.withOpacity(0.35)
              : _hovered
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.border0,
          child: Center(
            child: Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: _hovered || _dragging
                    ? AppColors.accent
                    : AppColors.textMuted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: divider);
    }
    return divider;
  }
}
