// lib/core/models/app_models.dart
// Data models for the PMG Grade application

/// Represents a single sub-criteria within a grading criterion
class SubCriteria {
  final String id;       // e.g. "1.1", "1.2"
  final String name;     // e.g. "Project Name"
  final String description;
  final double maxScore;
  double? aiScore;       // AI suggested score
  String? aiReason;      // AI reasoning
  double? manualScore;   // Teacher's final score
  String? deductReason;  // Reason for deduction

  SubCriteria({
    required this.id,
    required this.name,
    required this.description,
    required this.maxScore,
    this.aiScore,
    this.aiReason,
    this.manualScore,
    this.deductReason,
  });

  double get effectiveScore => manualScore ?? aiScore ?? 0;

  SubCriteria copyWith({
    double? manualScore,
    String? deductReason,
    double? aiScore,
    String? aiReason,
  }) {
    return SubCriteria(
      id: id,
      name: name,
      description: description,
      maxScore: maxScore,
      aiScore: aiScore ?? this.aiScore,
      aiReason: aiReason ?? this.aiReason,
      manualScore: manualScore ?? this.manualScore,
      deductReason: deductReason ?? this.deductReason,
    );
  }
}

/// Represents a main grading criterion (Question / Requirement)
class GradingCriterion {
  final String id;       // e.g. "Q1", "Q2" or "Yêu cầu 1"
  final String name;
  final double maxScore;
  final List<SubCriteria> subCriteria;
  String? generalComment;

  GradingCriterion({
    required this.id,
    required this.name,
    required this.maxScore,
    required this.subCriteria,
    this.generalComment,
  });

  double get totalScore => subCriteria.fold(0, (sum, sc) => sum + sc.effectiveScore);
  double get totalMaxScore => subCriteria.fold(0, (sum, sc) => sum + sc.maxScore);

  bool get isFullyGraded => subCriteria.every((sc) => sc.manualScore != null);

  GradingCriterion copyWith({
    String? generalComment,
  }) {
    return GradingCriterion(
      id: id,
      name: name,
      maxScore: maxScore,
      subCriteria: subCriteria,
      generalComment: generalComment ?? this.generalComment,
    );
  }
}

/// Grading status of a student submission
enum GradingStatus { ungraded, inProgress, graded }

/// Represents a student's submission
class StudentSubmission {
  final String alias;        // Student ID / alias (from CSV)
  final String? name;        // Student display name
  final String? marker;      // Assigned marker (teacher)
  final String filePath;     // Path to submission file (.txt)
  String fileContent;        // Loaded file content
  
  GradingStatus status;
  List<GradingCriterion> criteria;  // Filled in during grading
  
  String publicComment;   // Visible to student
  String privateNote;     // Teacher's private note
  
  double? finalScore;          // On scale of 100
  double? finalScaleScore;     // On scale of 10
  bool isExported;

  StudentSubmission({
    required this.alias,
    this.name,
    this.marker,
    required this.filePath,
    this.fileContent = '',
    this.status = GradingStatus.ungraded,
    this.criteria = const [],
    this.publicComment = '',
    this.privateNote = '',
    this.finalScore,
    this.finalScaleScore,
    this.isExported = false,
  });

  double get computedTotal => criteria.fold(0, (sum, c) => sum + c.totalScore);
  double get maxTotal => criteria.fold(0, (sum, c) => sum + c.totalMaxScore);
  double get computedScale10 => maxTotal > 0 ? (computedTotal / maxTotal) * 10 : 0;

  String get autoPublicComment {
    return "";
  }

  String get autoPrivateNote {
    List<String> generalComments = [];
    for (final c in criteria) {
      if (c.generalComment != null && c.generalComment!.trim().isNotEmpty) {
        generalComments.add("${c.id}: ${c.generalComment!.trim()}");
      }
    }
    if (generalComments.isNotEmpty) {
      return "Nhận xét riêng tư:\n- ${generalComments.join('\n- ')}";
    }
    return "";
  }

  String get finalPublicComment => [publicComment, autoPublicComment].where((s) => s.trim().isNotEmpty).join('\n\n');
  String get finalPrivateNote => [privateNote, autoPrivateNote].where((s) => s.trim().isNotEmpty).join('\n\n');
}

/// App-level setup state
class SetupData {
  String? examFilePath;        // .docx exam file
  String? examFileName;
  String examContent;          // Loaded exam content

  String? gradingGuidePath;    // .docx grading guide
  String? gradingGuideFileName;
  
