import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// SHARED MODELS & ENUMS
/// ---------------------------------------------------------------------

enum SchoolType { secondary, university }

enum SubjectLevel { secondary, university }

extension SubjectLevelLabel on SubjectLevel {
  String get label =>
      this == SubjectLevel.secondary ? 'Secondary' : 'University';
}

class Student {
  final String id;
  final String name;
  final int age;
  final SchoolType schoolType;
  final String schoolName;
  final String country;

  const Student({
    required this.id,
    required this.name,
    required this.age,
    required this.schoolType,
    required this.schoolName,
    this.country = 'Malawi',
  });
}

class ResultRecord {
  final String studentId;
  final String code; // course/subject code e.g. "COM315"
  final String subject; // subject (secondary) or course title (university)
  final double marks;
  final double? gpa; // university only — grade point for this course
  final double? points; // secondary only — grade point for this course
  final String year; // e.g. "2026"
  final String? term; // secondary: "Term 1" / "Term 2" / "Term 3"
  final String? semester; // university: "Semester 1" / "Semester 2"

  const ResultRecord({
    required this.studentId,
    required this.code,
    required this.subject,
    required this.marks,
    this.gpa,
    this.points,
    required this.year,
    this.term,
    this.semester,
  });

  /// The grade point value regardless of secondary/university (whichever is set).
  double get gradePoint => gpa ?? points ?? 0;
}

/// ---------------------------------------------------------------------
/// SHARED MOCK DATA (GLOBAL MUTABLE DATABASES)
/// ---------------------------------------------------------------------

final List<Student> kStudents = [
  const Student(id: 's1', name: 'Chisomo Banda', age: 16, schoolType: SchoolType.secondary, schoolName: 'Kamuzu Academy'),
  const Student(id: 's2', name: 'Thandiwe Phiri', age: 20, schoolType: SchoolType.university, schoolName: 'University of Malawi'),
  const Student(id: 's3', name: 'Takondwa Mwale', age: 17, schoolType: SchoolType.secondary, schoolName: 'Chichiri Secondary School'),
  const Student(id: 's4', name: 'Kondwani Nyirenda', age: 22, schoolType: SchoolType.university, schoolName: 'Mzuzu University'),
  const Student(id: 's5', name: 'Chimwemwe Kaunda', age: 15, schoolType: SchoolType.secondary, schoolName: 'Providence High School'),
  const Student(id: 's6', name: 'Tendai Chirwa', age: 21, schoolType: SchoolType.university, schoolName: 'Malawi University of Business and Applied Sciences'),
  const Student(id: 's7', name: 'Mphatso Gondwe', age: 16, schoolType: SchoolType.secondary, schoolName: 'Kamuzu Academy'),
  const Student(id: 's8', name: 'Yamikani Mbewe', age: 19, schoolType: SchoolType.university, schoolName: 'University of Malawi'),
];

final List<Map<String, dynamic>> kSubjects = [
  {
    'name': 'Mathematics',
    'details': 'Core mathematics including algebra and geometry.',
    'notes': 'Required for science majors.',
    'level': SubjectLevel.secondary,
    'code': 'MATH101',
  },
  {
    'name': 'English Literature',
    'details': 'Study of classic and modern literature.',
    'notes': 'Compulsory course.',
    'level': SubjectLevel.secondary,
    'code': 'ENG102',
  },
  {
    'name': 'Biology',
    'details': 'General biology, genetics, and human anatomy.',
    'notes': 'Lab hours included.',
    'level': SubjectLevel.secondary,
    'code': 'BIO103',
  },
  {
    'name': 'Agriculture',
    'details': 'Crop management and soil sciences.',
    'notes': 'Practical field assignments.',
    'level': SubjectLevel.secondary,
    'code': 'AGR101',
  },
  {
    'name': 'Chichewa',
    'details': 'National language grammar and literature.',
    'notes': 'Core language subject.',
    'level': SubjectLevel.secondary,
    'code': 'CHI104',
  },
  {
    'name': 'Software Engineering',
    'details': 'Design and construction of software systems.',
    'notes': 'University level.',
    'level': SubjectLevel.university,
    'code': 'COM411',
  },
];

final List<ResultRecord> kResults = [
  const ResultRecord(studentId: 's1', code: 'MATH101', subject: 'Mathematics', marks: 78, points: 6, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: 's1', code: 'ENG102', subject: 'English', marks: 65, points: 5, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: 's1', code: 'BIO103', subject: 'Biology', marks: 82, points: 7, year: '2026', term: 'Term 2'),
  const ResultRecord(studentId: 's1', code: 'CHI104', subject: 'Chichewa', marks: 74, points: 6, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: 's2', code: 'COM211', subject: 'Data Structures', marks: 74, gpa: 3.6, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: 's2', code: 'MATH212', subject: 'Calculus II', marks: 68, gpa: 3.1, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: 's2', code: 'COM222', subject: 'Database Systems', marks: 88, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  const ResultRecord(studentId: 's3', code: 'PHY301', subject: 'Physical Science', marks: 71, points: 6, year: '2025', term: 'Term 3'),
  const ResultRecord(studentId: 's3', code: 'CHI302', subject: 'Chichewa', marks: 90, points: 8, year: '2025', term: 'Term 3'),

  const ResultRecord(studentId: 's4', code: 'COM411', subject: 'Software Engineering', marks: 80, gpa: 3.8, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: 's4', code: 'COM412', subject: 'Operating Systems', marks: 63, gpa: 2.9, year: '2026', semester: 'Semester 1'),

  const ResultRecord(studentId: 's5', code: 'AGR101', subject: 'Agriculture', marks: 85, points: 7, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: 's5', code: 'CHI104', subject: 'Chichewa', marks: 58, points: 4, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: 's6', code: 'ACC421', subject: 'Accounting', marks: 76, gpa: 3.4, year: '2026', semester: 'Semester 2'),
  const ResultRecord(studentId: 's6', code: 'STA422', subject: 'Business Statistics', marks: 91, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  const ResultRecord(studentId: 's7', code: 'MATH101', subject: 'Mathematics', marks: 93, points: 8, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: 's7', code: 'PHY102', subject: 'Physics', marks: 88, points: 8, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: 's7', code: 'CHI104', subject: 'Chichewa', marks: 70, points: 6, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: 's8', code: 'ECN101', subject: 'Microeconomics', marks: 95, gpa: 4.0, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: 's8', code: 'STA102', subject: 'Statistics', marks: 89, gpa: 3.9, year: '2026', semester: 'Semester 1'),
];

/// ---------------------------------------------------------------------
/// SHARED UTILITIES
/// ---------------------------------------------------------------------

({String label, Color color}) performanceBand(double avg) {
  if (avg >= 80) return (label: 'Excellent', color: Colors.green.shade700);
  if (avg >= 65) return (label: 'Good', color: Colors.blue.shade700);
  if (avg >= 50) return (label: 'Average', color: Colors.orange.shade800);
  return (label: 'Needs Improvement', color: Colors.red.shade700);
}