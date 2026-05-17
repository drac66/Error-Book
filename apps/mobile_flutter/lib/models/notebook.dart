import '../config/app_config.dart';

class Notebook {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Notebook({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notebook.defaultNotebook() {
    final now = DateTime.now();
    return Notebook(
      id: AppConfig.defaultNotebookId,
      name: AppConfig.defaultNotebookName,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Notebook.fromDb(Map<String, Object?> row) => Notebook(
        id: row['id'].toString(),
        name: row['name'].toString(),
        createdAt: DateTime.parse(row['createdAt'].toString()),
        updatedAt: DateTime.parse(row['updatedAt'].toString()),
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
