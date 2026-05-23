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

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS imported_csvs (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    _db!.execute('''
      CREATE TABLE IF NOT EXISTS imported_submission_folders (
        path TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    _initialized = true;
  }

  Future<List<Map<String, String>>> loadCsvImports() async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        'SELECT path, name FROM imported_csvs ORDER BY created_at ASC',
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

  Future<List<Map<String, String>>> loadSubmissionFolderImports() async {
    try {
      await _ensureInitialized();
      final result = _db!.select(
        'SELECT path, name FROM imported_submission_folders ORDER BY created_at ASC',
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
    required String path,
    required String name,
  }) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO imported_csvs(path, name, created_at)
        VALUES (?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET name = excluded.name
      ''');
      stmt.execute([path, name, DateTime.now().millisecondsSinceEpoch]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> saveSubmissionFolderImport({
    required String path,
    required String name,
  }) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('''
        INSERT INTO imported_submission_folders(path, name, created_at)
        VALUES (?, ?, ?)
        ON CONFLICT(path) DO UPDATE SET name = excluded.name
      ''');
      stmt.execute([path, name, DateTime.now().millisecondsSinceEpoch]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> removeCsvImport(String path) async {
    try {
      await _ensureInitialized();
      final stmt = _db!.prepare('DELETE FROM imported_csvs WHERE path = ?');
      stmt.execute([path]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> removeSubmissionFolderImport(String path) async {
    try {
      await _ensureInitialized();
      final stmt = _db!
          .prepare('DELETE FROM imported_submission_folders WHERE path = ?');
      stmt.execute([path]);
      stmt.dispose();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      _db!.execute('DELETE FROM imported_csvs');
      _db!.execute('DELETE FROM imported_submission_folders');
    } catch (_) {}
  }
}