  String? csvFilePath;         // .csv student list
  String? csvFileName;
  
  String? submissionFolderPath; // folder with student .txt files
  
  List<GradingCriterion> parsedCriteria;
  List<StudentSubmission> students;
  
  SetupData({
    this.examFilePath,
    this.examFileName,
    this.examContent = '',
    this.gradingGuidePath,
    this.gradingGuideFileName,
    this.csvFilePath,
    this.csvFileName,
    this.submissionFolderPath,
    this.parsedCriteria = const [],
    this.students = const [],
  });

  bool get isReadyToGrade =>
      csvFilePath != null &&
      submissionFolderPath != null &&
      parsedCriteria.isNotEmpty &&
      students.isNotEmpty;
}

/// AI grading suggestion for a single criterion
class AISuggestion {
  final String criteriaId;
  final double suggestedScore;
  final String reason;
  final List<String> deductions;

  AISuggestion({
    required this.criteriaId,
    required this.suggestedScore,
    required this.reason,
    this.deductions = const [],
  });
}

/// Mock data for demo purposes
class MockData {
  static List<GradingCriterion> getSampleCriteria() {
    return [
      GradingCriterion(
        id: 'Q1',
        name: 'Yêu cầu 1 - Project Charter',
        maxScore: 20,
        subCriteria: [
          SubCriteria(
            id: '1.1',
            name: 'Project Name',
            description: 'Tên dự án phải rõ ràng, có ý nghĩa và phản ánh mục tiêu chính của dự án.',
            maxScore: 2,
            aiScore: 2,
            aiReason: 'Tên dự án "Smart Campus Management System" rõ ràng và phù hợp.',
          ),
          SubCriteria(
            id: '1.2',
            name: 'Project Purpose & Objectives',
            description: 'Mô tả mục đích và mục tiêu SMART của dự án.',
            maxScore: 5,
            aiScore: 4,
            aiReason: 'Mục tiêu được trình bày nhưng chưa đạt chuẩn SMART hoàn toàn (thiếu Time-bound cụ thể).',
          ),
          SubCriteria(
            id: '1.3',
            name: 'Scope Statement',
            description: 'Phạm vi dự án cần xác định rõ In-scope và Out-of-scope.',
            maxScore: 5,
            aiScore: 3,
            aiReason: 'Phần In-scope tốt nhưng Out-of-scope còn thiếu nhiều mục.',
          ),
          SubCriteria(
            id: '1.4',
            name: 'Stakeholders',
            description: 'Xác định đầy đủ các bên liên quan và vai trò.',
            maxScore: 5,
            aiScore: 5,
            aiReason: 'Đã xác định đầy đủ tất cả stakeholders với role và interest rõ ràng.',
          ),
          SubCriteria(
            id: '1.5',
            name: 'Budget Estimate',
            description: 'Ước tính ngân sách sơ bộ với các hạng mục chi tiết.',
            maxScore: 3,
            aiScore: 2,
            aiReason: 'Có ước tính ngân sách nhưng chưa phân tích các hạng mục chi tiết.',
          ),
        ],
      ),
      GradingCriterion(
        id: 'Q2',
        name: 'Yêu cầu 2 - Work Breakdown Structure',
        maxScore: 20,
        subCriteria: [
          SubCriteria(
            id: '2.1',
            name: 'WBS Structure (3 levels minimum)',
            description: 'WBS phải có ít nhất 3 cấp độ phân rã công việc.',
            maxScore: 8,
            aiScore: 7,
            aiReason: 'WBS có 3 cấp nhưng một số work packages chưa đủ chi tiết ở level 3.',
          ),
          SubCriteria(
            id: '2.2',
            name: 'WBS Dictionary',
            description: 'Từ điển WBS mô tả chi tiết từng work package.',
            maxScore: 7,
            aiScore: 5,
            aiReason: 'WBS Dictionary tồn tại nhưng còn thiếu description cho 4/12 work packages.',
          ),
          SubCriteria(
            id: '2.3',
            name: 'Deliverables Identification',
            description: 'Xác định rõ các deliverables cho từng phase.',
            maxScore: 5,
            aiScore: 5,
            aiReason: 'Deliverables được xác định rõ ràng cho tất cả phases.',
          ),
        ],
      ),
      GradingCriterion(
        id: 'Q3',
        name: 'Yêu cầu 3 - Schedule Management',
        maxScore: 20,
        subCriteria: [
          SubCriteria(
            id: '3.1',
            name: 'Gantt Chart',
            description: 'Biểu đồ Gantt hiển thị đầy đủ các activities, dependencies và milestones.',
            maxScore: 10,
            aiScore: 8,
            aiReason: 'Gantt chart đầy đủ nhưng một số dependencies chưa được vẽ đúng (Finish-to-Start).',
          ),
          SubCriteria(
            id: '3.2',
            name: 'Critical Path Analysis',
            description: 'Phân tích đường găng (Critical Path) rõ ràng.',
            maxScore: 6,
            aiScore: 4,
            aiReason: 'Critical Path được xác định nhưng tính toán Float chưa chính xác ở task 5 và 8.',
          ),
          SubCriteria(
            id: '3.3',
            name: 'Milestones',
            description: 'Xác định ít nhất 5 milestones quan trọng.',
            maxScore: 4,
            aiScore: 4,
            aiReason: 'Đủ 7 milestones, tất cả đều có ngày hoàn thành rõ ràng.',
          ),
        ],
      ),
      GradingCriterion(
        id: 'Q4',
        name: 'Yêu cầu 4 - Risk Management',
        maxScore: 20,
        subCriteria: [
          SubCriteria(
            id: '4.1',
            name: 'Risk Identification',
            description: 'Xác định ít nhất 10 rủi ro tiềm tàng.',
            maxScore: 8,
            aiScore: 6,
            aiReason: 'Chỉ xác định được 7 rủi ro. Còn thiếu rủi ro về security và technical debt.',
          ),
          SubCriteria(
            id: '4.2',
            name: 'Risk Matrix (Probability × Impact)',
            description: 'Ma trận đánh giá rủi ro đúng chuẩn.',
            maxScore: 7,
            aiScore: 7,
            aiReason: 'Risk Matrix chính xác và đầy đủ với đánh giá P×I rõ ràng.',
          ),
          SubCriteria(
            id: '4.3',
            name: 'Risk Response Plan',
            description: 'Kế hoạch ứng phó cho từng rủi ro cao.',
            maxScore: 5,
            aiScore: 3,
            aiReason: 'Risk response plan chỉ có Avoid và Accept. Chưa có Mitigate hoặc Transfer strategies.',
          ),
        ],
      ),
      GradingCriterion(
        id: 'Q5',
        name: 'Yêu cầu 5 - Communication & Presentation',
        maxScore: 20,
        subCriteria: [
          SubCriteria(
            id: '5.1',
            name: 'Document Formatting',
            description: 'Tài liệu được format chuyên nghiệp, nhất quán.',
            maxScore: 5,
            aiScore: 5,
            aiReason: 'Format tài liệu rất chuyên nghiệp, font chữ và spacing nhất quán.',
          ),
          SubCriteria(
            id: '5.2',
            name: 'Communication Plan',
            description: 'Kế hoạch truyền thông nội bộ và ngoại vi.',
            maxScore: 8,
            aiScore: 6,
            aiReason: 'Communication Plan có đủ các thành phần cơ bản nhưng tần suất họp chưa cụ thể.',
          ),
          SubCriteria(
            id: '5.3',
            name: 'Presentation Quality',
            description: 'Chất lượng trình bày tổng thể.',
            maxScore: 7,
            aiScore: 6,
            aiReason: 'Trình bày rõ ràng, logic. Một số slide chứa quá nhiều text.',
          ),
        ],
      ),
    ];
  }

