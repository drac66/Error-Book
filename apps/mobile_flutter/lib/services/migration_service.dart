import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/mistake.dart';
import 'mistake_repository.dart';
import 'notebook_repository.dart';

class MigrationService {
  final MistakeRepository mistakeRepository;
  final NotebookRepository notebookRepository;

  MigrationService({
    required this.mistakeRepository,
    required this.notebookRepository,
  });

  Future<void> run() async {
    await notebookRepository.ensureDefault();
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(AppConfig.migrationFlagKey) == true) return;
    if (await mistakeRepository.count() > 0) {
      await sp.setBool(AppConfig.migrationFlagKey, true);
      return;
    }

    final legacy = await _legacyCache(sp);
    if (legacy.isNotEmpty) {
      await mistakeRepository.insertMany(legacy);
    } else {
      await mistakeRepository.insertMany(await _seedMistakes());
    }
    await sp.setBool(AppConfig.migrationFlagKey, true);
  }

  Future<void> resetToSeed() async {
    final sp = await SharedPreferences.getInstance();
    await mistakeRepository.databaseService.reset();
    await notebookRepository.ensureDefault();
    await mistakeRepository.insertMany(await _seedMistakes());
    await sp.setBool(AppConfig.migrationFlagKey, true);
  }

  Future<List<Mistake>> _legacyCache(SharedPreferences sp) async {
    final raw = sp.getString(AppConfig.legacyCacheKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr
          .map((e) => Mistake.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Mistake>> _seedMistakes() async {
    final raw = await rootBundle.loadString('assets/seed_mistakes.json');
    final arr = jsonDecode(raw) as List<dynamic>;
    return arr.map((e) => Mistake.fromJson(e as Map<String, dynamic>)).toList();
  }
}
