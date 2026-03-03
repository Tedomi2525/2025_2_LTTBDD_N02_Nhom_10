import 'dart:async';
import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class TakeExam extends StatefulWidget {
  final Exam exam;
  final VoidCallback onComplete;

  const TakeExam({super.key, required this.exam, required this.onComplete});

  @override
  State<TakeExam> createState() => _TakeExamState();
}

class _TakeExamState extends State<TakeExam> {
  List<Question> _questions = [];
  final Map<String, int> _answers = {};
  late int _timeRemaining;
  Timer? _timer;
  User? _currentUser;
  final Map<String, GlobalKey> _questionKeys = {};

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.exam.duration * 60;
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final user = await getCurrentUser();
    final allQuestions = await getQuestions();
    final examQuestions = allQuestions.where((q) => widget.exam.questionIds.contains(q.id)).toList();

    for (final q in examQuestions) {
      _questionKeys[q.id] = GlobalKey();
    }

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _questions = examQuestions;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining <= 1) {
        timer.cancel();
        _submitExam();
      } else {
        setState(() {
          _timeRemaining--;
        });
      }
    });
  }

  Future<void> _submitExam() async {
    _timer?.cancel();

    int correct = 0;
    for (final question in _questions) {
      if (_answers[question.id] == question.correctAnswer) {
        correct++;
      }
    }

    final double score = _questions.isEmpty ? 0 : (correct / _questions.length) * 10;
    if (_currentUser == null) return;

    final submission = ExamSubmission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      examId: widget.exam.id,
      studentId: _currentUser!.id,
      answers: _answers,
      score: score.toInt(),
      submittedAt: DateTime.now().toIso8601String(),
    );

    await addSubmission(submission);
    widget.onComplete();
  }

  void _handleConfirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(context.t('submit_confirm')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('answered_count', args: {
              'answered': _answers.length.toString(),
              'total': _questions.length.toString(),
            })),
            if (_answers.length < _questions.length)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  context.t('remaining_questions', args: {
                    'value': (_questions.length - _answers.length).toString(),
                  }),
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 12),
            Text(context.t('confirm_submit')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('continue_work')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: Text(context.t('submit_exam')),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final int mins = totalSeconds ~/ 60;
    final int secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _scrollToQuestion(String questionId) {
    final key = _questionKeys[questionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrowScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: isNarrowScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.exam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        context.t('answered_status', args: {
                          'answered': _answers.length.toString(),
                          'total': _questions.length.toString(),
                        }),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _timeRemaining < 300 ? Colors.red[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 20, color: _timeRemaining < 300 ? Colors.red : Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_timeRemaining),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _timeRemaining < 300 ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _handleConfirmSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: Text(context.t('submit_exam')),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.exam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            context.t('answered_status', args: {
                              'answered': _answers.length.toString(),
                              'total': _questions.length.toString(),
                            }),
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _timeRemaining < 300 ? Colors.red[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: _timeRemaining < 300 ? Colors.red : Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(_timeRemaining),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _timeRemaining < 300 ? Colors.red : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _handleConfirmSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: Text(context.t('submit_exam')),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_timeRemaining < 300)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red[800]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.t('time_warning'),
                                    style: TextStyle(color: Colors.red[800]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...List.generate(_questions.length, (index) {
                          final question = _questions[index];
                          return Card(
                            key: _questionKeys[question.id],
                            margin: const EdgeInsets.only(bottom: 24),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(16)),
                                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(question.content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                  if (question.imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Image.network(question.imageUrl!, height: 200, fit: BoxFit.contain),
                                    ),
                                  const SizedBox(height: 16),
                                  ...List.generate(question.options.length, (optIndex) {
                                    final isSelected = _answers[question.id] == optIndex;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _answers[question.id] = optIndex;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.indigo[50] : Colors.white,
                                          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: isSelected ? Colors.indigo : Colors.grey),
                                                color: isSelected ? Colors.indigo : Colors.transparent,
                                              ),
                                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Text('${String.fromCharCode(65 + optIndex)}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(question.options[optIndex])),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (MediaQuery.of(context).size.width > 800)
                  Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('question_nav'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              final isAnswered = _answers.containsKey(q.id);
                              return InkWell(
                                onTap: () => _scrollToQuestion(q.id),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isAnswered ? Colors.green : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isAnswered ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
