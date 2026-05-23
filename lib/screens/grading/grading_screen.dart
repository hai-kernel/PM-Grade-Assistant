import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
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
  double _leftPanelWidth = 260;
  double _rightPanelWidth = 380;
  static const double _minLeft = 200;
  static const double _maxLeft = 360;
  static const double _minRight = 320;
  static const double _maxRight = 500;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GradingTopBar(),
        Expanded(
          child: Row(
            children: [
              // Left panel: Student List
              SizedBox(
                width: _leftPanelWidth,
                child: const StudentListPanel(),
              ),
              // Divider + drag handle
              _ResizeDivider(
                onDrag: (dx) => setState(() {
                  _leftPanelWidth = (_leftPanelWidth + dx).clamp(_minLeft, _maxLeft);
                }),
              ),
              // Middle panel: Submission content + comments + score summary
              Expanded(
                child: const SubmissionPanel(),
              ),
              // Divider + drag handle
              _ResizeDivider(
                onDrag: (dx) => setState(() {
                  _rightPanelWidth = (_rightPanelWidth - dx).clamp(_minRight, _maxRight);
                }),
              ),
              // Right panel: Scoring rubric
              SizedBox(
                width: _rightPanelWidth,
                child: const ScoringPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResizeDivider extends StatefulWidget {
  final void Function(double dx) onDrag;
  const _ResizeDivider({required this.onDrag});

  @override
  State<_ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends State<_ResizeDivider> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 6,
          color: _hovered ? AppColors.accent.withOpacity(0.6) : AppColors.border0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _hovered ? Colors.white : AppColors.textMuted.withOpacity(0.3),
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