  static List<StudentSubmission> getSampleStudents() {
    return [
      StudentSubmission(
        alias: 'Alias_01',
        name: 'Nguyễn Văn An',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_01.txt',
        status: GradingStatus.graded,
        publicComment: 'Bài làm tốt, cần cải thiện phần Risk Management.',
        privateNote: 'Chăm chỉ, có tiến bộ rõ rệt so với kỳ trước.',
        finalScore: 78,
        finalScaleScore: 7.8,
        isExported: false,
      ),
      StudentSubmission(
        alias: 'Alias_02',
        name: 'Trần Thị Bình',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_02.txt',
        status: GradingStatus.inProgress,
        publicComment: '',
        privateNote: '',
      ),
      StudentSubmission(
        alias: 'Alias_03',
        name: 'Lê Minh Cường',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_03.txt',
        status: GradingStatus.ungraded,
      ),
      StudentSubmission(
        alias: 'Alias_04',
        name: 'Phạm Thu Dung',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_04.txt',
        status: GradingStatus.graded,
        finalScore: 92,
        finalScaleScore: 9.2,
      ),
      StudentSubmission(
        alias: 'Alias_05',
        name: 'Hoàng Văn Em',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_05.txt',
        status: GradingStatus.ungraded,
      ),
      StudentSubmission(
        alias: 'Alias_06',
        name: 'Vũ Thị Phương',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_06.txt',
        status: GradingStatus.ungraded,
      ),
      StudentSubmission(
        alias: 'Alias_07',
        name: 'Đặng Quốc Giang',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_07.txt',
        status: GradingStatus.graded,
        finalScore: 65,
        finalScaleScore: 6.5,
      ),
      StudentSubmission(
        alias: 'Alias_08',
        name: 'Bùi Thị Hà',
        marker: 'Teacher A',
        filePath: '/submissions/Alias_08.txt',
        status: GradingStatus.ungraded,
      ),
    ];
  }

