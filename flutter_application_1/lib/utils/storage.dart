import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/index.dart';

class StorageKeys {
  static const String users = 'exam_system_users';
  static const String classes = 'exam_system_classes';
  static const String questions = 'exam_system_questions';
  static const String exams = 'exam_system_exams';
  static const String submissions = 'exam_system_submissions';
  static const String currentUser = 'exam_system_current_user';
}

Future<void> initializeStorage() async {
  final prefs = await SharedPreferences.getInstance();
  bool isNullOrEmptyJsonList(String? data) {
    if (data == null) return true;
    try {
      final decoded = jsonDecode(data);
      return decoded is List && decoded.isEmpty;
    } catch (_) {
      return true;
    }
  }

  if (prefs.getString(StorageKeys.users) == null) {
    final defaultUsers = [
      const User(
        id: '1',
        username: 'admin',
        password: 'admin123',
        email: 'admin@example.com',
        fullName: 'Quản trị viên',
        role: 'admin',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
      const User(
        id: '2',
        username: 'teacher1',
        password: 'teacher123',
        email: 'teacher1@example.com',
        fullName: 'Nguyễn Văn A',
        role: 'teacher',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
      const User(
        id: '3',
        username: 'student1',
        password: 'student123',
        email: 'student1@example.com',
        fullName: 'Trần Thị B',
        role: 'student',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
      const User(
        id: '4',
        username: 'student2',
        password: 'student123',
        email: 'student2@example.com',
        fullName: 'Lê Văn C',
        role: 'student',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    ];
    // Encode list user sang json string để lưu
    final List<Map<String, dynamic>> jsonList = defaultUsers.map((u) => u.toJson()).toList();
    await prefs.setString(StorageKeys.users, jsonEncode(jsonList));
  }

  if (prefs.getString(StorageKeys.classes) == null) {
    final defaultClasses = [
      const Class(
        id: '1',
        name: 'Lập trình Web - K22',
        teacherId: '2',
        studentIds: ['3', '4'],
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    ];
    final List<Map<String, dynamic>> jsonList = defaultClasses.map((c) => c.toJson()).toList();
    await prefs.setString(StorageKeys.classes, jsonEncode(jsonList));
  }

  if (isNullOrEmptyJsonList(prefs.getString(StorageKeys.questions))) {
    final defaultQuestions = [
      const Question(
        id: '1',
        content: 'HTML là viết tắt của từ gì?',
        options: [
          'HyperText Markup Language',
          'HighText Machine Language',
          'HyperText and Links Markup Language',
          'None of these',
        ],
        correctAnswer: 0,
        teacherId: '2',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
      const Question(
        id: '2',
        content: 'CSS được sử dụng để làm gì?',
        options: [
          'Tạo cấu trúc trang web',
          'Tạo kiểu dáng cho trang web',
          'Lập trình logic',
          'Quản lý database'
        ],
        correctAnswer: 1,
        teacherId: '2',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
      const Question(
        id: '3',
        content: 'Trong HTML, thế nào dùng để tạo liên kết?',
        options: [
          '<link>',
          '<a>',
          '<href>',
          '<url>',
        ],
        correctAnswer: 1,
        teacherId: '2',
        createdAt: '2024-01-02T00:00:00.000Z',
      ),
      const Question(
        id: '4',
        content: 'Thuộc tính nào trong CSS dùng để đổi màu chữ?',
        options: [
          'font-style',
          'text-color',
          'color',
          'font-color',
        ],
        correctAnswer: 2,
        teacherId: '2',
        createdAt: '2024-01-02T00:00:00.000Z',
      ),
      const Question(
        id: '5',
        content: 'JavaScript dùng để làm gì trong web?',
        options: [
          'Tạo giao diện tĩnh',
          'Thêm tương tác và xử lý logic',
          'Lưu trữ dữ liệu trên server',
          'Định dạng văn bản',
        ],
        correctAnswer: 1,
        teacherId: '2',
        createdAt: '2024-01-03T00:00:00.000Z',
      ),
      const Question(
        id: '6',
        content: 'Trong Dart, kiểu dữ liệu nào dùng để lưu true/false?',
        options: [
          'int',
          'String',
          'bool',
          'double',
        ],
        correctAnswer: 2,
        teacherId: '2',
        createdAt: '2024-01-03T00:00:00.000Z',
      ),
    ];
    final List<Map<String, dynamic>> jsonList = defaultQuestions.map((q) => q.toJson()).toList();
    await prefs.setString(StorageKeys.questions, jsonEncode(jsonList));
  }

  if (isNullOrEmptyJsonList(prefs.getString(StorageKeys.exams))) {
    final defaultExams = [
      const Exam(
        id: '1',
        name: 'Đề thi cơ bản HTML-CSS',
        teacherId: '2',
        classId: '1',
        questionIds: ['1', '2', '3', '4'],
        duration: 30,
        startTime: '2025-01-01T00:00:00.000Z',
        endTime: '2030-12-31T23:59:59.000Z',
        status: 'active',
        allowViewAnswers: true,
        createdAt: '2025-01-01T00:00:00.000Z',
      ),
      const Exam(
        id: '2',
        name: 'Đề thi tổng hợp Web + Dart',
        teacherId: '2',
        classId: '1',
        questionIds: ['2', '3', '5', '6'],
        duration: 45,
        startTime: '2025-01-01T00:00:00.000Z',
        endTime: '2030-12-31T23:59:59.000Z',
        status: 'active',
        allowViewAnswers: true,
        password: '123456',
        createdAt: '2025-01-01T00:00:00.000Z',
      ),
    ];
    final List<Map<String, dynamic>> jsonList = defaultExams.map((e) => e.toJson()).toList();
    await prefs.setString(StorageKeys.exams, jsonEncode(jsonList));
  }

// Đảm bảo dữ liệu gốc vẫn tồn tại ngay cả khi bộ nhớ lưu trữ cũ đã chứa một phần dữ liệu.
  final seededQuestions = [
    const Question(
      id: '1',
      content: 'HTML là viết tắt của từ gì?',
      options: [
        'HyperText Markup Language',
        'HighText Machine Language',
        'HyperText and Links Markup Language',
        'None of these',
      ],
      correctAnswer: 0,
      teacherId: '2',
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    const Question(
      id: '2',
      content: 'CSS được sử dụng để làm gì?',
      options: [
        'Tạo cấu trúc trang web',
        'Tạo kiểu dáng cho trang web',
        'Lập trình logic',
        'Quản lý database'
      ],
      correctAnswer: 1,
      teacherId: '2',
      createdAt: '2024-01-01T00:00:00.000Z',
    ),
    const Question(
      id: '3',
      content: 'Trong HTML, thế nào dùng để tạo liên kết?',
      options: ['<link>', '<a>', '<href>', '<url>'],
      correctAnswer: 1,
      teacherId: '2',
      createdAt: '2024-01-02T00:00:00.000Z',
    ),
    const Question(
      id: '4',
      content: 'Thuộc tính nào trong CSS dùng để đổi màu chữ?',
      options: ['font-style', 'text-color', 'color', 'font-color'],
      correctAnswer: 2,
      teacherId: '2',
      createdAt: '2024-01-02T00:00:00.000Z',
    ),
    const Question(
      id: '5',
      content: 'JavaScript dùng để làm gì trong web?',
      options: [
        'Tạo giao diện tĩnh',
        'Thêm tương tác và xử lý logic',
        'Lưu trữ dữ liệu trên server',
        'Định dạng văn bản',
      ],
      correctAnswer: 1,
      teacherId: '2',
      createdAt: '2024-01-03T00:00:00.000Z',
    ),
    const Question(
      id: '6',
      content: 'Trong Dart, kiểu dữ liệu nào dùng để lưu true/false?',
      options: ['int', 'String', 'bool', 'double'],
      correctAnswer: 2,
      teacherId: '2',
      createdAt: '2024-01-03T00:00:00.000Z',
    ),
  ];
  final currentQuestions = await getQuestions();
  final questionIds = currentQuestions.map((q) => q.id).toSet();
  final missingQuestions = seededQuestions.where((q) => !questionIds.contains(q.id)).toList();
  if (missingQuestions.isNotEmpty) {
    await saveQuestions([...currentQuestions, ...missingQuestions]);
  }

  final seededExams = [
    const Exam(
      id: '1',
      name: 'Đề thi cơ bản HTML-CSS',
      teacherId: '2',
      classId: '1',
      questionIds: ['1', '2', '3', '4'],
      duration: 30,
      startTime: '2025-01-01T00:00:00.000Z',
      endTime: '2030-12-31T23:59:59.000Z',
      status: 'active',
      allowViewAnswers: true,
      createdAt: '2025-01-01T00:00:00.000Z',
    ),
    const Exam(
      id: '2',
      name: 'Đề thi tổng hợp Web + Dart',
      teacherId: '2',
      classId: '1',
      questionIds: ['2', '3', '5', '6'],
      duration: 45,
      startTime: '2025-01-01T00:00:00.000Z',
      endTime: '2030-12-31T23:59:59.000Z',
      status: 'active',
      allowViewAnswers: true,
      password: '123456',
      createdAt: '2025-01-01T00:00:00.000Z',
    ),
  ];
  final currentExams = await getExams();
  final examIds = currentExams.map((e) => e.id).toSet();
  final missingExams = seededExams.where((e) => !examIds.contains(e.id)).toList();
  if (missingExams.isNotEmpty) {
    await saveExams([...currentExams, ...missingExams]);
  }

  if (prefs.getString(StorageKeys.submissions) == null) {
    await prefs.setString(StorageKeys.submissions, jsonEncode([]));
  }
}

// Helper generic để get list
Future<List<T>> _getList<T>(
    String key, T Function(Map<String, dynamic>) fromJson) async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString(key);
  if (data == null) return [];
  final List<dynamic> jsonList = jsonDecode(data);
  return jsonList.map((e) => fromJson(e)).toList();
}

// Helper generic để save list
Future<void> _saveList<T>(String key, List<T> list) async {
  final prefs = await SharedPreferences.getInstance();
  // Vì T là generic nên ta cần trick để gọi toJson, 
  // nhưng đơn giản nhất là map thủ công ở các hàm gọi hoặc ép kiểu dynamic
  final jsonList = list.map((item) => (item as dynamic).toJson()).toList();
  await prefs.setString(key, jsonEncode(jsonList));
}

// --- USERS ---
Future<List<User>> getUsers() async {
  return _getList(StorageKeys.users, User.fromJson);
}

Future<void> saveUsers(List<User> users) async {
  await _saveList(StorageKeys.users, users);
}

Future<void> addUser(User user) async {
  final users = await getUsers();
  users.add(user);
  await saveUsers(users);
}

Future<void> updateUser(String id, Map<String, dynamic> updates) async {
  final users = await getUsers();
  final index = users.indexWhere((u) => u.id == id);
  if (index != -1) {
    final oldJson = users[index].toJson();
    final newJson = {...oldJson, ...updates};
    users[index] = User.fromJson(newJson);
    await saveUsers(users);
  }
}

Future<void> deleteUser(String id) async {
  final users = await getUsers();
  users.removeWhere((u) => u.id == id);
  await saveUsers(users);
}

Future<void> removeCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_user'); 
}
// --- CLASSES ---
Future<List<Class>> getClasses() async {
  return _getList(StorageKeys.classes, Class.fromJson);
}

Future<void> saveClasses(List<Class> classes) async {
  await _saveList(StorageKeys.classes, classes);
}

Future<void> addClass(Class cls) async {
  final classes = await getClasses();
  classes.add(cls);
  await saveClasses(classes);
}

Future<void> updateClass(String id, Map<String, dynamic> updates) async {
  final classes = await getClasses();
  final index = classes.indexWhere((c) => c.id == id);
  if (index != -1) {
    final oldJson = classes[index].toJson();
    final newJson = {...oldJson, ...updates};
    classes[index] = Class.fromJson(newJson);
    await saveClasses(classes);
  }
}

Future<void> deleteClass(String id) async {
  final classes = await getClasses();
  classes.removeWhere((c) => c.id == id);
  await saveClasses(classes);
}

// --- QUESTIONS ---
Future<List<Question>> getQuestions() async {
  return _getList(StorageKeys.questions, Question.fromJson);
}

Future<void> saveQuestions(List<Question> questions) async {
  await _saveList(StorageKeys.questions, questions);
}

Future<void> addQuestion(Question question) async {
  final questions = await getQuestions();
  questions.add(question);
  await saveQuestions(questions);
}

Future<void> updateQuestion(String id, Map<String, dynamic> updates) async {
  final questions = await getQuestions();
  final index = questions.indexWhere((q) => q.id == id);
  if (index != -1) {
    final oldJson = questions[index].toJson();
    final newJson = {...oldJson, ...updates};
    questions[index] = Question.fromJson(newJson);
    await saveQuestions(questions);
  }
}

Future<void> deleteQuestion(String id) async {
  final questions = await getQuestions();
  questions.removeWhere((q) => q.id == id);
  await saveQuestions(questions);
}

// --- EXAMS ---
Future<List<Exam>> getExams() async {
  return _getList(StorageKeys.exams, Exam.fromJson);
}

Future<void> saveExams(List<Exam> exams) async {
  await _saveList(StorageKeys.exams, exams);
}

Future<void> addExam(Exam exam) async {
  final exams = await getExams();
  exams.add(exam);
  await saveExams(exams);
}

Future<void> updateExam(String id, Map<String, dynamic> updates) async {
  final exams = await getExams();
  final index = exams.indexWhere((e) => e.id == id);
  if (index != -1) {
    final oldJson = exams[index].toJson();
    final newJson = {...oldJson, ...updates};
    exams[index] = Exam.fromJson(newJson);
    await saveExams(exams);
  }
}

Future<void> deleteExam(String id) async {
  final exams = await getExams();
  exams.removeWhere((e) => e.id == id);
  await saveExams(exams);
}

// --- SUBMISSIONS ---
Future<List<ExamSubmission>> getSubmissions() async {
  return _getList(StorageKeys.submissions, ExamSubmission.fromJson);
}

Future<void> saveSubmissions(List<ExamSubmission> submissions) async {
  await _saveList(StorageKeys.submissions, submissions);
}

Future<void> addSubmission(ExamSubmission submission) async {
  final submissions = await getSubmissions();
  submissions.add(submission);
  await saveSubmissions(submissions);
}

// --- CURRENT USER ---
Future<User?> getCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString(StorageKeys.currentUser);
  return data != null ? User.fromJson(jsonDecode(data)) : null;
}

Future<void> setCurrentUser(User? user) async {
  final prefs = await SharedPreferences.getInstance();
  if (user != null) {
    await prefs.setString(StorageKeys.currentUser, jsonEncode(user.toJson()));
  } else {
    await prefs.remove(StorageKeys.currentUser);
  }
}
