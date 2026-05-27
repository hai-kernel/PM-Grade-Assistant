import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Persist setup imports in a local SQLite database under app data.
class SetupImportStorageService {
  Database? _db;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final appSupportDir = await getApplicationSupportDirectory();
    final dataDir = Directory(p.join(appSupportDir.path, 'appdata'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }

    final dbFile = File(p.join(dataDir.path, 'setup_imports.sqlite'));
    _db = sqlite3.open(dbFile.path);

    // Schema migration check for session_id column
    try {
      _db!.select('SELECT session_id FROM imported_csvs LIMIT 1');
    } catch (_) {
      try {
        _db!.execute('DROP TABLE IF EXISTS imported_csvs');
        _db!.execute('DROP TABLE IF EXISTS imported_submission_folders');
        _db!.execute('DROP TABLE IF EXISTS setup_files');
      } catch (_) {}
    }

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS imported_csvs (
        session_id TEXT NOT NULL,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (session_id, path)
      )
    ''');
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS imported_submission_folders (
        session_id TEXT NOT NULL,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (session_id, path)
      )
    ''');
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS setup_files (
        session_id TEXT NOT NULL,
        key TEXT NOT NULL,
        path TEXT NOT NULL,
        name TEXT NOT NULL,
        PRIMARY KEY (session_id, key)
      )
    ''');
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        semester TEXT NOT NULL,
        subject TEXT NOT NULL,
        type TEXT NOT NULL,
        exam_code TEXT NOT NULL,
        total_submissions INTEGER NOT NULL,
        progress REAL NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    _initialized = true;
  }

  Future<List<Map<String, String>>> loadCsvImports(String sessionId) async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        'SELECT path, name FROM imported_csvs WHERE session_id = ? ORDER BY created_at ASC',
        [sessionId],
      );
      return result
          .map((row) => {
                'path': (row['path'] ?? '').toString(),
                'name': (row['name'] ?? '').toString(),
              })
          .where((row) => row['path']!.isNotEmpty && row['name']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> loadSubmissionFolderImports(String sessionId) async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        'SELECT path, name FROM imported_submission_folders WHERE session_id = ? ORDER BY created_at ASC',
        [sessionId],
      );
      return result
          .map((row) => {
                'path': (row['path'] ?? '').toString(),
                'name': (row['name'] ?? '').toString(),
              })
          .where((row) => row['path']!.isNotEmpty && row['name']!.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCsvImport({
    required String sessionId,
    required String path,
    required String name,
  }) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO imported_csvs(session_id, path, name, created_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(session_id, path) DO UPDATE SET name = excluded.name
      ''');
      stmt.execute([sessionId, path, name, DateTime.now().millisecondsSinceEpoch]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> saveSubmissionFolderImport({
    required String sessionId,
    required String path,
    required String name,
  }) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO imported_submission_folders(session_id, path, name, created_at)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(session_id, path) DO UPDATE SET name = excluded.name
      ''');
      stmt.execute([sessionId, path, name, DateTime.now().millisecondsSinceEpoch]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> removeCsvImport(String sessionId, String path) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('DELETE FROM imported_csvs WHERE session_id = ? AND path = ?');
      stmt.execute([sessionId, path]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> removeSubmissionFolderImport(String sessionId, String path) async {
    try {
      await _ensureInitialized();
      final stmt = _db!
          .prepare('DELETE FROM imported_submission_folders WHERE session_id = ? AND path = ?');
      stmt.execute([sessionId, path]);
      stmt.dispose();
    } catch (_) {}
  }

  // ─── Grading Guide & Exam File Persistence ─────────────────

  Future<void> saveGradingGuide({required String sessionId, required String path, required String name}) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO setup_files(session_id, key, path, name)
        VALUES (?, 'grading_guide', ?, ?)
        ON CONFLICT(session_id, key) DO UPDATE SET path = excluded.path, name = excluded.name
      ''');
      stmt.execute([sessionId, path, name]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<Map<String, String>?> loadGradingGuide(String sessionId) async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        "SELECT path, name FROM setup_files WHERE session_id = ? AND key = 'grading_guide'",
        [sessionId],
      );
      if (result.isEmpty) return null;
      final row = result.first;
      final path = (row['path'] ?? '').toString();
      final name = (row['name'] ?? '').toString();
      if (path.isEmpty || name.isEmpty) return null;
      return {'path': path, 'name': name};
    } catch (_) {
      return null;
    }
  }

  Future<void> saveExamFile({required String sessionId, required String path, required String name}) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO setup_files(session_id, key, path, name)
        VALUES (?, 'exam_file', ?, ?)
        ON CONFLICT(session_id, key) DO UPDATE SET path = excluded.path, name = excluded.name
      ''');
      stmt.execute([sessionId, path, name]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<Map<String, String>?> loadExamFile(String sessionId) async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        "SELECT path, name FROM setup_files WHERE session_id = ? AND key = 'exam_file'",
        [sessionId],
      );
      if (result.isEmpty) return null;
      final row = result.first;
      final path = (row['path'] ?? '').toString();
      final name = (row['name'] ?? '').toString();
      if (path.isEmpty || name.isEmpty) return null;
      return {'path': path, 'name': name};
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadSessions() async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        'SELECT id, semester, subject, type, exam_code, total_submissions, progress, status FROM sessions ORDER BY created_at DESC',
      );
      return result.map((row) => {
        'id': row['id']?.toString() ?? '',
        'semester': row['semester']?.toString() ?? '',
        'subject': row['subject']?.toString() ?? '',
        'type': row['type']?.toString() ?? '',
        'examCode': row['exam_code']?.toString() ?? '',
        'totalSubmissions': row['total_submissions'] as int? ?? 0,
        'progress': (row['progress'] as num?)?.toDouble() ?? 0.0,
        'status': row['status']?.toString() ?? 'pending',
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(Map<String, dynamic> session) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO sessions(id, semester, subject, type, exam_code, total_submissions, progress, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET 
          semester = excluded.semester,
          subject = excluded.subject,
          type = excluded.type,
          exam_code = excluded.exam_code,
          total_submissions = excluded.total_submissions,
          progress = excluded.progress,
          status = excluded.status
      ''');
      stmt.execute([
        session['id'],
        session['semester'],
        session['subject'],
        session['type'],
        session['examCode'],
        session['totalSubmissions'],
        session['progress'],
        session['status'],
        DateTime.now().millisecondsSinceEpoch,
      ]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> updateSessionProgress(String id, double progress, int total, String status) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        UPDATE sessions SET progress = ?, total_submissions = ?, status = ? WHERE id = ?
      ''');
      stmt.execute([progress, total, status, id]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> clearSessionData(String sessionId) async {
    try {
      await _ensureInitialized();
      final stmt1 = _db!.prepare('DELETE FROM imported_csvs WHERE session_id = ?');
      stmt1.execute([sessionId]);
      stmt1.dispose();
      
      final stmt2 = _db!.prepare('DELETE FROM imported_submission_folders WHERE session_id = ?');
      stmt2.execute([sessionId]);
      stmt2.dispose();
      
      final stmt3 = _db!.prepare('DELETE FROM setup_files WHERE session_id = ?');
      stmt3.execute([sessionId]);
      stmt3.dispose();
    } catch (_) {}
  }

  Future<void> deleteSession(String id) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('DELETE FROM sessions WHERE id = ?');
      stmt.execute([id]);
      stmt.dispose();
      await clearSessionData(id);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    // Retained for compatibility/safety, but modified to do nothing or clear globally.
  }
}
