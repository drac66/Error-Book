import 'dart:io';

import 'package:flutter/material.dart';

import '../models/mistake.dart';
import '../models/notebook.dart';
import '../services/app_services.dart';

class MistakeFormPage extends StatefulWidget {
  final AppServices services;
  final List<Notebook> notebooks;
  final Mistake? existing;

  const MistakeFormPage({
    super.key,
    required this.services,
    required this.notebooks,
    this.existing,
  });

  @override
  State<MistakeFormPage> createState() => _MistakeFormPageState();
}

class _MistakeFormPageState extends State<MistakeFormPage> {
  late final TextEditingController question;
  late final TextEditingController wrongAnswer;
  late final TextEditingController correctAnswer;
  late final TextEditingController reason;
  late final TextEditingController tags;
  late String notebookId;
  late MasteryStatus status;
  late int difficultyLevel;
  late int importanceLevel;
  String questionImagePath = '';
  String wrongAnswerImagePath = '';
  String correctAnswerImagePath = '';
  bool saving = false;
  final Set<String> recognizing = {};
  List<Notebook> notebooks = [];

  bool get editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    question = TextEditingController(text: m?.question ?? '');
    wrongAnswer = TextEditingController(text: m?.wrongAnswer ?? '');
    correctAnswer = TextEditingController(text: m?.correctAnswer ?? '');
    reason = TextEditingController(text: m?.reason ?? '');
    tags = TextEditingController(text: m?.tags.join(', ') ?? '');
    notebooks = [...widget.notebooks];
    notebookId = m?.notebookId ?? (notebooks.isEmpty ? 'default' : notebooks.first.id);
    status = m?.masteryStatus ?? MasteryStatus.fresh;
    difficultyLevel = m?.difficultyLevel ?? 3;
    importanceLevel = m?.importanceLevel ?? 3;
    questionImagePath = m?.questionImagePath ?? '';
    wrongAnswerImagePath = m?.wrongAnswerImagePath ?? '';
    correctAnswerImagePath = m?.correctAnswerImagePath ?? '';
  }

  @override
  void dispose() {
    question.dispose();
    wrongAnswer.dispose();
    correctAnswer.dispose();
    reason.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> _pick(String target, bool fromCamera) async {
    final picked = await widget.services.imagePicker.pickImage(
      fromCamera: fromCamera,
    );
    if (picked == null) return;
    final savedPath =
        await widget.services.imageStorage.saveToPrivateStorage(picked);
    if (!mounted) return;
    setState(() => _setImage(target, savedPath));
  }

  Future<void> _recognize(String target) async {
    final path = _imagePath(target);
    if (path.isEmpty) {
      _toast('请先添加图片');
      return;
    }
    setState(() => recognizing.add(target));
    try {
      final text = await widget.services.ocr.recognizeText(path);
      if (text.isEmpty) {
        _toast('没有识别到文字');
        return;
      }
      final ctrl = _controller(target);
      ctrl.text = ctrl.text.trim().isEmpty ? text : '${ctrl.text.trim()}\n$text';
    } catch (_) {
      _toast('OCR 识别失败，请换一张更清晰的图片');
    } finally {
      if (mounted) setState(() => recognizing.remove(target));
    }
  }

  Future<void> _createNotebook() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建错题本'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例如：数学、物理、英语',
          ),
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

    final book = await widget.services.notebooks.create(name);
    if (!mounted) return;
    setState(() {
      final exists = notebooks.any((e) => e.id == book.id);
      if (!exists) notebooks.add(book);
      notebookId = book.id;
    });
    _toast('已创建错题本：${book.name}');
  }

  Future<void> _save() async {
    if (question.text.trim().isEmpty && questionImagePath.isEmpty) {
      _toast('请填写题干或添加题干图片');
      return;
    }
    setState(() => saving = true);
    try {
      final tagList = tags.text
          .split(RegExp(r'[,，\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final base = widget.existing;
      final selectedNotebook = notebooks.firstWhere(
        (b) => b.id == notebookId,
        orElse: () => notebooks.isEmpty ? Notebook.defaultNotebook() : notebooks.first,
      );
      final next = (base ?? Mistake.create()).copyWith(
        notebookId: notebookId,
        question: question.text.trim(),
        wrongAnswer: wrongAnswer.text.trim(),
        correctAnswer: correctAnswer.text.trim(),
        reason: reason.text.trim(),
        category: selectedNotebook.name,
        tags: tagList,
        questionImagePath: questionImagePath,
        wrongAnswerImagePath: wrongAnswerImagePath,
        correctAnswerImagePath: correctAnswerImagePath,
        masteryStatus: status,
        difficultyLevel: difficultyLevel,
        importanceLevel: importanceLevel,
        updatedAt: DateTime.now(),
      );
      await widget.services.mistakes.upsert(next);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? '编辑错题' : '添加错题')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _sectionTitle('题干'),
          _imageBlock('题干图片', 'question', questionImagePath),
          _field('题干文字', question, maxLines: 4),
          _sectionTitle('我的错误'),
          _imageBlock('错误答案图片', 'wrong', wrongAnswerImagePath),
          _field('我的错误答案', wrongAnswer, maxLines: 3),
          _sectionTitle('正确答案'),
          _imageBlock('正确答案图片', 'correct', correctAnswerImagePath),
          _field('正确答案', correctAnswer, maxLines: 3),
          _sectionTitle('解析与归类'),
          _field('解析 / 错因', reason, maxLines: 4),
          _field('标签，用逗号分隔', tags),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: notebookId,
                  decoration: const InputDecoration(labelText: '选择错题本'),
                  items: notebooks
                      .map(
                        (book) => DropdownMenuItem(
                          value: book.id,
                          child: Text(book.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => notebookId = value ?? notebookId),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _createNotebook,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('新建'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MasteryStatus>(
            initialValue: status,
            decoration: const InputDecoration(labelText: '掌握状态'),
            items: MasteryStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (value) => setState(() => status = value ?? status),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: difficultyLevel,
                  decoration: const InputDecoration(labelText: '难度'),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_difficultyLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) => setState(
                    () => difficultyLevel = value ?? difficultyLevel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: importanceLevel,
                  decoration: const InputDecoration(labelText: '重要性'),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_importanceLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) => setState(
                    () => importanceLevel = value ?? importanceLevel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? '保存中' : '保存错题'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _imageBlock(String label, String target, String path) {
    final busy = recognizing.contains(target);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (path.isEmpty)
              Container(
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('未添加图片'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 80,
                    child: Center(child: Text('图片不可用')),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPickSheet(target),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('图片'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _recognize(target),
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.document_scanner_outlined),
                    label: Text(busy ? '识别中' : 'OCR'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '移除图片',
                  onPressed: () => setState(() => _setImage(target, '')),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPickSheet(String target) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pick(target, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pick(target, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  TextEditingController _controller(String target) {
    if (target == 'question') return question;
    if (target == 'wrong') return wrongAnswer;
    return correctAnswer;
  }

  String _imagePath(String target) {
    if (target == 'question') return questionImagePath;
    if (target == 'wrong') return wrongAnswerImagePath;
    return correctAnswerImagePath;
  }

  void _setImage(String target, String path) {
    if (target == 'question') questionImagePath = path;
    if (target == 'wrong') wrongAnswerImagePath = path;
    if (target == 'correct') correctAnswerImagePath = path;
  }

  String _difficultyLabel(int level) {
    switch (level) {
      case 1:
        return '1 级 · 很简单';
      case 2:
        return '2 级 · 偏简单';
      case 3:
        return '3 级 · 中等';
      case 4:
        return '4 级 · 偏难';
      default:
        return '5 级 · 很难';
    }
  }

  String _importanceLabel(int level) {
    switch (level) {
      case 1:
        return '1 级 · 一般';
      case 2:
        return '2 级 · 稍重要';
      case 3:
        return '3 级 · 重要';
      case 4:
        return '4 级 · 很重要';
      default:
        return '5 级 · 核心必会';
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
