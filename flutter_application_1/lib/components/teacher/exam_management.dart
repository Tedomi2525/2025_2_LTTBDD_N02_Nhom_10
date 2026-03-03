import 'dart:math';
import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class ExamManagement extends StatefulWidget {
  const ExamManagement({super.key});

  @override
  State<ExamManagement> createState() => _ExamManagementState();
}

class _ExamManagementState extends State<ExamManagement> {
  List<Exam> _exams = [];
  List<Class> _classes = [];
  List<Question> _questions = [];
  User? _currentUser;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _passwordController = TextEditingController();
  String _selectedClassId = '';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _allowViewAnswers = true;
  List<String> _selectedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    final allExams = await getExams();
    final allClasses = await getClasses();
    final allQuestions = await getQuestions();

    if (mounted) {
      setState(() {
        _currentUser = user;
        if (user != null) {
          _exams = allExams.where((e) => e.teacherId == user.id).toList();
          _classes = allClasses.where((c) => c.teacherId == user.id).toList();
          _questions = allQuestions.where((q) => q.teacherId == user.id).toList();
          if (_classes.isNotEmpty) _selectedClassId = _classes.first.id;
        }
      });
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;

    if (!context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _handleOpenDialog({Exam? exam}) {
    if (exam != null) {
      _nameController.text = exam.name;
      _selectedClassId = exam.classId;
      _durationController.text = exam.duration.toString();
      _startTime = DateTime.parse(exam.startTime);
      _endTime = DateTime.parse(exam.endTime);
      _passwordController.text = exam.password ?? '';
      _allowViewAnswers = exam.allowViewAnswers;
      _selectedQuestionIds = List.from(exam.questionIds);
    } else {
      _nameController.clear();
      if (_classes.isNotEmpty) _selectedClassId = _classes.first.id;
      _durationController.text = '60';
      _startTime = null;
      _endTime = null;
      _passwordController.clear();
      _allowViewAnswers = true;
      _selectedQuestionIds = [];
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(exam != null ? context.t('edit_exam') : context.t('create_new_exam')),
            content: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(labelText: context.t('exam_name'), border: const OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? context.t('enter_exam_name') : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: context.t('class_label'),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedClassId,
                                  isExpanded: true,
                                  items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => _selectedClassId = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: context.t('duration_minutes'), border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await _pickDateTime(context, _startTime);
                                if (picked != null) setDialogState(() => _startTime = picked);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: context.t('start_time'), border: const OutlineInputBorder()),
                                child: Text(_startTime != null ? _startTime.toString().substring(0, 16) : context.t('choose_datetime')),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await _pickDateTime(context, _endTime);
                                if (picked != null) setDialogState(() => _endTime = picked);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: context.t('end_time'), border: const OutlineInputBorder()),
                                child: Text(_endTime != null ? _endTime.toString().substring(0, 16) : context.t('choose_datetime')),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(labelText: context.t('password_optional'), border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CheckboxListTile(
                              title: Text(context.t('allow_view_answers')),
                              value: _allowViewAnswers,
                              onChanged: (val) => setDialogState(() => _allowViewAnswers = val!),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.t('selected_questions', args: {'value': _selectedQuestionIds.length.toString()}),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              final random = Random();
                              final countController = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(context.t('random_select')),
                                  content: TextField(
                                    controller: countController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: context.t('quantity')),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        final count = int.tryParse(countController.text) ?? 0;
                                        if (count > 0 && count <= _questions.length) {
                                          final shuffled = List<Question>.from(_questions)..shuffle(random);
                                          setDialogState(() {
                                            _selectedQuestionIds = shuffled.take(count).map((q) => q.id).toList();
                                          });
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: Text(context.t('choose')),
                                    )
                                  ],
                                ),
                              );
                            },
                            child: Text(context.t('random_select')),
                          )
                        ],
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: ListView.builder(
                          itemCount: _questions.length,
                          itemBuilder: (ctx, idx) {
                            final q = _questions[idx];
                            final isSelected = _selectedQuestionIds.contains(q.id);
                            return CheckboxListTile(
                              title: Text(
                                '${context.t('question_n', args: {'index': '${idx + 1}'})}: ${q.content}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    _selectedQuestionIds.add(q.id);
                                  } else {
                                    _selectedQuestionIds.remove(q.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
              ElevatedButton(
                onPressed: _selectedQuestionIds.isEmpty
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate() && _startTime != null && _endTime != null) {
                          await _handleSubmit(exam);
                          // ignore: use_build_context_synchronously
                          if (mounted) Navigator.pop(context);
                        }
                      },
                child: Text(exam != null ? context.t('update') : context.t('create_new_exam')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit(Exam? editingExam) async {
    final examData = {
      'name': _nameController.text,
      'classId': _selectedClassId,
      'duration': int.parse(_durationController.text),
      'startTime': _startTime!.toIso8601String(),
      'endTime': _endTime!.toIso8601String(),
      'password': _passwordController.text.isEmpty ? null : _passwordController.text,
      'allowViewAnswers': _allowViewAnswers,
      'questionIds': _selectedQuestionIds,
    };

    if (editingExam != null) {
      await updateExam(editingExam.id, examData);
    } else {
      final newExam = Exam(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: examData['name'] as String,
        teacherId: _currentUser!.id,
        classId: examData['classId'] as String,
        questionIds: examData['questionIds'] as List<String>,
        duration: examData['duration'] as int,
        startTime: examData['startTime'] as String,
        endTime: examData['endTime'] as String,
        status: 'draft',
        allowViewAnswers: examData['allowViewAnswers'] as bool,
        password: examData['password'] as String?,
        createdAt: DateTime.now().toIso8601String(),
      );
      await addExam(newExam);
    }
    await _loadData();
  }

  Future<void> _toggleStatus(Exam exam) async {
    final newStatus = exam.status == 'active' ? 'closed' : 'active';
    await updateExam(exam.id, {'status': newStatus});
    await _loadData();
  }

  Future<void> _deleteExam(String id) async {
    await deleteExam(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('manage_exams'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleOpenDialog(),
              icon: const Icon(Icons.add),
              label: Text(context.t('create_new_exam')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500.0,
                childAspectRatio: 1.6,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: _exams.length,
              itemBuilder: (context, index) {
                final exam = _exams[index];
                final clsName = _classes
                    .firstWhere(
                      (c) => c.id == exam.classId,
                      orElse: () => const Class(id: '', name: 'Unknown', teacherId: '', studentIds: [], createdAt: ''),
                    )
                    .name;

                Color statusColor;
                String statusLabel;
                switch (exam.status) {
                  case 'active':
                    statusColor = Colors.green;
                    statusLabel = context.t('status_active');
                    break;
                  case 'closed':
                    statusColor = Colors.red;
                    statusLabel = context.t('status_closed');
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusLabel = context.t('status_draft');
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(exam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(context.t('class_with_name', args: {'value': clsName})),
                        Text(
                          context.t('questions_duration', args: {
                            'questions': exam.questionIds.length.toString(),
                            'duration': exam.duration.toString(),
                          }),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _toggleStatus(exam),
                              icon: Icon(exam.status == 'active' ? Icons.stop : Icons.play_arrow, size: 16),
                              label: Text(exam.status == 'active' ? context.t('end') : context.t('activate')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: exam.status == 'active' ? Colors.red[50] : Colors.green[50],
                                foregroundColor: exam.status == 'active' ? Colors.red : Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _handleOpenDialog(exam: exam)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExam(exam.id)),
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
  }
}
