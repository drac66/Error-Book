import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/notebook.dart';
import 'database_service.dart';

class NotebookRepository {
  final DatabaseService databaseService;

  NotebookRepository(this.databaseService);

  Future<List<Notebook>> list() async {
    final db = await databaseService.database;
    final rows = await db.query('notebooks', orderBy: 'createdAt ASC');
    return rows.map(Notebook.fromDb).toList();
  }

  Future<Notebook> ensureDefault() async {
    final db = await databaseService.database;
    final notebook = Notebook.defaultNotebook();
    await db.insert('notebooks', notebook.toDb(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
    return notebook;
  }

  Future<Notebook> create(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw Exception('错题本名称不能为空');
    }

    final db = await databaseService.database;
    final existing = await db.query(
      'notebooks',
      where: 'name = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return Notebook.fromDb(existing.first);
    }

    final now = DateTime.now();
    final notebook = Notebook(
      id: const Uuid().v4(),
      name: normalized,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('notebooks', notebook.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return notebook;
  }
}
