import 'package:flutter/material.dart';

import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';

class LibraryPage extends StatefulWidget {
  final AppServices services;
  final List<Notebook> notebooks;
  final ValueChanged<Mistake> onEdit;
  final Future<void> Function() onChanged;

  const LibraryPage({
    super.key,
    required this.services,
    required this.notebooks,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String keyword = '';
  String notebookId = 'all';
  MasteryStatus? status;
  bool loading = true;
  List<Mistake> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final next = await widget.services.mistakes.list(
      keyword: keyword,
      notebookId: notebookId,
      status: status,
    );
    if (!mounted) return;
    setState(() {
      items = next;
      loading = false;
    });
  }

  Future<void> _delete(Mistake mistake) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除错题'),
        content: const Text('删除后不会进入回收站，确认删除吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.services.mistakes.delete(mistake.id);
    await _load();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题库')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索题干、答案、解析、分类或标签',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                keyword = value.trim();
                _load();
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ChoiceChip(
                  label: const Text('全部错题本'),
                  selected: notebookId == 'all',
                  onSelected: (_) {
                    setState(() => notebookId = 'all');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                ...widget.notebooks.map((book) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(book.name),
                        selected: notebookId == book.id,
                        onSelected: (_) {
                          setState(() => notebookId = book.id);
                          _load();
                        },
                      ),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statusChip('全部状态', null),
                const SizedBox(width: 8),
                ...MasteryStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _statusChip(s.label, s),
                    )),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 220),
                              Center(child: Text('没有符合条件的错题')),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 92),
                            itemBuilder: (_, i) => _MistakeCard(
                              mistake: items[i],
                              onTap: () => widget.onEdit(items[i]),
                              onDelete: () => _delete(items[i]),
                            ),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemCount: items.length,
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, MasteryStatus? value) {
    return ChoiceChip(
      label: Text(label),
      selected: status == value,
      onSelected: (_) {
        setState(() => status = value);
        _load();
      },
    );
  }
}

class _MistakeCard extends StatelessWidget {
  final Mistake mistake;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MistakeCard({
    required this.mistake,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(mistake.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: '删除',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Pill(text: mistake.category, icon: Icons.folder_outlined),
                  _Pill(
                      text: mistake.masteryStatus.label,
                      icon: Icons.flag_outlined),
                  if (mistake.hasImage)
                    const _Pill(text: '含图片', icon: Icons.image_outlined),
                  ...mistake.tags
                      .take(3)
                      .map((tag) => _Pill(text: tag, icon: Icons.tag)),
                ],
              ),
              const SizedBox(height: 8),
              Text('更新：${_date(mistake.updatedAt)}',
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
