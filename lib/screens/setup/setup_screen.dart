import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/models/app_models.dart';
import '../../widgets/file_drop_card.dart';
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

  @override
  void initState() {
    super.initState();
    // Default select PE01 and load demo data for it
    _selectedSession = _sessions[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppStateProvider>(context, listen: false);
      state.setCurrentSessionName(
          '${_selectedSession!['subject']} / ${_selectedSession!['semester']} / ${_selectedSession!['examCode']}');
      state.loadDemoData();
    });
  }

  void _onSessionSelected(Map<String, dynamic> session) {
    setState(() {
      _selectedSession = session;
    });
    final state = context.read<AppStateProvider>();
    state.setCurrentSessionName(
        '${session['subject']} / ${session['semester']} / ${session['examCode']}');
    if (session['status'] != 'pending') {
      state.loadDemoData();
    } else {
      state.resetSetupData();
    }
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
          // ─── Sidebar ───
          SetupSidebar(
            sessions: _sessions,
            selectedSession: _selectedSession,
            onSessionSelected: _onSessionSelected,
            onCreateSession: _onCreateSession,
            onLogout: () {
              state.navigateTo(AppScreen.login);
            },
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border0),
          // ─── Main Content ───
          Expanded(
            child: _selectedSession != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 850),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                               crossAxisAlignment: CrossAxisAlignment.center,
                               children: [
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         'Mã đề: ${_selectedSession?['examCode'] ?? 'PE01'} - ${_selectedSession?['semester'] ?? 'SP26'}',
                                         style: const TextStyle(
                                           fontSize: 26,
                                           fontWeight: FontWeight.w700,
                                           color: AppColors.textPrimary,
                                           fontFamily: 'Inter',
                                         ),
                                       ),
                                       const SizedBox(height: 6),
                                       Text(
                                         'Học kỳ ${_selectedSession?['semester'] ?? 'SP26'}  /  ${_selectedSession?['subject'] ?? 'PMG201c'} - ${_selectedSession?['type'] ?? 'PE'}',
                                         style: const TextStyle(
                                           fontSize: 14,
                                           fontWeight: FontWeight.w600,
                                           color: AppColors.accentLight,
                                           fontFamily: 'Inter',
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 _buildStatusBadge(_selectedSession?['status'],
                                     _selectedSession?['progress']?.toDouble()),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Text(
                               'Thiết lập dữ liệu cho phiên chấm này để bắt đầu quá trình chấm điểm tự động.  •  Giai đoạn hiện tại: ${state.students.isNotEmpty ? "Sẵn sàng chấm" : (state.setupData.examFileName != null && state.setupData.gradingGuideFileName != null ? "Nhập danh sách sinh viên" : "Thiết lập tài liệu & Barem")}',
                               style: const TextStyle(
                                 fontSize: 13,
                                 color: AppColors.textSecondary,
                                 fontFamily: 'Inter',
                               ),
                             ),
                             const SizedBox(height: 24),
                            _buildSetupCards(context),
                            const SizedBox(height: 32),
                            _buildStudentPreview(context),
                            const SizedBox(height: 32),
                            _buildActionButton(context),
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_edu_rounded, size: 40, color: AppColors.accent),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Hệ thống quản lý & Chấm điểm Project Management',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chọn một phiên chấm thi từ danh sách bên trái hoặc tạo phiên mới để bắt đầu.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 40),
                          Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildFeatureInfoCard(
                                icon: Icons.psychology_outlined,
                                color: AppColors.purple,
                                title: 'AI Assistant Grading',
                                desc: 'Chấm bài thi Project Management thông minh, phân tích chi tiết lỗi logic và đề xuất điểm chuẩn barem.',
                              ),
                              _buildFeatureInfoCard(
                                icon: Icons.table_view_outlined,
                                color: AppColors.success,
                                title: 'Báo cáo điểm chuẩn Excel',
                                desc: 'Xuất kết quả chấm điểm kép (Double-Header) chuẩn chỉ, tích hợp nhận xét chi tiết của sinh viên.',
                              ),
                              _buildFeatureInfoCard(
                                icon: Icons.account_tree_outlined,
                                color: AppColors.accent,
                                title: 'Quản lý lịch sử chấm',
                                desc: 'Quản lý các phiên chấm thi (sessions) trực quan giúp dễ dàng tra cứu, kiểm tra lại quá trình chấm điểm.',
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          OutlinedButton.icon(
                            onPressed: _onCreateSession,
                            icon: const Icon(Icons.add_box_outlined, size: 16),
                            label: const Text('Tạo phiên chấm mới để bắt đầu'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
              height: 1.5,
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
        title: const Text('Tạo phiên chấm mới', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Mã đề',
                  hintText: 'Ví dụ: PE01, FE02...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subController,
                decoration: InputDecoration(
                  labelText: 'Môn học',
                  hintText: 'Ví dụ: PMG201c...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: InputDecoration(
                  labelText: 'Đợt thi (PE / FE)',
                  hintText: 'Ví dụ: PE, FE...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupCards(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final card1 = FileDropCard(
            icon: Icons.description_outlined,
            label: 'Đề thi',
            subtitle: 'File .docx chứa đề thi gốc',
            acceptedTypes: 'DOCX',
            accentColor: AppColors.accent,
            selectedFileName: state.setupData.examFileName,
            onPickFile: () => _pickFile(context, 'exam'),
          );

          final card2 = FileDropCard(
            icon: Icons.rule_rounded,
            label: 'Barem chấm điểm',
            subtitle: 'File .docx chứa tiêu chí & điểm tối đa',
            acceptedTypes: 'DOCX',
            accentColor: AppColors.purple,
            selectedFileName: state.setupData.gradingGuideFileName,
            onPickFile: () => _pickFile(context, 'guide'),
          );

          final card3 = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FileDropCard(
                icon: Icons.table_chart_outlined,
                label: 'Danh sách sinh viên',
                subtitle: 'File .csv (Mark Input template)',
                acceptedTypes: 'CSV',
                accentColor: AppColors.success,
                selectedFileName: state.setupData.csvFileName,
                onPickFile: () => _pickFile(context, 'csv'),
              ),
              if (state.uploadedCSVs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Danh sách đã tải lên (${state.uploadedCSVs.length}):',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: List.generate(state.uploadedCSVs.length, (idx) {
                    final csv = state.uploadedCSVs[idx];
                    final isSelected = state.selectedCSVIndex == idx;
                    return InkWell(
                      onTap: () => state.selectCSVFile(idx),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.bg2,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.success.withOpacity(0.4)
                                : AppColors.border0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.insert_drive_file_outlined,
                              size: 12,
                              color: isSelected
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                csv['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontFamily: 'Inter',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ],
          );

          final card4 = FileDropCard(
            icon: Icons.folder_open_rounded,
            label: 'Thư mục bài thi',
            subtitle: 'Folder chứa bài làm (.txt) của sinh viên',
            acceptedTypes: 'FOLDER',
            accentColor: AppColors.warning,
            selectedFileName: state.setupData.submissionFolderPath != null
                ? state.setupData.submissionFolderPath!.split('/').last
                : null,
            onPickFile: () => _pickFile(context, 'folder'),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card1,
                const SizedBox(height: 16),
                card2,
                const SizedBox(height: 16),
                card3,
                const SizedBox(height: 16),
                card4,
              ],
            );
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 16),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 16),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentPreview(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final students = state.students;
    if (students.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Danh sách sinh viên (${students.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                _StatusChip(
                  label: '${state.gradedCount} đã chấm',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: '${state.ungradedCount} chưa chấm',
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border0),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                return _StudentPreviewRow(student: s, index: i);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => state.loadDemoData(),
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Tải dữ liệu Demo', style: TextStyle(fontFamily: 'Inter')),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: state.students.isNotEmpty
                ? () => state.proceedToGrading()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Bắt đầu chấm điểm', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _pickFile(BuildContext context, String type) {
    final state = context.read<AppStateProvider>();
    // Demo: simulate file picking with mock paths
    switch (type) {
      case 'exam':
        state.setExamFile('/demo/PMG201c-Exam.docx', 'PMG201c-Exam.docx');
        break;
      case 'guide':
        state.setGradingGuide('/demo/PMG201c-GradingGuide.docx', 'PMG201c-GradingGuide.docx');
        break;
      case 'csv':
        state.setCSVFile('/demo/Mark_Input.csv', 'PMG201c_SP26_Mark_Input.csv');
        break;
      case 'folder':
        state.setSubmissionFolder('/demo/submissions');
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
    final hasFiles = state.setupData.examFileName != null && state.setupData.gradingGuideFileName != null;
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
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
    );
  }
}

class _StudentPreviewRow extends StatelessWidget {
  final dynamic student;
  final int index;
  const _StudentPreviewRow({required this.student, required this.index});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border0.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${index + 1}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Inter')),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(student.alias,
                style: const TextStyle(
                    color: AppColors.accentLight, fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(student.name ?? '—',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'Inter')),
          ),
          Expanded(
            flex: 2,
            child: Text(student.marker ?? '—',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Inter')),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
          ),
          const SizedBox(width: 16),
          Text(
            student.finalScaleScore != null ? '${student.finalScaleScore!.toStringAsFixed(1)}/10' : '—',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Inter'),
          ),
        ],
      ),
    );
  }
}
