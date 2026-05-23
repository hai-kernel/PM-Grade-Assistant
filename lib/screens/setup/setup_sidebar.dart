import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SetupSidebar extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic>? selectedSession;
  final ValueChanged<Map<String, dynamic>> onSessionSelected;
  final VoidCallback onCreateSession;
  final VoidCallback onLogout;

  const SetupSidebar({
    super.key,
    required this.sessions,
    required this.selectedSession,
    required this.onSessionSelected,
    required this.onCreateSession,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Grouping: Map<Semester, Map<Subject, List<Session>>>
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var session in sessions) {
      final sem = session['semester'] ?? 'Khác';
      final sub = session['subject'] ?? 'Khác';
      grouped.putIfAbsent(sem, () => {});
      grouped[sem]!.putIfAbsent(sub, () => []);
      grouped[sem]![sub]!.add(session);
    }

    final List<Widget> listItems = [];
    grouped.forEach((semester, subjects) {
      // Semester Header
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 10, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'HỌC KỲ $semester',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

      subjects.forEach((subject, sessionList) {
        // Subject Header
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 6, bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.folder_open_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        );

        // Sessions (Mã đề) Under this Subject
        for (var session in sessionList) {
          final isSelected = selectedSession != null && selectedSession!['id'] == session['id'];
          listItems.add(
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _SessionCard(
                session: session,
                isSelected: isSelected,
                onTap: () => onSessionSelected(session),
              ),
            ),
          );
        }
      });
    });

    return Container(
      width: 220,
      color: AppColors.bg2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // ─── Header Logo ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PMG Grade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── Action Button: Create Session ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _CreateSessionButton(onPressed: onCreateSession),
          ),
          const SizedBox(height: 12),

          // ─── Tree Sessions List ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: listItems,
            ),
          ),

          // ─── Profile / Footer ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border0)),
              color: AppColors.bg1,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: const Text(
                    'HL',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HungLD5',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Giảng viên chấm thi',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 14, color: AppColors.textMuted),
                  onPressed: onLogout,
                  tooltip: 'Đăng xuất',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSessionButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _CreateSessionButton({required this.onPressed});

  @override
  State<_CreateSessionButton> createState() => _CreateSessionButtonState();
}

class _CreateSessionButtonState extends State<_CreateSessionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isHovered ? AppColors.accent : AppColors.border1,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 14,
                color: _isHovered ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Text(
                'Create Session',
                style: TextStyle(
                  color: _isHovered ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final bool isSelected;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.session['status'] ?? 'pending';
    final progress = (widget.session['progress'] as num?)?.toDouble() ?? 0.0;
    final totalSub = widget.session['totalSubmissions'] ?? 0;
    final examCode = widget.session['examCode'] ?? '';

    // Color helpers based on status
    Color statusColor;
    String statusLabel = '';
    switch (status) {
      case 'graded':
        statusColor = AppColors.success;
        statusLabel = 'Đã xong';
        break;
      case 'grading':
        statusColor = AppColors.warning;
        statusLabel = '${(progress * 100).toStringAsFixed(0)}%';
        break;
      default:
        statusColor = AppColors.textMuted;
        statusLabel = 'Chờ';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent.withOpacity(0.08)
                : (_isHovered ? AppColors.bg4.withOpacity(0.3) : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              // Status dot indicator
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      examCode,
                      style: TextStyle(
                        color: widget.isSelected ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalSub bài làm • $statusLabel',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
