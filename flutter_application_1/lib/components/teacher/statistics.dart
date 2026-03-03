import 'package:flutter/material.dart';
import '../../types/index.dart';
import '../../utils/storage.dart';
import '../../l10n/app_text.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  List<Exam> _exams = [];
  Exam? _selectedExam;
  List<ExamSubmission> _submissions = [];
  List<User> _users = [];
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await getCurrentUser();
    final allExams = await getExams();
    final allSubmissions = await getSubmissions();
    final allUsers = await getUsers();
    final allQuestions = await getQuestions();

    if (mounted) {
      setState(() {
        if (user != null) {
          _exams = allExams.where((e) => e.teacherId == user.id).toList();
          if (_exams.isNotEmpty) _selectedExam = _exams.first;
        }
        _submissions = allSubmissions;
        _users = allUsers;
        _questions = allQuestions;
        _isLoading = false;
      });
    }
  }

  List<ExamSubmission> get _examSubmissions {
    if (_selectedExam == null) return [];
    return _submissions.where((s) => s.examId == _selectedExam!.id).toList();
  }

  Map<String, double> get _stats {
    if (_examSubmissions.isEmpty) return {'average': 0, 'passRate': 0};
    final total = _examSubmissions.fold(0.0, (sum, s) => sum + s.score);
    final passed = _examSubmissions.where((s) => s.score >= 5).length;
    return {
      'average': total / _examSubmissions.length,
      'passRate': (passed / _examSubmissions.length) * 100,
    };
  }

  List<Map<String, dynamic>> get _scoreDistribution {
    final ranges = [
      {'name': '0-2', 'min': 0, 'max': 2, 'count': 0},
      {'name': '2-4', 'min': 2, 'max': 4, 'count': 0},
      {'name': '4-6', 'min': 4, 'max': 6, 'count': 0},
      {'name': '6-8', 'min': 6, 'max': 8, 'count': 0},
      {'name': '8-10', 'min': 8, 'max': 10, 'count': 0},
    ];

    for (final sub in _examSubmissions) {
      for (final range in ranges) {
        final score = sub.score.toDouble();
        final min = range['min'] as int;
        final max = range['max'] as int;
        final isLastRange = max == 10;
        if (score >= min && (isLastRange ? score <= max : score < max)) {
          range['count'] = (range['count'] as int) + 1;
          break;
        }
      }
    }
    return ranges;
  }

  void _showSubmissionDetail(ExamSubmission submission) {
    final studentName = _users
        .firstWhere(
          (u) => u.id == submission.studentId,
          orElse: () => const User(id: '', username: '', password: '', email: '', fullName: 'Unknown', role: '', createdAt: ''),
        )
        .fullName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.t('detail')} - $studentName'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: ListView.builder(
            itemCount: _selectedExam!.questionIds.length,
            itemBuilder: (context, index) {
              final qId = _selectedExam!.questionIds[index];
              final question = _questions.firstWhere(
                (q) => q.id == qId,
                orElse: () => Question(
                  id: '',
                  content: context.t('question_deleted'),
                  options: [],
                  correctAnswer: -1,
                  teacherId: '',
                  createdAt: '',
                ),
              );

              final studentAns = submission.answers[qId];
              final isCorrect = studentAns == question.correctAnswer;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green[50] : Colors.red[50],
                  border: Border.all(color: isCorrect ? Colors.green[200]! : Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.t('question_n', args: {'index': '${index + 1}'})}: ${question.content}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (question.options.isNotEmpty)
                      ...List.generate(question.options.length, (optIdx) {
                        final isKey = optIdx == question.correctAnswer;
                        final isChosen = optIdx == studentAns;

                        String suffix = '';
                        if (isKey) suffix = ' +';
                        if (isChosen && !isKey) suffix = ' - ${context.t('you_chose')}';

                        return Text(
                          '${String.fromCharCode(65 + optIdx)}. ${question.options[optIdx]} $suffix',
                          style: TextStyle(
                            color: isKey ? Colors.green[800] : (isChosen ? Colors.red[800] : Colors.black),
                            fontWeight: (isKey || isChosen) ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('close')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_exams.isEmpty) return Center(child: Text(context.t('no_exam_for_statistics')));

    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('statistics_report'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedExam?.id,
                  isExpanded: true,
                  items: _exams.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedExam = _exams.firstWhere((e) => e.id == val);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  _StatCard(title: context.t('submission_count'), value: '${_examSubmissions.length}', color: Colors.blue),
                  _StatCard(title: context.t('average_score'), value: _stats['average']!.toStringAsFixed(2), color: Colors.green),
                  _StatCard(title: context.t('pass_rate'), value: '${_stats['passRate']!.toStringAsFixed(1)}%', color: Colors.purple),
                ];

                if (isSmallScreen) {
                  return Column(
                    children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList(),
                  );
                }

                return Row(
                  children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: c))).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(context.t('score_distribution'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 32),
            Flex(
              direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isSmallScreen ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
              children: [
                Text(context.t('score_list'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (isSmallScreen) const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('excel_not_supported'))));
                  },
                  icon: const Icon(Icons.download),
                  label: Text(context.t('export_excel')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('STT')),
                      DataColumn(label: Text(context.t('full_name'))),
                      DataColumn(label: Text(context.t('score_label'))),
                      DataColumn(label: Text(context.t('submit_time'))),
                      DataColumn(label: Text(context.t('action'))),
                    ],
                    rows: List.generate(_examSubmissions.length, (index) {
                      final sub = _examSubmissions[index];
                      final student = _users.firstWhere(
                        (u) => u.id == sub.studentId,
                        orElse: () => const User(id: '', username: '', password: '', email: '', fullName: 'Unknown', role: '', createdAt: ''),
                      );

                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(student.fullName)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: sub.score >= 5 ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sub.score.toStringAsFixed(1),
                              style: TextStyle(fontWeight: FontWeight.bold, color: sub.score >= 5 ? Colors.green[800] : Colors.red[800]),
                            ),
                          ),
                        ),
                        DataCell(Text(DateTime.parse(sub.submittedAt).toString().substring(0, 16))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                            tooltip: context.t('detail'),
                            onPressed: () => _showSubmissionDetail(sub),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final dataList = _scoreDistribution;
    final maxCount = _examSubmissions.isEmpty ? 1 : _examSubmissions.length;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dataList.map((data) {
          final count = (data['count'] as int).toDouble();
          final percentage = maxCount > 0 ? count / maxCount : 0.0;
          final height = percentage * 100.0;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${count.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: height <= 0 ? 1 : height,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(data['name'], style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
