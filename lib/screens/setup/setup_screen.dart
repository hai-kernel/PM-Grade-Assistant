import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/models/app_models.dart';
import '../../core/services/setup_file_import_service.dart';
import 'setup_sidebar.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoadingSessions = true;
  String _studentSearch = '';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final state = context.read<AppStateProvider>();
    final list = await state.setupImportStorage.loadSessions();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _isLoadingSessions = false;
    });

    if (state.currentSessionId != null) {
      Map<String, dynamic>? matched;
      for (final s in list) {
        if (s['id'] == state.currentSessionId) {
          matched = s;
          break;
        }
      }
      if (matched != null) {
        state.setCurrentSession(matched);
      }
    }

    if (state.currentSessionId != null && state.students.isEmpty) {
      await state.loadSessionData(state.currentSessionId!);
    }
  }

  void _onSessionSelected(Map<String, dynamic> session) async {
    final state = context.read<AppStateProvider>();
    state.setCurrentSession(session);
    state.setCurrentSessionId(session['id']);
    state.setCurrentSessionName(
        '${session['subject']} / ${session['semester']} / ${session['examCode']}');
    await state.loadSessionData(session['id']);
  }

  void _onBackToSessionList() {
    setState(() {
      _studentSearch = '';
    });
    final state = context.read<AppStateProvider>();
    state.setCurrentSession(null);
    state.setCurrentSessionId(null);
    state.setCurrentSessionName(null);
    state.resetSetupData();
    _loadSessions();
  }

  void _onCreateSession() async {
    final result = await _showCreateSessionDialog();
    if (result != null) {
      final state = context.read<AppStateProvider>();
      final newSession = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'examCode': result['examCode']!,
        'semester': result['semester']!,
        'subject': result['subject']!,
        'type': result['type']!,
        'totalSubmissions': 0,
        'progress': 0.0,
        'status': 'pending',
      };
      await state.setupImportStorage.saveSession(newSession);
      state.setCurrentSessionName(
          '${result['subject']} / ${result['semester']} / ${result['examCode']}');
      state.resetSetupData();
      await _loadSessions();
      final createdSession = _sessions.firstWhere((s) => s['id'] == newSession['id']);
      state.setCurrentSession(createdSession);
      state.setCurrentSessionId(createdSession['id'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Container(
      color: AppColors.bg0,
      child: Row(
        children: [
          const SetupSidebar(),
          const VerticalDivider(
              width: 1, thickness: 1, color: AppColors.border0),
          // ─── Main Content ───
          Expanded(
            child: state.currentSession != null
                ? _buildSessionDetailView(context, state)
                : Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 30),
                        children: [
                          // ─── Hero Banner ───
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: AppColors.bg4,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Chào mừng trở lại!',
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Hệ thống quản lý & Chấm điểm\nProject Management',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Chọn một đợt thi bên dưới hoặc tạo phiên chấm mới để bắt đầu quá trình chấm điểm tự động, hỗ trợ phân tích AI và xuất báo cáo chuẩn xác.',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          height: 1.5,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _onCreateSession,
                                        icon: const Icon(Icons.add_rounded,
                                            size: 18),
                                        label: const Text('Tạo phiên chấm mới',
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                        Icons.auto_awesome_mosaic_rounded,
                                        size: 70,
                                        color: AppColors.accent.withOpacity(0.85)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── Session Selector ───
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.bg1,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border0),
                            ),
                            child: _buildSessionSelector(compact: false),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetailView(BuildContext context, AppStateProvider state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSessionHeaderCard(state),
          const SizedBox(height: 14),
          _buildSummaryStats(state),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 920) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildStudentPanel(context, state),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildSessionSidebar(context, state),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildStudentPanel(context, state)),
                    const SizedBox(height: 12),
                    _buildSessionSidebar(context, state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeaderCard(AppStateProvider state) {
    final session = state.currentSession!;
    final progress = (session['progress'] as num?)?.toDouble() ?? 0.0;
    final gradedPct = state.students.isEmpty
        ? progress
        : state.gradedCount / state.students.length;
    final ready = _importReadyCount(state);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _onBackToSessionList,
                icon: const Icon(Icons.arrow_back_rounded, size: 14),
                label: const Text('Danh sách đợt thi',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(session['status'], progress),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã đề ${session['examCode']} · ${session['semester']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                            icon: Icons.school_outlined,
                            label: session['subject'] as String),
                        _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: 'Học kỳ ${session['semester']}'),
                        _MetaChip(
                            icon: Icons.category_outlined,
                            label: session['type'] as String),
                        _MetaChip(
                            icon: Icons.folder_open_outlined,
                            label: '$ready/4 tài liệu'),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.students.isNotEmpty) ...[
                const SizedBox(width: 24),
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(gradedPct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Text(
                        'tiến độ chấm',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (state.students.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: gradedPct.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.bg4,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${state.gradedCount}/${state.students.length} bài đã chấm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Text(
                  'Ngưỡng qua môn: ${AppStateProvider.passScaleThreshold.toStringAsFixed(1)}/10',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionSidebar(BuildContext context, AppStateProvider state) {
    final ready = _importReadyCount(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildImportSection(context)),
        const SizedBox(height: 12),
        _buildActionButton(context),
        if (ready < 4)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Cần import đủ 4 mục trước khi chấm tự động.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.warning.withOpacity(0.9),
                fontFamily: 'Inter',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentPanel(BuildContext context, AppStateProvider state) {
    final students = state.students.where((s) {
      if (_studentSearch.isEmpty) return true;
      final q = _studentSearch.toLowerCase();
      return s.alias.toLowerCase().contains(q) ||
          (s.name?.toLowerCase().contains(q) ?? false) ||
          (s.marker?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Danh sách sinh viên',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.students.length}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Spacer(),
                _LegendDot(color: AppColors.success, label: 'Đã chấm'),
                const SizedBox(width: 10),
                _LegendDot(color: AppColors.warning, label: 'Đang chấm'),
                const SizedBox(width: 10),
                _LegendDot(color: AppColors.textMuted, label: 'Chưa chấm'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _studentSearch = v),
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm theo alias, tên, giảng viên...',
                hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter'),
                prefixIcon: const Icon(Icons.search,
                    size: 16, color: AppColors.textMuted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.bg2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border0),
          if (students.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.students.isEmpty
                            ? Icons.people_outline
                            : Icons.search_off_rounded,
                        size: 36,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.students.isEmpty
                            ? 'Chưa có sinh viên'
                            : 'Không tìm thấy kết quả',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.students.isEmpty
                            ? 'Import CSV và thư mục bài thi ở cột bên phải.'
                            : 'Thử từ khóa khác.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                      width: 32,
                      child: Text('#',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              fontFamily: 'Inter'))),
                  const Expanded(
                    flex: 2,
                    child: Text('Mã SV',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Text('Họ và tên',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  const Expanded(
                    flex: 2,
                    child: Text('Giảng viên',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  ...state.setupData.parsedCriteria.map((criterion) {
                    return Expanded(
                      flex: 1,
                      child: Text(
                        criterion.id,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          fontFamily: 'Inter',
                        ),
                      ),
                    );
                  }),
                  const Expanded(
                    flex: 2,
                    child: Text('Trạng thái',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  const Expanded(
                    flex: 1,
                    child: Text('Total',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text('Comment',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              fontFamily: 'Inter')),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border0),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, i) {
                  final originalIndex = state.students.indexOf(students[i]);
                  return _StudentPreviewRow(
                    student: students[i],
                    index: originalIndex,
                    striped: i.isEven,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionSelector({bool compact = true}) {
    final state = context.read<AppStateProvider>();
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (final session in _sessions) {
      final sem = session['semester'] ?? 'Khác';
      final sub = session['subject'] ?? 'Khác';
      grouped.putIfAbsent(sem, () => {});
      grouped[sem]!.putIfAbsent(sub, () => []);
      grouped[sem]![sub]!.add(session);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_note_outlined,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            const Text(
              'Đợt thi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _onCreateSession,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Tạo phiên mới',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...grouped.entries.expand((semEntry) {
          final semester = semEntry.key;
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Học kỳ $semester',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...semEntry.value.entries.expand((subEntry) {
              final subject = subEntry.key;
              final sessionList = subEntry.value;
              return [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sessionList.map((session) {
                    final isSelected = state.currentSession != null &&
                        state.currentSession!['id'] == session['id'];
                    return _SessionPickerCard(
                      session: session,
                      isSelected: isSelected,
                      compact: compact,
                      onTap: () => _onSessionSelected(session),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ];
            }),
          ];
        }),
      ],
    );
  }

  Future<Map<String, String>?> _showCreateSessionDialog() async {
    final codeController = TextEditingController();
    final semController = TextEditingController();
    final subController = TextEditingController(text: 'PMG201c');
    final typeController = TextEditingController(text: 'PE');
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Tạo phiên chấm mới',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Mã đề',
                  hintText: 'Ví dụ: PE01, FE02...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                autofocus: true,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: semController,
                decoration: InputDecoration(
                  labelText: 'Học kỳ',
                  hintText: 'Ví dụ: SP26, SU25...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subController,
                decoration: InputDecoration(
                  labelText: 'Môn học',
                  hintText: 'Ví dụ: PMG201c...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Đợt thi (PE / FE)',
                  hintText: 'Ví dụ: PE, FE...',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.isNotEmpty &&
                  semController.text.isNotEmpty &&
                  subController.text.isNotEmpty &&
                  typeController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'examCode': codeController.text.toUpperCase(),
                  'semester': semController.text.toUpperCase(),
                  'subject': subController.text.toUpperCase(),
                  'type': typeController.text.toUpperCase(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  int _importReadyCount(AppStateProvider state) {
    var n = 0;
    if (state.setupData.examFileName != null) n++;
    if (state.setupData.gradingGuideFileName != null) n++;
    if (state.uploadedCSVs.isNotEmpty) n++;
    if (state.uploadedSubmissionFolders.isNotEmpty) n++;
    return n;
  }

  Widget _buildSummaryStats(AppStateProvider state) {
    final stats = [
      (
        Icons.assignment_ind_outlined,
        'Phân công',
        state.assignedCount,
        AppColors.accent
      ),
      (
        Icons.check_circle_outline,
        'Đã chấm',
        state.gradedCount,
        AppColors.success
      ),
      (
        Icons.pending_outlined,
        'Chưa chấm',
        state.pendingGradeCount,
        AppColors.warning
      ),
      (
        Icons.emoji_events_outlined,
        'Qua môn',
        state.passCount,
        AppColors.success
      ),
      (Icons.cancel_outlined, 'Rớt môn', state.failCount, AppColors.danger),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: stats[i].$1,
              label: stats[i].$2,
              value: stats[i].$3,
              color: stats[i].$4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImportSection(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final ready = _importReadyCount(state);
    final selectedCsvName = state.selectedCSVIndex >= 0 &&
            state.selectedCSVIndex < state.uploadedCSVs.length
        ? state.uploadedCSVs[state.selectedCSVIndex]['name']
        : null;
    final latestFolderName = state.uploadedSubmissionFolders.isNotEmpty
        ? state.uploadedSubmissionFolders.last['name']
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border0),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Thiết lập tài liệu & dữ liệu',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Text(
                  '$ready/4 đã tải',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ready == 4 ? AppColors.success : AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Import đủ 4 mục để bật chấm điểm tự động.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border0),
            const SizedBox(height: 6),
            _buildImportRow(
              icon: Icons.image_outlined,
              label: 'Đề thi',
              typeLabel: 'PNG/JPG',
              color: AppColors.accent,
              fileName: state.setupData.examFileName,
              onPick: () async => _pickFile(context, 'exam'),
            ),
            _buildImportRow(
              icon: Icons.rule_rounded,
              label: 'Barem chấm điểm',
              typeLabel: 'DOCX',
              color: AppColors.purple,
              fileName: state.setupData.gradingGuideFileName,
              onPick: () async => _pickFile(context, 'guide'),
            ),
            _buildImportRow(
              icon: Icons.table_chart_outlined,
              label: 'Danh sách sinh viên',
              typeLabel: 'CSV/XLSX',
              color: AppColors.success,
              fileName: selectedCsvName,
              onPick: () async => _pickFile(context, 'csv'),
            ),
            _buildImportRow(
              icon: Icons.folder_open_rounded,
              label: 'Thư mục bài thi',
              typeLabel: 'FOLDER',
              color: AppColors.warning,
              fileName: latestFolderName,
              onPick: () async => _pickFile(context, 'folder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportRow({
    required IconData icon,
    required String label,
    required String typeLabel,
    required Color color,
    required String? fileName,
    required Future<void> Function() onPick,
  }) {
    final hasFile = fileName != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 75,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasFile
                      ? Icons.check_circle_rounded
                      : Icons.insert_drive_file_outlined,
                  size: 14,
                  color: hasFile ? color : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName ?? 'Chưa chọn file',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: OutlinedButton.icon(
              onPressed: () => onPick(),
              icon: Icon(
                hasFile ? Icons.sync_rounded : Icons.upload_file_rounded,
                size: 14,
              ),
              label: Text(
                hasFile ? 'Đổi' : 'Import',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            final error = state.proceedToGrading();
            if (error != null) {
              _showImportSnack(context, error);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Bắt đầu chấm điểm',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final message = await state.refreshImportedData();
              if (!context.mounted) return;
              _showImportSnack(context, message);
            } catch (e) {
              if (!context.mounted) return;
              _showImportSnack(context, 'Lỗi khi nạp dữ liệu: $e');
            }
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Làm mới dữ liệu từ file',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            if (state.students.isEmpty) {
              _showImportSnack(context, 'Không có dữ liệu sinh viên để xuất.');
              return;
            }
            try {
              final path = await state.exportAllGradesToExcel();
              if (!context.mounted) return;
              if (path != null) {
                _showImportSnack(context, 'Đã xuất file điểm thành công: $path');
              }
            } catch (e) {
              if (!context.mounted) return;
              _showImportSnack(context, 'Lỗi khi xuất file: $e');
            }
          },
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Xuất báo cáo điểm (Excel/CSV)',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
          ),
        ),
      ],
    );
  }

  void _showImportSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Inter')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, String type) async {
    final state = context.read<AppStateProvider>();

    switch (type) {
      case 'exam':
        final picked = await SetupFileImportService.pickImage(
          dialogTitle: 'Chọn ảnh đề thi (.png/.jpg)',
        );
        if (!context.mounted || picked == null) return;
        await state.setExamFile(picked.path, picked.name);
        _showImportSnack(context, 'Đã import đề thi: ${picked.name}');
        break;
      case 'guide':
        final picked = await SetupFileImportService.pickDocx(
          dialogTitle: 'Chọn file barem chấm điểm (.docx)',
        );
        if (!context.mounted || picked == null) return;
        await state.setGradingGuide(picked.path, picked.name);
        _showImportSnack(context, 'Đã import barem: ${picked.name}');
        break;
      case 'csv':
        final pickedFiles = await SetupFileImportService.pickStudentListFiles();
        if (!context.mounted || pickedFiles.isEmpty) return;
        await state.addCSVFiles(pickedFiles);
        if (!context.mounted) return;
        _showImportSnack(context,
            'Đã import ${pickedFiles.length} file danh sách sinh viên');
        break;
      case 'folder':
        final path = await SetupFileImportService.pickSubmissionFolder();
        if (!context.mounted || path == null || path.isEmpty) return;
        await state.addSubmissionFolder(path);
        if (!context.mounted) return;
        final folderName = path.split(RegExp(r'[/\\]')).last;
        _showImportSnack(context, 'Đã chọn thư mục: $folderName');
        break;
    }
  }

  Widget _buildMetadataChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status, double? progressVal) {
    Color color;
    String label;
    switch (status) {
      case 'graded':
        color = AppColors.success;
        label = 'Trạng thái: Đã chấm xong';
        break;
      case 'grading':
        color = AppColors.warning;
        final pct = ((progressVal ?? 0.0) * 100).toStringAsFixed(0);
        label = 'Trạng thái: Đang chấm ($pct%)';
        break;
      default:
        color = AppColors.textMuted;
        label = 'Trạng thái: Chờ thiết lập';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(AppStateProvider state) {
    final hasFiles = state.setupData.examFileName != null &&
        state.setupData.gradingGuideFileName != null;
    final hasStudents = state.students.isNotEmpty;

    Color color;
    String label;
    if (hasStudents) {
      color = AppColors.success;
      label = 'Giai đoạn: Sẵn sàng chấm';
    } else if (hasFiles) {
      color = AppColors.accent;
      label = 'Giai đoạn: Nhập danh sách sinh viên';
    } else {
      color = AppColors.purple;
      label = 'Giai đoạn: Thiết lập tài liệu & Barem';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPickerCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _SessionPickerCard({
    required this.session,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_SessionPickerCard> createState() => _SessionPickerCardState();
}

class _SessionPickerCardState extends State<_SessionPickerCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.session['status'] ?? 'pending';
    final progress = (widget.session['progress'] as num?)?.toDouble() ?? 0.0;
    final totalSub = widget.session['totalSubmissions'] ?? 0;
    final examCode = widget.session['examCode'] ?? '';
    final type = widget.session['type'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'graded':
        statusColor = AppColors.success;
        statusLabel = 'Đã chấm xong';
        break;
      case 'grading':
        statusColor = AppColors.warning;
        statusLabel = 'Đang chấm ${(progress * 100).toStringAsFixed(0)}%';
        break;
      default:
        statusColor = AppColors.textMuted;
        statusLabel = 'Chờ thiết lập';
    }

    final width = widget.compact ? 168.0 : 200.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accentBg
                : (_isHovered ? AppColors.bg4 : AppColors.bg1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.accent.withOpacity(0.5)
                  : AppColors.border0,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      examCode,
                      style: TextStyle(
                        color: widget.isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$totalSub bài làm',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Inter',
                    height: 1.1,
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter')),
    );
  }
}

class _StudentPreviewRow extends StatelessWidget {
  final dynamic student;
  final int index;
  final bool striped;
  const _StudentPreviewRow({
    required this.student,
    required this.index,
    this.striped = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateProvider>();
    final parsedCriteria = state.setupData.parsedCriteria;

    Color statusColor;
    String statusLabel;
    switch (student.status) {
      case GradingStatus.graded:
        statusColor = AppColors.success;
        statusLabel = 'Đã chấm';
        break;
      case GradingStatus.inProgress:
        statusColor = AppColors.warning;
        statusLabel = 'Đang chấm';
        break;
      default:
        statusColor = AppColors.textMuted;
        statusLabel = 'Chưa chấm';
    }

    final score = student.finalScaleScore;
    Color? scoreColor;
    if (score != null) {
      scoreColor = score >= AppStateProvider.passScaleThreshold
          ? AppColors.success
          : AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: striped ? AppColors.bg2.withOpacity(0.55) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: AppColors.accent.withOpacity(0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    student.alias,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.name ?? '—',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.marker ?? '—',
              style: TextStyle(
                color: student.marker != null ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...parsedCriteria.map((criterion) {
            // Find this student's score for this criterion
            final studentCriterion = student.criteria.firstWhere(
              (c) => c.id == criterion.id,
              orElse: () => criterion,
            );
            final hasCriterionScore = student.status == GradingStatus.graded;
            final scoreVal = hasCriterionScore ? studentCriterion.totalScore : null;
            return Expanded(
              flex: 1,
              child: Text(
                scoreVal != null ? scoreVal.toStringAsFixed(1) : '—',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
            );
          }),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              score != null ? score.toStringAsFixed(1) : '—',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: scoreColor ?? AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                student.status == GradingStatus.graded
                    ? student.finalPublicComment
                    : '—',
                style: TextStyle(
                  color: student.status == GradingStatus.graded
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
