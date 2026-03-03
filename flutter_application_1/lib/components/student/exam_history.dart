import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class ExamHistory extends StatefulWidget {
  const ExamHistory({super.key});

  @override
  State<ExamHistory> createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamHistory> {
  List<ExamSubmission> _submissions = [];
  List<Exam> _exams = [];
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final allSubmissions = await getSubmissions();
    final studentSubmissions = allSubmissions.where((s) => s.studentId == user.id).toList();
    final allExams = await getExams();
    final allQuestions = await getQuestions();

    if (mounted) {
      setState(() {
        _submissions = studentSubmissions;
        _exams = allExams;
        _questions = allQuestions;
        _isLoading = false;
      });
    }
  }

  Exam? _getExam(String examId) {
    try {
      return _exams.firstWhere((e) => e.id == examId);
    } catch (_) {
      return null;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.blue;
    return Colors.red;
  }

  void _handleViewDetail(ExamSubmission submission) {
    final exam = _getExam(submission.examId);
    if (exam == null) return;

    if (!exam.allowViewAnswers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('teacher_disallow_answers'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _DetailDialog(
        submission: submission,
        exam: exam,
        questions: _questions.where((q) => exam.questionIds.contains(q.id)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('exam_history'),
              style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
            ),
            Text(context.t('review_completed_exams'), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24.0),
            if (_submissions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(context.t('no_completed_exams'), style: const TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final submission = _submissions[index];
                  final exam = _getExam(submission.examId);
                  final examName = exam?.name ?? context.t('unknown');
                  final scoreColor = _getScoreColor(submission.score.toDouble());

                  return Card(
                    elevation: 2.0,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(examName, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8.0),
                                Wrap(
                                  spacing: 16.0,
                                  runSpacing: 8.0,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 16.0, color: Colors.grey),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          context.t('submitted_at', args: {
                                            'value': DateTime.parse(submission.submittedAt).toLocal().toString().substring(0, 16),
                                          }),
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.emoji_events, size: 16.0, color: Colors.grey),
                                        const SizedBox(width: 4.0),
                                        Text('${context.t('score_label')} ', style: const TextStyle(color: Colors.grey)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                          decoration: BoxDecoration(
                                            color: scoreColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          child: Text(
                                            '${submission.score.toStringAsFixed(1)}/10',
                                            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (exam?.allowViewAnswers == true)
                            IconButton(
                              onPressed: () => _handleViewDetail(submission),
                              icon: const Icon(Icons.visibility),
                              tooltip: context.t('view_detail'),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                                foregroundColor: Colors.indigo,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8.0)),
                              child: const Icon(Icons.lock, color: Colors.grey, size: 20),
                            ),
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

class _DetailDialog extends StatelessWidget {
  final ExamSubmission submission;
  final Exam exam;
  final List<Question> questions;

  const _DetailDialog({
    required this.submission,
    required this.exam,
    required this.questions,
  });

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.blue;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogWidth = constraints.maxWidth > 750 ? 700.0 : constraints.maxWidth * 0.95;
        final dialogHeight = constraints.maxHeight > 700 ? 600.0 : constraints.maxHeight * 0.9;

        return AlertDialog(
          title: Text(context.t('exam_detail')),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8.0)),
                  child: Column(
                    children: [
                      _buildDetailRow(context, context.t('exam_label'), exam.name),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Text('${context.t('score_label')} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _getScoreColor(submission.score.toDouble()).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              '${submission.score.toStringAsFixed(1)}/10',
                              style: TextStyle(color: _getScoreColor(submission.score.toDouble()), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      _buildDetailRow(
                        context,
                        context.t('submit_time'),
                        DateTime.parse(submission.submittedAt).toLocal().toString().substring(0, 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView.separated(
                    itemCount: questions.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 16.0),
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final studentAnswer = submission.answers[question.id];
                      final isCorrect = studentAnswer == question.correctAnswer;

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green[50] : Colors.red[50],
                          border: Border.all(color: isCorrect ? Colors.green[200]! : Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: isCorrect ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    context.t('question_n', args: {'index': '${index + 1}'}),
                                    style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  isCorrect ? context.t('correct') : context.t('wrong'),
                                  style: TextStyle(color: isCorrect ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(question.content, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8.0),
                            ...List.generate(question.options.length, (optIdx) {
                              final isKey = optIdx == question.correctAnswer;
                              final isChosen = optIdx == studentAnswer;

                              Color bgColor = Colors.white;
                              Color borderColor = Colors.grey[300]!;
                              if (isKey) {
                                bgColor = Colors.green[100]!;
                                borderColor = Colors.green;
                              } else if (isChosen && !isCorrect) {
                                bgColor = Colors.red[100]!;
                                borderColor = Colors.red;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${String.fromCharCode(65 + optIdx)}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(question.options[optIdx])),
                                    if (isKey) const Text(' +', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    if (isChosen && !isKey) const Text(' -', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('close'))),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8.0),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
