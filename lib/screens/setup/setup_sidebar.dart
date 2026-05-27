import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Sidebar cố định: logo + profile. Không chứa danh sách đợt thi (tránh overload).
class SetupSidebar extends StatelessWidget {
  const SetupSidebar({
    super.key,
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
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 18),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
