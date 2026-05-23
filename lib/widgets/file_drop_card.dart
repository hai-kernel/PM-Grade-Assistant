import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class FileDropCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String acceptedTypes;
  final Color accentColor;
  final String? selectedFileName;
  final VoidCallback onPickFile;

  const FileDropCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.acceptedTypes,
    required this.accentColor,
    required this.onPickFile,
    this.selectedFileName,
  });

  @override
  State<FileDropCard> createState() => _FileDropCardState();
}

class _FileDropCardState extends State<FileDropCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool hasFile = widget.selectedFileName != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.accentColor.withOpacity(0.06)
                : AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasFile
                  ? widget.accentColor.withOpacity(0.5)
                  : _hovered
                      ? widget.accentColor.withOpacity(0.35)
                      : AppColors.border0,
              width: hasFile ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bg4,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.acceptedTypes,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (hasFile) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: widget.accentColor, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.selectedFileName!,
                          style: TextStyle(
                            color: widget.accentColor,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined, color: widget.accentColor.withOpacity(0.6), size: 13),
                    ],
                  ),
                ),
              ] else ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _hovered ? widget.accentColor.withOpacity(0.04) : AppColors.bg3,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _hovered ? widget.accentColor.withOpacity(0.4) : AppColors.border0,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          color: _hovered ? widget.accentColor : AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Click để chọn file',
                          style: TextStyle(
                            color: _hovered ? widget.accentColor : AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: _hovered ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
