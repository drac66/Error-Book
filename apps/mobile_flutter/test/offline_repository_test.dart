import 'dart:io';

import 'package:error_book_mobile/models/mistake.dart';
import 'package:error_book_mobile/services/database_service.dart';
import 'package:error_book_mobile/services/mistake_repository.dart';
import 'package:error_book_mobile/services/notebook_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late DatabaseService database;
  late MistakeRepository mistakes;
  late NotebookRepository notebooks;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('error_book_test_');
    database = DatabaseService(databasePath: '${tempDir.path}/test.db');
    mistakes = MistakeRepository(database);
    notebooks = NotebookRepository(database);
    await notebooks.ensureDefault();
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  test('SQLite repository creates, filters, updates review status, and deletes',
      () async {
    final mistake = Mistake.create(
      id: 'm1',
      question: '一元二次方程',
      correctAnswer: 'x=1',
      category: '数学',
      tags: ['代数'],
      difficultyLevel: 4,
      importanceLevel: 5,
    );

    await mistakes.upsert(mistake);

    expect(await mistakes.count(), 1);
    expect(await mistakes.list(keyword: '代数'), hasLength(1));
    expect(await mistakes.list(status: MasteryStatus.fresh), hasLength(1));

    final stored = (await mistakes.list()).single;
    expect(stored.difficultyLevel, 4);
    expect(stored.importanceLevel, 5);

    await mistakes.recordReview('m1', MasteryStatus.mastered);
    final reviewed = (await mistakes.list()).single;
    expect(reviewed.masteryStatus, MasteryStatus.mastered);
    expect(reviewed.reviewCount, 1);
    expect(reviewed.lastReviewedAt, isNotNull);

    final stats = await mistakes.stats();
    expect(stats.total, 1);
    expect(stats.mastered, 1);

    await mistakes.delete('m1');
    expect(await mistakes.count(), 0);
  });
}
