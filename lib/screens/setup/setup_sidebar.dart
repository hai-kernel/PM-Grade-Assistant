import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Sidebar cố định: logo + profile. Không chứa danh sách đợt thi (tránh overload).
class SetupSidebar extends StatelessWidget {
  final VoidCallback onLogout;

  const SetupSidebar({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.bg2,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 18),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: const Text(
                    'HL',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.textMuted),
                  onPressed: onLogout,
                  tooltip: 'Đăng xuất',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  splashRadius: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
