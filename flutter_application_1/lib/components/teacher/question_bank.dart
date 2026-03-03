import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class QuestionBank extends StatefulWidget {
  const QuestionBank({super.key});

  @override
  State<QuestionBank> createState() => _QuestionBankState();
}

class _QuestionBankState extends State<QuestionBank> {
  List<Question> _questions = [];
  User? _currentUser;
  String _searchQuery = '';

  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  int _selectedCorrectAnswer = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    final allQuestions = await getQuestions();

    setState(() {
      _currentUser = user;
      if (user != null) {
        _questions = allQuestions.where((q) => q.teacherId == user.id).toList();
      }
    });
  }

  List<Question> get _filteredQuestions {
    if (_searchQuery.isEmpty) return _questions;
    return _questions.where((q) => q.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _handleOpenDialog({Question? question}) {
    if (question != null) {
      _contentController.text = question.content;
      _imageController.text = question.imageUrl ?? '';
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = question.options[i];
      }
      _selectedCorrectAnswer = question.correctAnswer;
    } else {
      _contentController.clear();
      _imageController.clear();
      for (final c in _optionControllers) {
        c.clear();
      }
      _selectedCorrectAnswer = 0;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(question != null ? context.t('edit_question') : context.t('add_new_question')),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: context.t('question_content'), border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageController,
                      decoration: InputDecoration(labelText: context.t('image_url_optional'), prefixIcon: const Icon(Icons.image)),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(context.t('answer_options'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              // ignore: deprecated_member_use
                              groupValue: _selectedCorrectAnswer,
                              // ignore: deprecated_member_use
                              onChanged: (val) {
                                setDialogState(() => _selectedCorrectAnswer = val!);
                              },
                            ),
                            Text(context.t('option_n', args: {'label': String.fromCharCode(65 + index)})),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _optionControllers[index],
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Text(context.t('mark_correct_hint'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
              ElevatedButton(
                onPressed: () async {
                  await _handleSubmit(question);
                  // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(context);
                },
                child: Text(question != null ? context.t('update') : context.t('add_question')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit(Question? editingQuestion) async {
    if (_currentUser == null) return;
    final options = _optionControllers.map((c) => c.text).toList();

    if (_contentController.text.isEmpty || options.any((o) => o.isEmpty)) {
      return;
    }

    if (editingQuestion != null) {
      await updateQuestion(editingQuestion.id, {
        'content': _contentController.text,
        'imageUrl': _imageController.text.isEmpty ? null : _imageController.text,
        'options': options,
        'correctAnswer': _selectedCorrectAnswer,
      });
    } else {
      final newQuestion = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _contentController.text,
        imageUrl: _imageController.text.isEmpty ? null : _imageController.text,
        options: options,
        correctAnswer: _selectedCorrectAnswer,
        teacherId: _currentUser!.id,
        createdAt: DateTime.now().toIso8601String(),
      );
      await addQuestion(newQuestion);
    }
    await _loadData();
  }

  Future<void> _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('confirm')),
        content: Text(context.t('delete_question_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteQuestion(id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('question_bank'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(context.t('your_question_bank'), style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSearchField(context),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _handleOpenDialog(),
                                icon: const Icon(Icons.add),
                                label: Text(context.t('add_question')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: _buildSearchField(context)),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _handleOpenDialog(),
                                icon: const Icon(Icons.add),
                                label: Text(context.t('add_question')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.menu_book, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                context.t('total_questions', args: {'value': _questions.length.toString()}),
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredQuestions.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final q = _filteredQuestions[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.indigo[100], borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      context.t('question_n', args: {'index': '${index + 1}'}),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(q.content, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                  if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Image.network(
                                        q.imageUrl!,
                                        height: 150,
                                        errorBuilder: (_, _, _) => Text(context.t('image_error')),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  ...List.generate(q.options.length, (optIdx) {
                                    final isCorrect = optIdx == q.correctAnswer;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCorrect ? Colors.green[50] : Colors.grey[50],
                                        border: Border.all(color: isCorrect ? Colors.green[200]! : Colors.transparent),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${String.fromCharCode(65 + optIdx)}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(q.options[optIdx])),
                                          if (isCorrect) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              context.t('correct_answer'),
                                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ]
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _handleOpenDialog(question: q),
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _handleDelete(q.id),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: context.t('search_questions'),
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }
}
