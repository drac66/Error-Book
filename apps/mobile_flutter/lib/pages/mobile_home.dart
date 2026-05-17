import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/app_stats.dart';
import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';
import 'dashboard_page.dart';
import 'mistake_form_page.dart';
import 'notebook_review_detail_page.dart';
import 'review_checkin_page.dart';
import 'review_page.dart';
import 'review_plan_session_page.dart';
import 'settings_page.dart';

class MobileHome extends StatefulWidget {
  final AppServices services;

  const MobileHome({super.key, required this.services});

  @override
  State<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends State<MobileHome> {
  static const _kLastNotebookId = 'last_notebook_id';
  static const _kLastNotebookName = 'last_notebook_name';
  static const _kLastMistakeTitle = 'last_mistake_title';

  int tab = 0;
  bool loading = true;
  List<Mistake> mistakes = [];
  List<Notebook> notebooks = [];
  AppStats stats = AppStats.empty;
  ReviewDashboardStats reviewStats = ReviewDashboardStats.empty;
  String currentNotebookId = 'all';
  String currentNotebookName = '全部错题';
  String currentMistakeTitle = '暂无';
  String? loadError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadStudyState();
      await widget.services.migration.run();
      await _refresh();
      if (mounted) {
        setState(() {
          loading = false;
          loadError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  Future<void> _loadStudyState() async {
    final sp = await SharedPreferences.getInstance();
    currentNotebookId = sp.getString(_kLastNotebookId) ?? 'all';
    currentNotebookName = sp.getString(_kLastNotebookName) ?? '全部错题';
    currentMistakeTitle = sp.getString(_kLastMistakeTitle) ?? '暂无';
  }

  Future<void> _saveStudyState({
    String? notebookId,
    String? notebookName,
    String? mistakeTitle,
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (notebookId != null && notebookId.trim().isNotEmpty) {
      currentNotebookId = notebookId;
      await sp.setString(_kLastNotebookId, notebookId);
    }
    if (notebookName != null && notebookName.trim().isNotEmpty) {
      currentNotebookName = notebookName;
      await sp.setString(_kLastNotebookName, notebookName);
    }
    if (mistakeTitle != null && mistakeTitle.trim().isNotEmpty) {
      currentMistakeTitle = mistakeTitle;
      await sp.setString(_kLastMistakeTitle, mistakeTitle);
    }
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    final nextMistakes = await widget.services.mistakes.list();
    final nextNotebooks = await widget.services.notebooks.list();

    final resolvedNotebookId = currentNotebookId == 'all' ||
            nextNotebooks.any((e) => e.id == currentNotebookId)
        ? currentNotebookId
        : 'all';
    final scopedNotebookId = _scopeNotebookId(resolvedNotebookId);
    if (resolvedNotebookId != currentNotebookId) {
      currentNotebookId = resolvedNotebookId;
      currentNotebookName = resolvedNotebookId == 'all'
          ? '全部错题'
          : nextNotebooks
              .firstWhere((e) => e.id == resolvedNotebookId)
              .name;
    }

    AppStats nextStats = AppStats.empty;
    ReviewDashboardStats nextReviewStats = ReviewDashboardStats.empty;
    try {
      nextStats = await widget.services.mistakes.stats(
        notebookId: scopedNotebookId,
      );
    } catch (_) {
      nextStats = AppStats.empty;
    }
    try {
      nextReviewStats = await widget.services.mistakes.reviewDashboardStats(
        notebookId: scopedNotebookId,
      );
    } catch (_) {
      nextReviewStats = ReviewDashboardStats.empty;
    }

    if (!mounted) return;
    setState(() {
      mistakes = nextMistakes;
      notebooks = nextNotebooks;
      stats = nextStats;
      reviewStats = nextReviewStats;
      loadError = null;
    });
  }

  Future<void> _openForm({Mistake? mistake}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MistakeFormPage(
          services: widget.services,
          notebooks: notebooks,
          existing: mistake,
        ),
      ),
    );
    if (changed == true) await _refresh();
  }

  Future<void> _startTodayPlan() async {
    final scopedNotebookId = _scopeNotebookId(currentNotebookId);
    final notebook = scopedNotebookId == 'all'
        ? null
        : notebooks
            .where((e) => e.id == currentNotebookId)
            .cast<Notebook?>()
            .firstWhere((e) => e != null, orElse: () => null);
    final remaining = await widget.services.mistakes.remainingPlannedReviewList(
      notebookId: scopedNotebookId,
    );
    if (!mounted) return;

    if (remaining.isEmpty) {
      final navigator = Navigator.of(context);
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ReviewCheckinPage(
            streak: reviewStats.checkinStreak,
            checkedInToday: reviewStats.checkedInToday,
            todayReviewed: reviewStats.todayReviewed,
            todayPlanned: reviewStats.todayPlanned,
          ),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    await _saveStudyState(
      notebookId: currentNotebookId,
      notebookName: currentNotebookName,
      mistakeTitle: remaining.first.title,
    );
    if (!mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => ReviewPlanSessionPage(
            services: widget.services,
            notebook: notebook,
          notebookName: currentNotebookName,
          onChanged: _refresh,
          onStudyStateChanged: (b, t) {
            _saveStudyState(
              notebookId: notebook?.id ?? currentNotebookId,
              notebookName: b,
              mistakeTitle: t,
            );
          },
        ),
      ),
    );
    await _refresh();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _scopeNotebookId(String notebookId) {
    return notebookId == AppConfig.defaultNotebookId ? 'all' : notebookId;
  }

  Future<void> _createNotebookFromHome() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建错题本'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入错题本名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await widget.services.notebooks.create(name);
    await _refresh();
    if (!mounted) return;
    _toast('已创建错题本：$name');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Color(0xFFE76F51)),
                const SizedBox(height: 12),
                const Text(
                  '主页初始化失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => loading = true);
                    _init();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pages = [
      DashboardPage(
        stats: stats,
        recentMistakes: mistakes.take(3).toList(),
        onQuickAdd: () => _openForm(),
        onStartReview: _startTodayPlan,
        currentNotebookName: currentNotebookName,
        currentMistakeTitle: currentMistakeTitle,
        reviewStats: reviewStats,
        onOpenMistake: (mistake) async {
          final notebook = notebooks
              .where((n) => n.id == mistake.notebookId)
              .cast<Notebook?>()
              .firstWhere((n) => n != null, orElse: () => null);
          final bookId = notebook?.id ?? 'all';
          final bookName = notebook?.id == AppConfig.defaultNotebookId
              ? '全部错题'
              : (notebook?.name ?? '全部错题');
          final navigator = Navigator.of(context);
          await _saveStudyState(
            notebookId: bookId,
            notebookName: bookName,
            mistakeTitle: mistake.title,
          );
          if (!mounted) return;
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => NotebookReviewDetailPage(
                services: widget.services,
                notebook: notebook,
                onChanged: _refresh,
                initialMistakeId: mistake.id,
                onStudyStateChanged: (b, t) {
                  _saveStudyState(
                    notebookId: bookId,
                    notebookName: b,
                    mistakeTitle: t,
                  );
                },
              ),
            ),
          );
          await _refresh();
        },
        onOpenMetric: (key) async {
          String? filterMode;
          Notebook? targetNotebook;
          final targetNotebookId = currentNotebookId;

          if (key == 'pending') filterMode = 'pending';
          if (key == 'reviewing') filterMode = 'reviewing';
          if (key == 'mastered') filterMode = 'mastered';
          if (currentNotebookId != 'all') {
            targetNotebook = notebooks
                .where((n) => n.id == currentNotebookId)
                .cast<Notebook?>()
                .firstWhere((n) => n != null, orElse: () => null);
          }

          final navigator = Navigator.of(context);
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => NotebookReviewDetailPage(
                services: widget.services,
                notebook: targetNotebook,
                onChanged: _refresh,
                filterMode: filterMode,
                onStudyStateChanged: (b, t) {
                  _saveStudyState(
                    notebookId: targetNotebookId,
                    notebookName: b,
                    mistakeTitle: t,
                  );
                },
              ),
            ),
          );
          await _refresh();
        },
      ),
      ReviewPage(
        services: widget.services,
        onChanged: _refresh,
        onStudyStateChanged: (b, t) {
          final found = notebooks
              .where(
                (e) =>
                    e.name == b ||
                    (e.id == AppConfig.defaultNotebookId && b == '全部错题'),
              )
              .cast<Notebook?>()
              .firstWhere((e) => e != null, orElse: () => null);
          _saveStudyState(
            notebookId: found?.id ?? 'all',
            notebookName: b,
            mistakeTitle: t,
          );
        },
      ),
      SettingsPage(
        services: widget.services,
        stats: stats,
        onChanged: () async {
          await _refresh();
          _toast('数据已更新');
        },
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(tab),
          child: pages[tab],
        ),
      ),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              onPressed: _createNotebookFromHome,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('添加错题本'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            label: '复习',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
