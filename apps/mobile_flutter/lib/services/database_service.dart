import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../config/app_config.dart';
import '../models/notebook.dart';

class DatabaseService {
  final String? databasePath;
  Database? _database;

  DatabaseService({this.databasePath});

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath =
        databasePath ?? p.join(await getDatabasesPath(), 'error_book_offline.db');
    _database = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notebooks(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE mistakes(
            id TEXT PRIMARY KEY,
            notebookId TEXT NOT NULL,
            question TEXT NOT NULL,
            wrongAnswer TEXT NOT NULL,
            correctAnswer TEXT NOT NULL,
            reason TEXT NOT NULL,
            category TEXT NOT NULL,
            tagsJson TEXT NOT NULL,
            questionImagePath TEXT NOT NULL,
            wrongAnswerImagePath TEXT NOT NULL,
            correctAnswerImagePath TEXT NOT NULL,
            masteryStatus TEXT NOT NULL,
            reviewCount INTEGER NOT NULL,
            difficultyLevel INTEGER NOT NULL DEFAULT 3,
            importanceLevel INTEGER NOT NULL DEFAULT 3,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            lastReviewedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE review_events(
            id TEXT PRIMARY KEY,
            mistakeId TEXT NOT NULL,
            result TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.insert('notebooks', Notebook.defaultNotebook().toDb());
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = await db.rawQuery('PRAGMA table_info(mistakes)');
          final names = columns
              .map((row) => row['name']?.toString() ?? '')
              .toSet();
          if (!names.contains('difficultyLevel')) {
            await db.execute(
              'ALTER TABLE mistakes ADD COLUMN difficultyLevel INTEGER NOT NULL DEFAULT 3',
            );
          }
          if (!names.contains('importanceLevel')) {
            await db.execute(
              'ALTER TABLE mistakes ADD COLUMN importanceLevel INTEGER NOT NULL DEFAULT 3',
            );
          }
        }
      },
    );
    return _database!;
  }

  Future<void> reset() async {
    final db = await database;
    await db.delete('review_events');
    await db.delete('mistakes');
    await db.delete(
      'notebooks',
      where: 'id <> ?',
      whereArgs: [AppConfig.defaultNotebookId],
    );
    await db.insert(
      'notebooks',
      Notebook.defaultNotebook().toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}
