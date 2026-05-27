import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme/app_theme.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    final maximized = await windowManager.isMaximized();
    setState(() => _isMaximized = maximized);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.bg2,
          border: Border(bottom: BorderSide(color: AppColors.border0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // App icon + title
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PMG Grade',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
              ),
            ),
            const Expanded(
              child: Text(
                ' — Hệ thống chấm điểm Project Management',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Window controls
            _WindowButton(
              icon: Icons.remove,
              tooltip: 'Minimize',
              onTap: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
              tooltip: _isMaximized ? 'Restore' : 'Maximize',
              onTap: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
                setState(() => _isMaximized = !_isMaximized);
              },
            ),
            _WindowButton(
              icon: Icons.close,
              tooltip: 'Close',
              isClose: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
            height: 40,
            color: _hovered
                ? (widget.isClose ? AppColors.danger : AppColors.bg4)
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered && widget.isClose
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
