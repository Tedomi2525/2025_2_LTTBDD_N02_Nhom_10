import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'components/login.dart';
import 'components/layout.dart';
import 'components/admin/admin_dashboard.dart';
import 'components/teacher/class_management.dart';
import 'components/teacher/question_bank.dart';
import 'components/teacher/exam_management.dart';
import 'components/teacher/statistics.dart';
import 'components/student/exam_list.dart';
import 'components/student/take_exam.dart';
import 'components/student/exam_history.dart';
import 'components/team_info.dart';

import 'types/index.dart';
import 'l10n/app_text.dart';
import 'utils/storage.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  User? _currentUser;
  String _currentView = '';
  Exam? _activeExam;
  bool _isInitializing = true;
  Locale _locale = const Locale('vi');

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await initializeStorage();
    final user = await getCurrentUser();

    if (mounted) {
      if (user != null) {
        _setCurrentUserAndDefaultView(user);
      }
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _setCurrentUserAndDefaultView(User user) {
    setState(() {
      _currentUser = user;
      switch (user.role) {
        case 'admin':
          _currentView = 'accounts';
          break;
        case 'teacher':
          _currentView = 'classes';
          break;
        case 'student':
          _currentView = 'exam-list';
          break;
        default:
          _currentView = '';
      }
    });
  }

  Future<void> _handleLogin() async {
    final user = await getCurrentUser();
    if (user != null && mounted) {
      _setCurrentUserAndDefaultView(user);
    }
  }

  Future<void> _handleLogout() async {
    await removeCurrentUser();

    if (mounted) {
      setState(() {
        _currentUser = null;
        _currentView = '';
        _activeExam = null;
      });
    }
  }

  void _handleStartExam(Exam exam) {
    setState(() {
      _activeExam = exam;
    });
  }

  void _handleCompleteExam() {
    setState(() {
      _activeExam = null;
      _currentView = 'history';
    });
  }

  void _handleViewChange(String view) {
    setState(() {
      _currentView = view;
    });
  }

  void _handleLocaleChange(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Widget _buildContent() {
    if (_currentUser == null) return const SizedBox.shrink();

    switch (_currentUser!.role) {
      case 'admin':
        switch (_currentView) {
          case 'accounts':
            return const AdminDashboard();
          case 'team-info':
            return const TeamInfoPage();
          default:
            return const AdminDashboard();
        }

      case 'teacher':
        switch (_currentView) {
          case 'classes':
            return const ClassManagement();
          case 'questions':
            return const QuestionBank();
          case 'exams':
            return const ExamManagement();
          case 'statistics':
            return const Statistics();
          case 'team-info':
            return const TeamInfoPage();
          default:
            return const ClassManagement();
        }

      case 'student':
        switch (_currentView) {
          case 'exam-list':
            return ExamList(onStartExam: _handleStartExam);
          case 'history':
            return const ExamHistory();
          case 'team-info':
            return const TeamInfoPage();
          default:
            return ExamList(onStartExam: _handleStartExam);
        }

      default:
        return Builder(
          builder: (context) => Center(
            child: Text(
              context.t(
                'invalid_role',
                args: {'role': _currentUser!.role},
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Exam System',
      locale: _locale,
      supportedLocales: AppText.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: Builder(
        builder: (context) {
          if (_isInitializing) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_currentUser == null) {
            return Login(onLogin: _handleLogin);
          }

          if (_activeExam != null) {
            return TakeExam(
              exam: _activeExam!,
              onComplete: _handleCompleteExam,
            );
          }

          return Layout(
            user: _currentUser!,
            currentView: _currentView,
            onViewChange: _handleViewChange,
            onLogout: _handleLogout,
            locale: _locale,
            onLocaleChange: _handleLocaleChange,
            child: _buildContent(),
          );
        },
      ),
    );
  }
}
