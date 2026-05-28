import 'package:flutter_test/flutter_test.dart';
import 'package:pmg_grade/core/models/app_models.dart';
import 'package:pmg_grade/core/services/ollama_ai_service.dart';

void main() {
  group('OllamaAiService.extractRelevantSection Tests', () {
    final service = OllamaAiService(baseUrl: 'http://localhost:11434', model: 'qwen2.5:7b');

    test('Extracts Request 1 to Request 2', () {
      const submission = '''
Request 1
This is the answer for request 1.
It spans multiple lines.

Request 2
This is the answer for request 2.
''';

      final criterion = GradingCriterion(
        id: 'Q1',
        name: 'Criterion 1',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('This is the answer for request 1.'));
      expect(section, isNot(contains('This is the answer for request 2.')));
    });

    test('Extracts Câu 2 to Câu 3', () {
      const submission = '''
Câu 1: bla bla
Câu 2
Nội dung câu 2 nằm ở đây.
Câu 3: bla bla
''';

      final criterion = GradingCriterion(
        id: 'Q2',
        name: 'Criterion 2',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('Nội dung câu 2 nằm ở đây.'));
      expect(section, isNot(contains('Câu 3')));
    });

    test('Extracts Yêu cầu 3 to Yêu cầu 4', () {
      const submission = '''
Yêu cầu 1: bla
Yêu cầu 3
Nội dung yêu cầu 3.
Yêu cầu 4
Nội dung yêu cầu 4.
''';

      final criterion = GradingCriterion(
        id: 'Q3',
        name: 'Criterion 3',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('Nội dung yêu cầu 3.'));
      expect(section, isNot(contains('Yêu cầu 4')));
    });

    test('Extracts Phần 4 to end', () {
      const submission = '''
Phần 3: bla
Phần 4: 
Nội dung phần 4 cuối cùng.
''';

      final criterion = GradingCriterion(
        id: 'Q4',
        name: 'Criterion 4',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('Nội dung phần 4 cuối cùng.'));
    });

    test('Extracts starting with numbers like 1) and 2)', () {
      const submission = '''
1)
Project Cafe:
Some description.

2)
Project Milk:
Some details.
''';

      final criterion = GradingCriterion(
        id: 'Q1',
        name: 'Criterion 1',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('Project Cafe:'));
      expect(section, isNot(contains('Project Milk:')));
    });

    test('Extracts starting with numbers like 1. and 2.', () {
      const submission = '''
1. Cafe Project
Details.

2. Milk Project
Details.
''';

      final criterion = GradingCriterion(
        id: '1',
        name: 'Criterion 1',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, contains('Cafe Project'));
      expect(section, isNot(contains('Milk Project')));
    });

    test('Falls back to full submission if start line is not found', () {
      const submission = 'Only generic text without labels.';

      final criterion = GradingCriterion(
        id: 'Q5',
        name: 'Criterion 5',
        maxScore: 10,
        subCriteria: [],
      );

      final section = service.extractRelevantSection(submission, criterion);
      expect(section, equals(submission));
    });
  });
}
