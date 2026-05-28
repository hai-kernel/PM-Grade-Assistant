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
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': 'session_pe01',
      'semester': 'SP26',
      'subject': 'PMG201c',
      'type': 'PE',
      'examCode': 'PE01',
      'totalSubmissions': 8,
      'progress': 0.375, // 3 out of 8 graded
      'status': 'grading',
    },
    {
      'id': 'session_fe01',
      'semester': 'SP26',
      'subject': 'PMG201c',
      'type': 'FE',
      'examCode': 'FE01',
      'totalSubmissions': 0,
      'progress': 0.0,
      'status': 'pending',
    },
    {
      'id': 'session_pe02',
      'semester': 'SU25',
      'subject': 'PMG201c',
      'type': 'PE',
      'examCode': 'PE02',
      'totalSubmissions': 8,
      'progress': 1.0,
      'status': 'graded',
    },
  ];
  Map<String, dynamic>? _selectedSession;
  String _studentSearch = '';

  void _onSessionSelected(Map<String, dynamic> session) async {
    setState(() {
      _selectedSession = session;
    });
    final state = context.read<AppStateProvider>();
    state.setCurrentSessionName(
        '${session['subject']} / ${session['semester']} / ${session['examCode']}');
    if (session['status'] != 'pending') {
      await state.loadDemoData();
      if (mounted) {
        final error = state.proceedToGrading();
        if (error != null) {
          _showImportSnack(context, error);
        }
      }
    } else {
      state.resetSetupData();
    }
  }

  void _onBackToSessionList() {
    setState(() {
      _selectedSession = null;
      _studentSearch = '';
    });
    context.read<AppStateProvider>().resetSetupData();
  }

  void _onCreateSession() async {
    final result = await _showCreateSessionDialog();
    if (result != null) {
      setState(() {
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
        _sessions.add(newSession);
        _selectedSession = newSession;
        final state = context.read<AppStateProvider>();
        state.setCurrentSessionName(
            '${result['subject']} / ${result['semester']} / ${result['examCode']}');
        state.resetSetupData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Container(
      color: AppColors.bg0,
      child: Row(
        children: [
          // ─── Main Content ───
          Expanded(
            child: _selectedSession != null
                ? _buildSessionDetailView(context, state)
                : Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 30),
                        children: [
                          // ─── Header Profile & Logout ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.accent, AppColors.purple],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.school_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'PMG Grade',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              Row(
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
                                  const Text(
                                    'HungLD5',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.logout_rounded,
                                        size: 16, color: AppColors.textMuted),
                                    onPressed: () => state.navigateTo(AppScreen.login),
                                    tooltip: 'Đăng xuất',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    splashRadius: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // ─── Hero Banner ───
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
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
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          '🎉 Chào mừng trở lại!',
                                          style: TextStyle(
                                            color: Colors.white,
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
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          fontFamily: 'Inter',
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Chọn một đợt thi bên dưới hoặc tạo phiên chấm mới để bắt đầu quá trình chấm điểm tự động, hỗ trợ phân tích AI và xuất báo cáo chuẩn xác.',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
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
                                          backgroundColor: Colors.white,
                                          foregroundColor: AppColors.accent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                        Icons.auto_awesome_mosaic_rounded,
                                        size: 70,
                                        color: Colors.white.withOpacity(0.9)),
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
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                        flex: 7,
                        child: _buildStudentPanel(context, state),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 380,
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
    final session = _selectedSession!;
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
              if (state.students.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _showExportAllDialog(context, state),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Xuất CSV',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
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
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
    final students = state.displayedStudents.where((s) {
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
                    '${state.displayedStudents.length}',
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
                children: const [
                  SizedBox(
                      width: 32,
                      child: Text('#',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              fontFamily: 'Inter'))),
                  Expanded(
                    flex: 3,
                    child: Text('Alias / Mã SV',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text('Họ tên',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Trạng thái',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('Điểm',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            fontFamily: 'Inter')),
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
                    final isSelected = _selectedSession != null &&
                        _selectedSession!['id'] == session['id'];
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

  // Future<Map<String, String>?> _showCreateSessionDialog() async {
  //   final codeController = TextEditingController();
  //   final semController = TextEditingController();
  //   final subController = TextEditingController(text: 'PMG201c');
  //   final typeController = TextEditingController(text: 'PE');
  //   return showDialog<Map<String, String>>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       title: const Text('Tạo phiên chấm mới',
  //           style: TextStyle(
  //               fontFamily: 'Inter',
  //               fontWeight: FontWeight.bold,
  //               fontSize: 18)),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             TextField(
  //               controller: codeController,
  //               decoration: InputDecoration(
  //                 labelText: 'Mã đề',
  //                 hintText: 'Ví dụ: PE01, FE02...',
  //                 hintStyle:
  //                     const TextStyle(color: AppColors.textMuted, fontSize: 14),
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8)),
  //                 contentPadding:
  //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //               ),
  //               autofocus: true,
  //               style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: semController,
  //               decoration: InputDecoration(
  //                 labelText: 'Học kỳ',
  //                 hintText: 'Ví dụ: SP26, SU25...',
  //                 hintStyle:
  //                     const TextStyle(color: AppColors.textMuted, fontSize: 14),
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8)),
  //                 contentPadding:
  //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //               ),
  //               style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: subController,
  //               decoration: InputDecoration(
  //                 labelText: 'Môn học',
  //                 hintText: 'Ví dụ: PMG201c...',
  //                 hintStyle:
  //                     const TextStyle(color: AppColors.textMuted, fontSize: 14),
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8)),
  //                 contentPadding:
  //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //               ),
  //               style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
  //             ),
  //             const SizedBox(height: 16),
  //             TextField(
  //               controller: typeController,
  //               decoration: InputDecoration(
  //                 labelText: 'Đợt thi (PE / FE)',
  //                 hintText: 'Ví dụ: PE, FE...',
  //                 hintStyle:
  //                     const TextStyle(color: AppColors.textMuted, fontSize: 14),
  //                 border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8)),
  //                 contentPadding:
  //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //               ),
  //               style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Hủy',
  //               style: TextStyle(color: AppColors.textSecondary)),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             if (codeController.text.isNotEmpty &&
  //                 semController.text.isNotEmpty &&
  //                 subController.text.isNotEmpty &&
  //                 typeController.text.isNotEmpty) {
  //               Navigator.pop(context, {
  //                 'examCode': codeController.text.toUpperCase(),
  //                 'semester': semController.text.toUpperCase(),
  //                 'subject': subController.text.toUpperCase(),
  //                 'type': typeController.text.toUpperCase(),
  //               });
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.accent,
  //             foregroundColor: Colors.white,
  //             elevation: 0,
  //             shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8)),
  //           ),
  //           child: const Text('Xác nhận'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // int _importReadyCount(AppStateProvider state) {
  //   var n = 0;
  //   if (state.setupData.examFileName != null) n++;
  //   if (state.setupData.gradingGuideFileName != null) n++;
  //   if (state.uploadedCSVs.isNotEmpty) n++;
  //   if (state.uploadedSubmissionFolders.isNotEmpty) n++;
  //   return n;
  // }

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
            if (state.uploadedCSVs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: List.generate(state.uploadedCSVs.length, (idx) {
                    final csv = state.uploadedCSVs[idx];
                    final isSelected = state.selectedCSVIndex == idx;
                    return InkWell(
                      onTap: () => state.selectCSVFile(idx),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.successBg : AppColors.bg2,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.success
                                : AppColors.border0,
                          ),
                        ),
                        child: Text(
                          csv['name']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            _buildImportRow(
              icon: Icons.folder_open_rounded,
              label: 'Thư mục bài thi',
              typeLabel: 'FOLDER',
              color: AppColors.warning,
              fileName: latestFolderName,
              onPick: () async => _pickFile(context, 'folder'),
            ),
            if (state.uploadedSubmissionFolders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: state.uploadedSubmissionFolders.map((folder) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        folder['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.warning,
                          fontFamily: 'Inter',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
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
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  hasFile
                      ? Icons.check_circle_rounded
                      : Icons.insert_drive_file_outlined,
                  size: 14,
                  color: hasFile ? color : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
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
          const SizedBox(width: 8),
          OutlinedButton.icon(
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
              final message = await state.loadDemoData();
              if (!context.mounted) return;
              _showImportSnack(context, message);
            } catch (e) {
              if (!context.mounted) return;
              _showImportSnack(context, 'Lỗi khi nạp dữ liệu: $e');
            }
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Nạp lại từ file đã import',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
        state.setExamFile(picked.path, picked.name);
        _showImportSnack(context, 'Đã import đề thi: ${picked.name}');
        break;
      case 'guide':
        final picked = await SetupFileImportService.pickDocx(
          dialogTitle: 'Chọn file barem chấm điểm (.docx)',
        );
        if (!context.mounted || picked == null) return;
        state.setGradingGuide(picked.path, picked.name);
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
    final progress =
        (widget.session['progress'] as num?)?.toDouble() ?? 0.0;
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
        statusLabel =
            'Đang chấm ${(progress * 100).toStringAsFixed(0)}%';
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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

  void _showExportAllDialog(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.bg1,
        child: Container(
          width: 850,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.download_rounded, color: AppColors.success, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Xuất toàn bộ điểm CSV', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border0),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiến độ chấm điểm:', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Inter', fontSize: 14)),
                        Text('${state.gradedCount} / ${state.students.length} bài', style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: state.students.isEmpty ? 0 : state.gradedCount / state.students.length,
                      backgroundColor: AppColors.bg4,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 6,
                    ),
                    if (state.gradedCount < state.students.length) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cảnh báo: Chưa chấm hết. Các bài chưa lưu sẽ để trống trong file CSV.',
                              style: TextStyle(color: AppColors.warning, fontFamily: 'Inter', fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Xem trước bảng điểm Excel tổng hợp (Demo dữ liệu xuất):', 
                  style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildExcelPreviewTable(state),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final path = await state.exportAllGradesToCsv();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            path != null
                                ? 'Đã xuất CSV: $path'
                                : 'Hủy xuất file hoặc không lưu được.',
                            style: const TextStyle(fontFamily: 'Inter'),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Xác nhận Xuất File', style: TextStyle(fontFamily: 'Inter')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcelPreviewTable(AppStateProvider state) {
    const headerBg = Color(0xFFFCE4D6);
    const commentBg = Color(0xFFFFFF00);
    const totalColor = Color(0xFF002060);

    Widget cell(String text, {Color? bg, bool isBold = false, Color? textColor, Alignment align = Alignment.center}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: bg ?? AppColors.bg0,
        alignment: align,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final rows = <TableRow>[];

    // Row 1: Headers
    rows.add(
      TableRow(
        children: [
          cell('Alias', bg: headerBg, isBold: true),
          cell('Marker', bg: headerBg, isBold: true),
          cell('Question 1', bg: headerBg, isBold: true),
          cell('Question 2', bg: headerBg, isBold: true),
          cell('Question 3', bg: headerBg, isBold: true),
          cell('Question 4', bg: headerBg, isBold: true),
          cell('Question 5', bg: headerBg, isBold: true),
          cell('Total', bg: headerBg, isBold: true, textColor: totalColor),
          cell('Comment', bg: commentBg, isBold: true, align: Alignment.centerLeft),
        ],
      ),
    );

    // Row 2: Max Points
    rows.add(
      TableRow(
        children: [
          cell('', bg: headerBg),
          cell('', bg: headerBg),
          cell('20', bg: headerBg, isBold: true),
          cell('20', bg: headerBg, isBold: true),
          cell('20', bg: headerBg, isBold: true),
          cell('20', bg: headerBg, isBold: true),
          cell('20', bg: headerBg, isBold: true),
          cell('100', bg: headerBg, isBold: true, textColor: totalColor),
          cell('', bg: commentBg),
        ],
      ),
    );

    // Row 3+: Student rows (take up to 6 students)
    final demoStudents = state.students.isNotEmpty 
        ? state.students 
        : MockData.getSampleStudents();

    for (final student in demoStudents.take(6)) {
      final qScores = <String>[];
      final currentCriteria = student.criteria.isNotEmpty 
          ? student.criteria 
          : MockData.getSampleCriteria();

      for (int i = 0; i < 5; i++) {
        if (currentCriteria.length > i) {
          final maxS = currentCriteria[i].totalMaxScore;
          final earned = student.criteria.isNotEmpty ? currentCriteria[i].totalScore : (maxS * 0.8);
          qScores.add(earned.toStringAsFixed(1));
        } else {
          qScores.add('0.0');
        }
      }

      final studentTotal = student.criteria.isNotEmpty 
          ? student.computedTotal 
          : 80.0;

      rows.add(
        TableRow(
          children: [
            cell(student.alias, align: Alignment.center),
            cell(student.marker ?? 'HungLD5', align: Alignment.center),
            cell(qScores[0]),
            cell(qScores[1]),
            cell(qScores[2]),
            cell(qScores[3]),
            cell(qScores[4]),
            cell(studentTotal.toStringAsFixed(1), isBold: true, textColor: totalColor),
            cell(student.finalPublicComment, align: Alignment.centerLeft),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border0),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 850,
          child: Table(
            border: TableBorder.all(color: AppColors.border0.withOpacity(0.5), width: 0.8),
            columnWidths: const {
              0: FixedColumnWidth(90),   // Alias
              1: FixedColumnWidth(90),   // Marker
              2: FixedColumnWidth(85),   // Q1
              3: FixedColumnWidth(85),   // Q2
              4: FixedColumnWidth(85),   // Q3
              5: FixedColumnWidth(85),   // Q4
              6: FixedColumnWidth(85),   // Q5
              7: FixedColumnWidth(75),   // Total
              8: FlexColumnWidth(),      // Comment
            },
            children: rows,
          ),
        ),
      ),
    );
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
  final StudentSubmission student;
  final int index;
  final bool striped;

  const _StudentPreviewRow({
    required this.student,
    required this.index,
    required this.striped,
  });

  @override
  Widget build(BuildContext context) {
    final status = student.status;
    final statusColor = switch (status) {
      GradingStatus.graded => AppColors.success,
      GradingStatus.inProgress => AppColors.warning,
      GradingStatus.ungraded => AppColors.textMuted,
    };
    final statusLabel = switch (status) {
      GradingStatus.graded => 'Đã chấm',
      GradingStatus.inProgress => 'Đang chấm',
      GradingStatus.ungraded => 'Chưa chấm',
    };
    final score = student.finalScaleScore;

    return Container(
      color: striped ? AppColors.bg2.withOpacity(0.45) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.alias,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              student.name ?? 'Chưa có tên',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _StatusChip(label: statusLabel, color: statusColor),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              score != null ? score.toStringAsFixed(1) : '—',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

