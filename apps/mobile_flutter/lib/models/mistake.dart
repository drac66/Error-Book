import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../config/app_config.dart';

enum MasteryStatus {
  fresh('new', '新错题'),
  reviewing('reviewing', '复习中'),
  mastered('mastered', '已掌握');

  final String value;
  final String label;

  const MasteryStatus(this.value, this.label);

  static MasteryStatus parse(Object? value) {
    final text = (value ?? '').toString();
    return MasteryStatus.values.firstWhere(
      (status) => status.value == text,
      orElse: () => MasteryStatus.fresh,
    );
  }
}

class Mistake {
  final String id;
  final String notebookId;
  final String question;
  final String wrongAnswer;
  final String correctAnswer;
  final String reason;
  final String category;
  final List<String> tags;
  final String questionImagePath;
  final String wrongAnswerImagePath;
  final String correctAnswerImagePath;
  final MasteryStatus masteryStatus;
  final int reviewCount;
  final int difficultyLevel;
  final int importanceLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;

  const Mistake({
    required this.id,
    required this.notebookId,
    required this.question,
    required this.wrongAnswer,
    required this.correctAnswer,
    required this.reason,
    required this.category,
    required this.tags,
    required this.questionImagePath,
    required this.wrongAnswerImagePath,
    required this.correctAnswerImagePath,
    required this.masteryStatus,
    required this.reviewCount,
    required this.difficultyLevel,
    required this.importanceLevel,
    required this.createdAt,
    required this.updatedAt,
    required this.lastReviewedAt,
  });

  factory Mistake.create({
    String? id,
    String notebookId = AppConfig.defaultNotebookId,
    String question = '',
    String wrongAnswer = '',
    String correctAnswer = '',
    String reason = '',
    String category = '未分类',
    List<String> tags = const [],
    String questionImagePath = '',
    String wrongAnswerImagePath = '',
    String correctAnswerImagePath = '',
    int difficultyLevel = 3,
    int importanceLevel = 3,
  }) {
    final now = DateTime.now();
    return Mistake(
      id: id ?? const Uuid().v4(),
      notebookId: notebookId,
      question: question,
      wrongAnswer: wrongAnswer,
      correctAnswer: correctAnswer,
      reason: reason,
      category: _category(category),
      tags: tags,
      questionImagePath: questionImagePath,
      wrongAnswerImagePath: wrongAnswerImagePath,
      correctAnswerImagePath: correctAnswerImagePath,
      masteryStatus: MasteryStatus.fresh,
      reviewCount: 0,
      difficultyLevel: _level(difficultyLevel),
      importanceLevel: _level(importanceLevel),
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: null,
    );
  }

  factory Mistake.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Mistake(
      id: (json['id'] ?? const Uuid().v4()).toString(),
      notebookId:
          (json['notebookId'] ?? AppConfig.defaultNotebookId).toString(),
      question: (json['question'] ?? '').toString(),
      wrongAnswer: (json['wrongAnswer'] ?? '').toString(),
      correctAnswer: (json['correctAnswer'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      category: _category(json['category']),
      tags: _tags(json['tags']),
      questionImagePath: (json['questionImagePath'] ?? '').toString(),
      wrongAnswerImagePath: (json['wrongAnswerImagePath'] ?? '').toString(),
      correctAnswerImagePath: (json['correctAnswerImagePath'] ?? '').toString(),
      masteryStatus: MasteryStatus.parse(json['masteryStatus']),
      reviewCount: int.tryParse((json['reviewCount'] ?? '0').toString()) ?? 0,
      difficultyLevel: _level(
        int.tryParse((json['difficultyLevel'] ?? '3').toString()) ?? 3,
      ),
      importanceLevel: _level(
        int.tryParse((json['importanceLevel'] ?? '3').toString()) ?? 3,
      ),
      createdAt: _date(json['createdAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? now,
      lastReviewedAt: _date(json['lastReviewedAt']),
    );
  }

  factory Mistake.fromDb(Map<String, Object?> row) => Mistake.fromJson({
        ...row,
        'tags': row['tagsJson'] == null
            ? <String>[]
            : jsonDecode(row['tagsJson'] as String),
      });

  Map<String, dynamic> toJson() => {
        'id': id,
        'notebookId': notebookId,
        'question': question,
        'wrongAnswer': wrongAnswer,
        'correctAnswer': correctAnswer,
        'reason': reason,
        'category': category,
        'tags': tags,
        'questionImagePath': questionImagePath,
        'wrongAnswerImagePath': wrongAnswerImagePath,
        'correctAnswerImagePath': correctAnswerImagePath,
        'masteryStatus': masteryStatus.value,
        'reviewCount': reviewCount,
        'difficultyLevel': difficultyLevel,
        'importanceLevel': importanceLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  Map<String, Object?> toDb() => {
        'id': id,
        'notebookId': notebookId,
        'question': question,
        'wrongAnswer': wrongAnswer,
        'correctAnswer': correctAnswer,
        'reason': reason,
        'category': category,
        'tagsJson': jsonEncode(tags),
        'questionImagePath': questionImagePath,
        'wrongAnswerImagePath': wrongAnswerImagePath,
        'correctAnswerImagePath': correctAnswerImagePath,
        'masteryStatus': masteryStatus.value,
        'reviewCount': reviewCount,
        'difficultyLevel': difficultyLevel,
        'importanceLevel': importanceLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      };

  Mistake copyWith({
    String? id,
    String? notebookId,
    String? question,
    String? wrongAnswer,
    String? correctAnswer,
    String? reason,
    String? category,
    List<String>? tags,
    String? questionImagePath,
    String? wrongAnswerImagePath,
    String? correctAnswerImagePath,
    MasteryStatus? masteryStatus,
    int? reviewCount,
    int? difficultyLevel,
    int? importanceLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
  }) {
    return Mistake(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      question: question ?? this.question,
      wrongAnswer: wrongAnswer ?? this.wrongAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      reason: reason ?? this.reason,
      category: _category(category ?? this.category),
      tags: tags ?? this.tags,
      questionImagePath: questionImagePath ?? this.questionImagePath,
      wrongAnswerImagePath: wrongAnswerImagePath ?? this.wrongAnswerImagePath,
      correctAnswerImagePath:
          correctAnswerImagePath ?? this.correctAnswerImagePath,
      masteryStatus: masteryStatus ?? this.masteryStatus,
      reviewCount: reviewCount ?? this.reviewCount,
      difficultyLevel: _level(difficultyLevel ?? this.difficultyLevel),
      importanceLevel: _level(importanceLevel ?? this.importanceLevel),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt:
          clearLastReviewedAt ? null : lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  String get title => question.trim().isEmpty ? '图片错题' : question.trim();

  bool get hasImage =>
      questionImagePath.isNotEmpty ||
      wrongAnswerImagePath.isNotEmpty ||
      correctAnswerImagePath.isNotEmpty;

  static String _category(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '未分类' : text;
  }

  static int _level(int value) => value.clamp(1, 5);

  static List<String> _tags(Object? value) {
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