  static const String sampleSubmission = '''
PROJECT MANAGEMENT - FINAL EXAM SUBMISSION
Student ID: Alias_02
Date: May 15, 2026

═══════════════════════════════════════════
QUESTION 1: PROJECT CHARTER (20 points)
═══════════════════════════════════════════

1.1 PROJECT NAME
"Smart Campus Management System" (SCMS)
- A comprehensive digital platform for FPT University campus operations

1.2 PROJECT PURPOSE & OBJECTIVES
Purpose: To digitize and streamline campus operations at FPT University, 
reducing manual work by 60% and improving student satisfaction scores.

Objectives:
• Reduce administrative processing time from 3 days to 4 hours
• Achieve 85% student satisfaction rate within 6 months of deployment
• Handle 10,000+ concurrent users without performance degradation
• Integrate with existing FPT IT infrastructure

1.3 SCOPE STATEMENT
IN-SCOPE:
- Student registration and enrollment management
- Dormitory management and booking system
- Library management with digital catalog
- Campus facility booking system
- Financial management for student fees
- Mobile app for iOS and Android

OUT-OF-SCOPE:
- Human resources management for staff
- Payroll processing system

1.4 STAKEHOLDERS
Primary Stakeholders:
• Project Sponsor: FPT University Board of Directors
• Project Manager: IT Department Head
• End Users: Students (15,000), Academic Staff (800), Admin Staff (200)

Secondary Stakeholders:
• FPT Software (technical partner)
• Ministry of Education (regulatory compliance)
• Students' Union (feedback channel)

1.5 BUDGET ESTIMATE
Total Estimated Budget: 2,500,000,000 VND
- Software Development: 1,200,000,000 VND (48%)
- Infrastructure & Servers: 600,000,000 VND (24%)  
- Training & Change Management: 300,000,000 VND (12%)
- Testing & QA: 250,000,000 VND (10%)
- Contingency Reserve (15%): 150,000,000 VND (6%)

═══════════════════════════════════════════
QUESTION 2: WORK BREAKDOWN STRUCTURE (20 points)
═══════════════════════════════════════════

2.1 WBS STRUCTURE

Level 1: Smart Campus Management System
├── Level 2: 1.0 Project Management
│   ├── Level 3: 1.1 Project Planning
│   ├── Level 3: 1.2 Status Reporting
│   └── Level 3: 1.3 Project Closure
├── Level 2: 2.0 Requirements & Design
│   ├── Level 3: 2.1 Requirements Gathering
│   ├── Level 3: 2.2 System Architecture Design
│   └── Level 3: 2.3 UI/UX Design
├── Level 2: 3.0 Development
│   ├── Level 3: 3.1 Backend Development
│   ├── Level 3: 3.2 Frontend Development
│   └── Level 3: 3.3 Mobile Development
├── Level 2: 4.0 Testing & QA
│   ├── Level 3: 4.1 Unit Testing
│   ├── Level 3: 4.2 Integration Testing
│   └── Level 3: 4.3 User Acceptance Testing
└── Level 2: 5.0 Deployment & Training
    ├── Level 3: 5.1 Production Deployment
    └── Level 3: 5.2 User Training

2.2 WBS DICTIONARY (Selected entries)

WP 2.1 - Requirements Gathering
Duration: 3 weeks | Owner: Business Analyst Team
Description: Conduct interviews with 50+ stakeholders, analyze existing 
systems, document functional and non-functional requirements.
Deliverable: Requirements Specification Document v1.0

WP 3.1 - Backend Development  
Duration: 12 weeks | Owner: Backend Team (5 developers)
Description: Develop RESTful APIs, database schemas, business logic layers.
Tech Stack: Spring Boot, PostgreSQL, Redis, Kafka
Deliverable: Fully functional backend services with 80%+ test coverage

═══════════════════════════════════════════
QUESTION 3: SCHEDULE MANAGEMENT (20 points)
═══════════════════════════════════════════

3.1 GANTT CHART (Described in text format)

Phase 1: Initiation (Weeks 1-2)
[████░░░░░░░░░░░░░░░░░░░░░░░░] Project Charter
[████░░░░░░░░░░░░░░░░░░░░░░░░] Stakeholder Analysis

Phase 2: Planning (Weeks 2-6)  
[░░██████░░░░░░░░░░░░░░░░░░░░] Requirements Gathering
[░░░░████░░░░░░░░░░░░░░░░░░░░] System Design

Phase 3: Development (Weeks 6-20)
[░░░░░░██████████████░░░░░░░░] Backend Development
[░░░░░░████████████████░░░░░░] Frontend Development

Phase 4: Testing (Weeks 18-24)
[░░░░░░░░░░░░░░░░░░██████░░░░] Testing & QA

Phase 5: Deployment (Weeks 24-26)
[░░░░░░░░░░░░░░░░░░░░░░░░████] Deployment & Training

3.2 CRITICAL PATH ANALYSIS
Critical Path: Requirements → System Design → Backend Dev → Integration Test → UAT → Deployment
Total Duration: 26 weeks (6.5 months)

Activity | Duration | ES | EF | LS | LF | Float
---------|----------|----|----|----|----|------
Req. Gathering | 4w | 0 | 4 | 0 | 4 | 0 (CRITICAL)
System Design | 2w | 4 | 6 | 4 | 6 | 0 (CRITICAL)
Backend Dev | 12w | 6 | 18 | 6 | 18 | 0 (CRITICAL)
Frontend Dev | 14w | 6 | 20 | 6 | 20 | 2 (non-critical)

3.3 MILESTONES
M1: Project Charter Approved - Week 2
M2: Requirements Baseline - Week 5
M3: Design Approval - Week 8
M4: Backend MVP Complete - Week 16
M5: Frontend MVP Complete - Week 18
M6: UAT Sign-off - Week 24
M7: Production Go-Live - Week 26

═══════════════════════════════════════════
QUESTION 4: RISK MANAGEMENT (20 points)
═══════════════════════════════════════════

4.1 RISK IDENTIFICATION

Risk 1: Key personnel resignation during development
Risk 2: Scope creep from stakeholder change requests
Risk 3: Integration failures with existing FPT systems
Risk 4: Budget overrun due to unforeseen technical complexity
Risk 5: Poor user adoption after deployment
Risk 6: Data migration issues from legacy system
Risk 7: Regulatory compliance changes mid-project

4.2 RISK MATRIX (Probability × Impact)

Risk | Probability | Impact | Score | Priority
-----|-------------|--------|-------|--------
Key personnel | Medium(3) | High(4) | 12 | HIGH
Scope creep | High(4) | High(4) | 16 | CRITICAL
Integration fail | Low(2) | High(5) | 10 | HIGH
Budget overrun | Medium(3) | Medium(3) | 9 | MEDIUM
User adoption | Medium(3) | High(4) | 12 | HIGH
Data migration | Low(2) | High(4) | 8 | MEDIUM
Regulatory | Low(1) | Medium(3) | 3 | LOW

4.3 RISK RESPONSE PLAN
Risk: Scope Creep → AVOID: Strict change control process, CCB approval required
Risk: Key Personnel → ACCEPT: Document all knowledge, cross-training program
Risk: Integration Failure → ACCEPT: Manual fallback procedures

═══════════════════════════════════════════
QUESTION 5: COMMUNICATION PLAN (20 points)
═══════════════════════════════════════════

5.1 DOCUMENT FORMATTING
[This document follows IEEE format with consistent headers, Times New Roman 12pt]

5.2 COMMUNICATION PLAN

Audience | Method | Frequency | Owner
---------|--------|-----------|------
Sponsor | Status Report | Monthly | PM
Core Team | Stand-up Meeting | Daily | PM  
Stakeholders | Progress Report | Bi-weekly | PM
End Users | Newsletter | Monthly | Comm. Lead

5.3 PRESENTATION APPROACH
The project will use a hybrid communication approach combining:
- Digital dashboards on intranet portal
- Weekly email digest with key metrics
- Quarterly town hall meetings for major announcements
''';
}
