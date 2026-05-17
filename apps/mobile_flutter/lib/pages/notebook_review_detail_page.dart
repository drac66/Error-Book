import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';
import 'mistake_form_page.dart';
import 'mistake_review_page.dart';
import 'review_plan_report_page.dart';

class NotebookReviewDetailPage extends StatefulWidget {
  final AppServices services;
  final Notebook? notebook;
  final Future<void> Function() onChanged;
  final String? initialMistakeId;
  final String? filterMode;
  final void Function(String notebookName, String mistakeTitle)?
      onStudyStateChanged;

  const NotebookReviewDetailPage({
    super.key,
    required this.services,
    required this.notebook,
    required this.onChanged,
    this.initialMistakeId,
    this.filterMode,
    this.onStudyStateChanged,
  });

  @override
  State<NotebookReviewDetailPage> createState() =>
      _NotebookReviewDetailPageState();
}

class _NotebookReviewDetailPageState extends State<NotebookReviewDetailPage> {
  bool loading = true;
  bool openedInitialMistake = false;
  List<Mistake> mistakes = [];
  String keyword = '';

  String get notebookId {
    final id = widget.notebook?.id;
    if (id == null || id == AppConfig.defaultNotebookId) return 'all';
    return id;
  }
  String get _displayNotebookName =>
      (widget.notebook?.id == AppConfig.defaultNotebookId ||
              widget.notebook == null)
          ? '全部错题'
          : widget.notebook!.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    List<Mistake> list;
    if (widget.filterMode == 'pending') {
      final fresh = await widget.services.mistakes.list(
        notebookId: notebookId,
        keyword: keyword,
        status: MasteryStatus.fresh,
      );
      final reviewing = await widget.services.mistakes.list(
        notebookId: notebookId,
        keyword: keyword,
        status: MasteryStatus.reviewing,
      );
      list = [...fresh, ...reviewing]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } else {
      MasteryStatus? status;
      if (widget.filterMode == 'reviewing') status = MasteryStatus.reviewing;
      if (widget.filterMode == 'mastered') status = MasteryStatus.mastered;
      list = await widget.services.mistakes.list(
        notebookId: notebookId,
        keyword: keyword,
        status: status,
      );
    }

    if (!mounted) return;
    setState(() {
      mistakes = list;
      loading = false;
    });

    if (!openedInitialMistake && widget.initialMistakeId != null) {
      final found = list
          .where((e) => e.id == widget.initialMistakeId)
          .cast<Mistake?>()
          .firstWhere((e) => e != null, orElse: () => null);
      if (found != null && mounted) {
        openedInitialMistake = true;
        widget.onStudyStateChanged?.call(_displayNotebookName, found.title);
        await _openMistake(found);
      }
    }
  }

  Future<void> _openReport() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewPlanReportPage(
          services: widget.services,
          notebook: widget.notebook,
          onChanged: widget.onChanged,
          onStudyStateChanged: widget.onStudyStateChanged,
        ),
      ),
    );
    await widget.onChanged();
    await _load();
  }

  Future<void> _openMistake(Mistake e) async {
    widget.onStudyStateChanged?.call(_displayNotebookName, e.title);
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MistakeReviewPage(
          services: widget.services,
          mistake: e,
          onChanged: widget.onChanged,
          planNotebookId: notebookId,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  Future<void> _addMistake() async {
    final books = await widget.services.notebooks.list();
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MistakeFormPage(
          services: widget.services,
          notebooks: books,
        ),
      ),
    );
    if (changed == true) {
      await widget.onChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleBase = widget.notebook?.id == AppConfig.defaultNotebookId
        ? '全部错题'
        : (widget.notebook?.name ?? '全部错题');
    final title = switch (widget.filterMode) {
      'pending' => '$titleBase · 待复习',
      'reviewing' => '$titleBase · 复习中',
      'mastered' => '$titleBase · 已掌握',
      _ => titleBase,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMistake,
        icon: const Icon(Icons.add),
        label: const Text('添加错题'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF3),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFDCC9A2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleBase,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '这里更适合看题库与计划。你可以先打开复习计划报告，再决定是否开始今天的任务。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6A7280),
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.manage_search),
                    hintText: '在当前错题本中搜索错题',
                  ),
                  onChanged: (v) async {
                    keyword = v.trim();
                    await _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openReport,
                  icon: const Icon(Icons.insert_chart_outlined),
                  label: const Text('复习计划'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const SizedBox(
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (mistakes.isEmpty)
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF3),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFDCC9A2)),
              ),
              child: const Text('当前范围内没有符合条件的错题'),
            )
          else ...[
            Row(
              children: [
                Text(
                  '本册错题 (${mistakes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Text(
                  '按更新时间排序',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6A7280),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...mistakes.take(50).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${e.category} · ${e.masteryStatus.label} · 更新 ${_fmt(e.updatedAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openMistake(e),
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
