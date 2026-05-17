import 'database_service.dart';
import 'image_storage_service.dart';
import 'image_text_service.dart';
import 'migration_service.dart';
import 'mistake_repository.dart';
import 'notebook_repository.dart';

class AppServices {
  final DatabaseService database;
  final MistakeRepository mistakes;
  final NotebookRepository notebooks;
  final ImageStorageService imageStorage;
  final ImagePickService imagePicker;
  final OcrService ocr;
  final MigrationService migration;

  AppServices._({
    required this.database,
    required this.mistakes,
    required this.notebooks,
    required this.imageStorage,
    required this.imagePicker,
    required this.ocr,
    required this.migration,
  });

  factory AppServices.create({DatabaseService? database}) {
    database ??= DatabaseService();
    final mistakes = MistakeRepository(database);
    final notebooks = NotebookRepository(database);
    return AppServices._(
      database: database,
      mistakes: mistakes,
      notebooks: notebooks,
      imageStorage: ImageStorageService(),
      imagePicker: ImagePickService(),
      ocr: OcrService(),
      migration: MigrationService(
          mistakeRepository: mistakes, notebookRepository: notebooks),
    );
  }
}
