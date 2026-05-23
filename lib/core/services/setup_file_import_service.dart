import 'package:file_picker/file_picker.dart';

/// Chọn file/thư mục từ hệ thống cho màn thiết lập phiên chấm.
class SetupFileImportService {
  static Future<({String path, String name})?> pickImage({
    required String dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
      dialogTitle: dialogTitle,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    return (path: path, name: file.name);
  }

  static Future<({String path, String name})?> pickDocx({
    required String dialogTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      allowMultiple: false,
      dialogTitle: dialogTitle,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;
    return (path: path, name: file.name);
  }

  static Future<List<({String path, String name})>>
      pickStudentListFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
      allowMultiple: true,
      dialogTitle: 'Chọn danh sách sinh viên (.csv / .xlsx)',
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return [];

    final files = <({String path, String name})>[];
    for (final file in result.files) {
      final path = file.path;
      if (path == null || path.isEmpty) continue;
      files.add((path: path, name: file.name));
    }
    return files;
  }

  static Future<String?> pickSubmissionFolder() async {
    return FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Chọn thư mục chứa bài làm',
    );
  }
}
