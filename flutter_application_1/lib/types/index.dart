// lib/types/index.dart

enum UserRole { admin, teacher, student }

class User {
  final String id;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final String role; // Lưu dưới dạng string để dễ serialize
  final String createdAt;

  const User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  // Tạo copyWith để hỗ trợ update partial như TS
  User copyWith({
    String? id,
    String? username,
    String? password,
    String? email,
    String? fullName,
    String? role,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
        'role': role,
        'createdAt': createdAt,
      };
}

class Class {
  final String id;
  final String name;
  final String teacherId;
  final List<String> studentIds;
  final String createdAt;

  const Class({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.studentIds,
    required this.createdAt,
  });

  Class copyWith({
    String? id,
    String? name,
    String? teacherId,
    List<String>? studentIds,
    String? createdAt,
  }) {
    return Class(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'],
      name: json['name'],
      teacherId: json['teacherId'],
      studentIds: List<String>.from(json['studentIds']),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacherId': teacherId,
        'studentIds': studentIds,
        'createdAt': createdAt,
      };
}

class Question {
  final String id;
  final String content;
  final String? imageUrl;
  final List<String> options;
  final int correctAnswer;
  final String teacherId;
  final String createdAt;

  const Question({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.options,
    required this.correctAnswer,
    required this.teacherId,
    required this.createdAt,
  });

  Question copyWith({
    String? id,
    String? content,
    String? imageUrl,
    List<String>? options,
    int? correctAnswer,
    String? teacherId,
    String? createdAt,
  }) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      teacherId: json['teacherId'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'options': options,
        'correctAnswer': correctAnswer,
        'teacherId': teacherId,
        'createdAt': createdAt,
      };
}

class Exam {
  final String id;
  final String name;
  final String teacherId;
  final String classId;
  final List<String> questionIds;
  final int duration;
  final String startTime;
  final String endTime;
  final String status; // 'draft' | 'active' | 'closed'
  final bool allowViewAnswers;
  final String? password;
  final String createdAt;

  const Exam({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.classId,
    required this.questionIds,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.allowViewAnswers,
    this.password,
    required this.createdAt,
  });

  Exam copyWith({
    String? id,
    String? name,
    String? teacherId,
    String? classId,
    List<String>? questionIds,
    int? duration,
    String? startTime,
    String? endTime,
    String? status,
    bool? allowViewAnswers,
    String? password,
    String? createdAt,
  }) {
    return Exam(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      classId: classId ?? this.classId,
      questionIds: questionIds ?? this.questionIds,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      allowViewAnswers: allowViewAnswers ?? this.allowViewAnswers,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      name: json['name'],
      teacherId: json['teacherId'],
      classId: json['classId'],
      questionIds: List<String>.from(json['questionIds']),
      duration: json['duration'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: json['status'],
      allowViewAnswers: json['allowViewAnswers'],
      password: json['password'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacherId': teacherId,
        'classId': classId,
        'questionIds': questionIds,
        'duration': duration,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'allowViewAnswers': allowViewAnswers,
        if (password != null) 'password': password,
        'createdAt': createdAt,
      };
}

class ExamSubmission {
  final String id;
  final String examId;
  final String studentId;
  final Map<String, int> answers; // questionId -> selected option index
  final int score;
  final String submittedAt;

  const ExamSubmission({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.submittedAt,
  });

  factory ExamSubmission.fromJson(Map<String, dynamic> json) {
    return ExamSubmission(
      id: json['id'],
      examId: json['examId'],
      studentId: json['studentId'],
      answers: Map<String, int>.from(json['answers']),
      score: json['score'],
      submittedAt: json['submittedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'studentId': studentId,
        'answers': answers,
        'score': score,
        'submittedAt': submittedAt,
      };
}