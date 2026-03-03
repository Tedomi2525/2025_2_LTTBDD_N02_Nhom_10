import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class ExamList extends StatefulWidget {
  final Function(Exam) onStartExam;

  const ExamList({super.key, required this.onStartExam});

  @override
  State<ExamList> createState() => _ExamListState();
}

class _ExamListState extends State<ExamList> {
  List<Exam> _availableExams = [];
  List<ExamSubmission> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final allClasses = await getClasses();
    final studentClasses = allClasses.where((c) => c.studentIds.contains(user.id)).toList();
    final classIds = studentClasses.map((c) => c.id).toList();

    final allExams = await getExams();
    final studentExams = allExams.where((e) => classIds.contains(e.classId) && e.status == 'active').toList();

    final allSubmissions = await getSubmissions();
    final userSubmissions = allSubmissions.where((s) => s.studentId == user.id).toList();

    if (mounted) {
      setState(() {
        _availableExams = studentExams;
        _submissions = userSubmissions;
        _isLoading = false;
      });
    }
  }

  bool _hasSubmitted(String examId) {
    return _submissions.any((s) => s.examId == examId);
  }

  ExamSubmission? _getSubmission(String examId) {
    try {
      return _submissions.firstWhere((s) => s.examId == examId);
    } catch (_) {
      return null;
    }
  }

  bool _isExamAvailable(Exam exam) {
    final now = DateTime.now();
    final start = DateTime.parse(exam.startTime);
    final end = DateTime.parse(exam.endTime);
    return now.isAfter(start) && now.isBefore(end);
  }

  void _handleStartExam(Exam exam) {
    if (exam.password != null && exam.password!.isNotEmpty) {
      final passwordController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('enter_exam_password')),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.t('exam_password'),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == exam.password) {
                  Navigator.pop(context);
                  widget.onStartExam(exam);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('wrong_exam_password'))),
                  );
                }
              },
              child: Text(context.t('enter_exam')),
            ),
          ],
        ),
      );
    } else {
      widget.onStartExam(exam);
    }
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
              context.t('exam_list'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(context.t('available_exams_for_you'), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            if (_availableExams.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(context.t('no_exams_now'), style: const TextStyle(color: Colors.grey)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _availableExams.length,
                itemBuilder: (context, index) {
                  final exam = _availableExams[index];
                  final submitted = _hasSubmitted(exam.id);
                  final submission = _getSubmission(exam.id);
                  final available = _isExamAvailable(exam);

                  return Opacity(
                    opacity: !available ? 0.6 : 1.0,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    exam.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (submitted)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.access_time,
                              context.t('minutes', args: {'value': exam.duration.toString()}),
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.description,
                              context.t('questions_count', args: {'value': exam.questionIds.length.toString()}),
                            ),
                            if (exam.password != null && exam.password!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: _buildInfoRow(Icons.lock, context.t('has_password'), color: Colors.orange),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t('open_time', args: {
                                      'value': DateTime.parse(exam.startTime).toLocal().toString().substring(0, 16),
                                    }),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    context.t('close_time', args: {
                                      'value': DateTime.parse(exam.endTime).toLocal().toString().substring(0, 16),
                                    }),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (submitted && submission != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  border: Border.all(color: Colors.green[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.t('score', args: {'value': submission.score.toStringAsFixed(1)}),
                                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      context.t('submitted_at', args: {
                                        'value': DateTime.parse(submission.submittedAt).toLocal().toString().substring(0, 16),
                                      }),
                                      style: TextStyle(color: Colors.green[800], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            if (!available && !submitted)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, size: 16, color: Colors.red[800]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        context.t('not_available'),
                                        style: TextStyle(color: Colors.red[800], fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (!available || submitted) ? null : () => _handleStartExam(exam),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  disabledForegroundColor: Colors.grey[500],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(submitted ? context.t('completed') : context.t('start_exam')),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color ?? Colors.grey[600], fontSize: 14)),
      ],
    );
  }
}
