import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

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
  final String id; // Database Primary Key
  final String scholarId; // Business ID (e.g., AGE-1)
  final String name;
  final int age;
  final SchoolType schoolType;
  final String schoolName;
  final String country;
  final String sex;
  final String dob;
  final String currentClass;
  final String status;
  final String district;
  final String village;
  final String donor;
  final String phone;
  final String email;
  final String programType;
  final String programName;
  final String previousSchool;
  final String startYear;
  final String endYear;

  // Guardian Details
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? guardianRelation;
  final String? guardianOccupation;

  const Student({
    required this.id,
    required this.scholarId,
    required this.name,
    required this.age,
    required this.schoolType,
    required this.schoolName,
    this.country = 'Malawi',
    this.sex = 'Female',
    this.dob = '',
    this.currentClass = '',
    this.status = 'Active',
    this.district = 'Lilongwe',
    this.village = '',
    this.donor = 'General Fund',
    this.phone = '',
    this.email = '',
    this.programType = '',
    this.programName = '',
    this.previousSchool = '',
    this.startYear = '2026',
    this.endYear = '2030',
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.guardianRelation,
    this.guardianOccupation,
  });

  Student copyWith({
    String? id,
    String? scholarId,
    String? name,
    int? age,
    SchoolType? schoolType,
    String? schoolName,
    String? country,
    String? sex,
    String? dob,
    String? currentClass,
    String? status,
    String? district,
    String? village,
    String? donor,
    String? phone,
    String? email,
    String? programType,
    String? programName,
    String? previousSchool,
    String? startYear,
    String? endYear,
    String? guardianName,
    String? guardianPhone,
    String? guardianEmail,
    String? guardianRelation,
    String? guardianOccupation,
  }) {
    return Student(
      id: id ?? this.id,
      scholarId: scholarId ?? this.scholarId,
      name: name ?? this.name,
      age: age ?? this.age,
      schoolType: schoolType ?? this.schoolType,
      schoolName: schoolName ?? this.schoolName,
      country: country ?? this.country,
      sex: sex ?? this.sex,
      dob: dob ?? this.dob,
      currentClass: currentClass ?? this.currentClass,
      status: status ?? this.status,
      district: district ?? this.district,
      village: village ?? this.village,
      donor: donor ?? this.donor,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      programType: programType ?? this.programType,
      programName: programName ?? this.programName,
      previousSchool: previousSchool ?? this.previousSchool,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      guardianOccupation: guardianOccupation ?? this.guardianOccupation,
    );
  }
}

class ResultRecord {
  final String studentId;
  final String code; // course/subject code e.g. "COM315"
  final String subject; // subject (secondary) or course title (university)
  final String type; // e.g. "RC" — defaults to 'RC' so existing records still compile
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
    this.type = 'RC',
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
  const Student(
    id: '1',
    scholarId: 'AGE-1',
    name: 'Chisomo Banda',
    age: 16,
    schoolType: SchoolType.secondary,
    schoolName: 'Kamuzu Academy',
    sex: 'Male',
    dob: '2010-02-15',
    currentClass: 'Form 3',
    status: 'Active',
    district: 'Lilongwe',
    village: 'Chilinde',
    donor: 'PMI',
    phone: '+265 888 123 456',
    email: 'chisomo.banda@example.com',
    startYear: '2023',
    endYear: '2027',
  ),
  const Student(
    id: '2',
    scholarId: 'AGE-2',
    name: 'Thandiwe Phiri',
    age: 20,
    schoolType: SchoolType.university,
    schoolName: 'University of Malawi',
    sex: 'Female',
    dob: '2006-08-20',
    currentClass: 'Year 2',
    status: 'Active',
    district: 'Zomba',
    village: 'Chinamwali',
    donor: 'BGE',
    phone: '+265 999 987 654',
    email: 'thandiwe.phiri@example.com',
    programType: 'Degree',
    startYear: '2024',
    endYear: '2028',
  ),
  const Student(
    id: '3',
    scholarId: 'AGE-3',
    name: 'Takondwa Mwale',
    age: 17,
    schoolType: SchoolType.secondary,
    schoolName: 'Chichiri Secondary School',
    sex: 'Female',
    dob: '2009-04-12',
    currentClass: 'Form 4',
    status: 'Active',
    district: 'Blantyre',
    village: 'Ndirande',
    donor: 'General Fund',
    phone: '+265 881 234 567',
    email: 'takondwa.mwale@example.com',
    startYear: '2022',
    endYear: '2026',
  ),
  const Student(
    id: '4',
    scholarId: 'AGE-4',
    name: 'Kondwani Nyirenda',
    age: 22,
    schoolType: SchoolType.university,
    schoolName: 'Mzuzu University',
    sex: 'Male',
    dob: '2004-11-05',
    currentClass: 'Year 3',
    status: 'Inactive',
    district: 'Mzimba',
    village: 'Likuni',
    donor: 'PMI',
    phone: '+265 992 345 678',
    email: 'kondwani.nyirenda@example.com',
    programType: 'Diploma',
    startYear: '2023',
    endYear: '2026',
  ),
  const Student(
    id: '5',
    scholarId: 'AGE-5',
    name: 'Chimwemwe Kaunda',
    age: 15,
    schoolType: SchoolType.secondary,
    schoolName: 'Providence High School',
    sex: 'Female',
    dob: '2011-05-30',
    currentClass: 'Form 1',
    status: 'Active',
    district: 'Dedza',
    village: 'Dedza Boma',
    donor: 'BGE',
    phone: '+265 888 777 666',
    email: 'chimwemwe.kaunda@example.com',
    startYear: '2025',
    endYear: '2029',
  ),
  const Student(
    id: '6',
    scholarId: 'AGE-6',
    name: 'Tendai Chirwa',
    age: 21,
    schoolType: SchoolType.university,
    schoolName: 'Malawi University of Business and Applied Sciences',
    sex: 'Female',
    dob: '2005-01-25',
    currentClass: 'Year 4',
    status: 'Active',
    district: 'Lilongwe',
    village: 'Area 25',
    donor: 'General Fund',
    phone: '+265 991 222 333',
    email: 'tendai.chirwa@example.com',
    programType: 'Degree',
    startYear: '2022',
    endYear: '2026',
  ),
  const Student(
    id: '7',
    scholarId: 'AGE-7',
    name: 'Mphatso Gondwe',
    age: 16,
    schoolType: SchoolType.secondary,
    schoolName: 'Kamuzu Academy',
    sex: 'Male',
    dob: '2010-09-18',
    currentClass: 'Form 2',
    status: 'Active',
    district: 'Rumphi',
    village: 'Rumphi Boma',
    donor: 'PMI',
    phone: '+265 883 444 555',
    email: 'mphatso.gondwe@example.com',
    startYear: '2024',
    endYear: '2028',
  ),
  const Student(
    id: '8',
    scholarId: 'AGE-8',
    name: 'Yamikani Mbewe',
    age: 19,
    schoolType: SchoolType.university,
    schoolName: 'University of Malawi',
    sex: 'Male',
    dob: '2007-06-14',
    currentClass: 'Year 1',
    status: 'Active',
    district: 'Zomba',
    village: 'Mponda',
    donor: 'BGE',
    phone: '+265 995 666 777',
    email: 'yamikani.mbewe@example.com',
    startYear: '2025',
    endYear: '2029',
  ),
];

class Subject {
  final String name;
  final String code;
  final String details;
  final String notes;
  final SubjectLevel level;

  const Subject({
    required this.name,
    required this.code,
    required this.details,
    required this.notes,
    required this.level,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'details': details,
    'notes': notes,
    'level': level,
  };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    name: map['name'],
    code: map['code'],
    details: map['details'],
    notes: map['notes'],
    level: map['level'],
  );
}

final List<Subject> kSubjects = [
  const Subject(
    name: 'Mathematics',
    details: 'Core mathematics including algebra and geometry.',
    notes: 'Required for science majors.',
    level: SubjectLevel.secondary,
    code: 'MATH101',
  ),
  const Subject(
    name: 'English Literature',
    details: 'Study of classic and modern literature.',
    notes: 'Compulsory course.',
    level: SubjectLevel.secondary,
    code: 'ENG102',
  ),
  const Subject(
    name: 'Biology',
    details: 'General biology, genetics, and human anatomy.',
    notes: 'Lab hours included.',
    level: SubjectLevel.secondary,
    code: 'BIO103',
  ),
  const Subject(
    name: 'Agriculture',
    details: 'Crop management and soil sciences.',
    notes: 'Practical field assignments.',
    level: SubjectLevel.secondary,
    code: 'AGR101',
  ),
  const Subject(
    name: 'Chichewa',
    details: 'National language grammar and literature.',
    notes: 'Core language subject.',
    level: SubjectLevel.secondary,
    code: 'CHI104',
  ),
  const Subject(
    name: 'Software Engineering',
    details: 'Design and construction of software systems.',
    notes: 'University level.',
    level: SubjectLevel.university,
    code: 'COM411',
  ),
];

final List<ResultRecord> kResults = [
  const ResultRecord(studentId: '1', code: 'MATH101', subject: 'Mathematics', marks: 78, points: 6, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: '1', code: 'ENG102', subject: 'English', marks: 65, points: 5, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: '1', code: 'BIO103', subject: 'Biology', marks: 82, points: 7, year: '2026', term: 'Term 2'),
  const ResultRecord(studentId: '1', code: 'CHI104', subject: 'Chichewa', marks: 74, points: 6, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: '2', code: 'COM211', subject: 'Data Structures', marks: 74, gpa: 3.6, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: '2', code: 'MATH212', subject: 'Calculus II', marks: 68, gpa: 3.1, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: '2', code: 'COM222', subject: 'Database Systems', marks: 88, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  const ResultRecord(studentId: '3', code: 'PHY301', subject: 'Physical Science', marks: 71, points: 6, year: '2025', term: 'Term 3'),
  const ResultRecord(studentId: '3', code: 'CHI302', subject: 'Chichewa', marks: 90, points: 8, year: '2025', term: 'Term 3'),

  const ResultRecord(studentId: '4', code: 'COM411', subject: 'Software Engineering', marks: 80, gpa: 3.8, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: '4', code: 'COM412', subject: 'Operating Systems', marks: 63, gpa: 2.9, year: '2026', semester: 'Semester 1'),

  const ResultRecord(studentId: '5', code: 'AGR101', subject: 'Agriculture', marks: 85, points: 7, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: '5', code: 'CHI104', subject: 'Chichewa', marks: 58, points: 4, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: '6', code: 'ACC421', subject: 'Accounting', marks: 76, gpa: 3.4, year: '2026', semester: 'Semester 2'),
  const ResultRecord(studentId: '6', code: 'STA422', subject: 'Business Statistics', marks: 91, gpa: 4.0, year: '2026', semester: 'Semester 2'),

  const ResultRecord(studentId: '7', code: 'MATH101', subject: 'Mathematics', marks: 93, points: 8, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: '7', code: 'PHY102', subject: 'Physics', marks: 88, points: 8, year: '2026', term: 'Term 1'),
  const ResultRecord(studentId: '7', code: 'CHI104', subject: 'Chichewa', marks: 70, points: 6, year: '2026', term: 'Term 1'),

  const ResultRecord(studentId: '8', code: 'ECN101', subject: 'Microeconomics', marks: 95, gpa: 4.0, year: '2026', semester: 'Semester 1'),
  const ResultRecord(studentId: '8', code: 'STA102', subject: 'Statistics', marks: 89, gpa: 3.9, year: '2026', semester: 'Semester 1'),
];

const List<String> kTerms = ['Term 1', 'Term 2', 'Term 3'];
const List<String> kSemesters = ['Semester 1', 'Semester 2'];

/// ---------------------------------------------------------------------
/// SHARED UTILITIES
/// ---------------------------------------------------------------------

({String label, Color color}) performanceBand(double avg) {
  if (avg >= 80) return (label: 'Excellent', color: Colors.green.shade700);
  if (avg >= 65) return (label: 'Good', color: Colors.blue.shade700);
  if (avg >= 50) return (label: 'Average', color: Colors.orange.shade800);
  return (label: 'Needs Improvement', color: Colors.red.shade700);
}

/// ---------------------------------------------------------------------
/// GRADING SCALE
/// ------------------------------------------------------------
/// Secondary (Points 1-9, 1 = best, 9 = worst) and
/// University (GPA 4.0-0.0, Grades A-F, A = best, F = worst).
/// ---------------------------------------------------------------------
({String letter, double point}) gradeFromMarks(double marks, {required bool isUniversity}) {
  if (isUniversity) {
    if (marks >= 75) return (letter: 'A', point: 4.00);
    if (marks >= 70) return (letter: 'B+', point: 3.50);
    if (marks >= 65) return (letter: 'B', point: 3.00);
    if (marks >= 60) return (letter: 'C+', point: 2.50);
    if (marks >= 55) return (letter: 'C', point: 2.00);
    if (marks >= 50) return (letter: 'D', point: 1.00);
    return (letter: 'F', point: 0.00);
  } else {
    // Secondary School (MSCE style)
    if (marks >= 80) return (letter: 'Distinction', point: 1.0);
    if (marks >= 75) return (letter: 'Distinction', point: 2.0);
    if (marks >= 70) return (letter: 'Credit', point: 3.0);
    if (marks >= 65) return (letter: 'Credit', point: 4.0);
    if (marks >= 60) return (letter: 'Credit', point: 5.0);
    if (marks >= 55) return (letter: 'Credit', point: 6.0);
    if (marks >= 50) return (letter: 'Pass', point: 7.0);
    if (marks >= 45) return (letter: 'Pass', point: 8.0);
    return (letter: 'Fail', point: 9.0);
  }
}

/// ---------------------------------------------------------------------
/// CALCULATION UTILITIES
/// ---------------------------------------------------------------------

({double totalMarks, double totalPoints, bool passed}) calculateSecondaryOutcome(List<ResultRecord> results) {
  if (results.isEmpty) return (totalMarks: 0, totalPoints: 0, passed: false);

  // Sort by points ascending (1 is best)
  final sorted = List<ResultRecord>.from(results)..sort((a, b) => (a.points ?? 9).compareTo(b.points ?? 9));

  final bestSix = sorted.take(6).toList();
  double totalMarks = bestSix.fold(0, (sum, r) => sum + r.marks);
  double totalPoints = bestSix.fold(0, (sum, r) => sum + (r.points ?? 9));

  // MSCE Pass: 6 subjects passed, including English (this is a simplification)
  // Let's just say total points <= 36 is a pass for best 6
  bool passed = bestSix.length >= 6 && totalPoints <= 40;

  return (totalMarks: totalMarks, totalPoints: totalPoints, passed: passed);
}

({double totalMarks, double avgGpa, String status}) calculateUniversityOutcome(List<ResultRecord> results) {
  if (results.isEmpty) return (totalMarks: 0, avgGpa: 0, status: 'N/A');

  double totalMarks = results.fold(0, (sum, r) => sum + r.marks);
  double avgGpa = results.fold(0.0, (sum, r) => sum + (r.gpa ?? 0)) / results.length;

  String status = 'Fail';
  if (avgGpa >= 3.5) status = 'Distinction';
  else if (avgGpa >= 3.0) status = 'Credit';
  else if (avgGpa >= 2.0) status = 'Pass';

  return (totalMarks: totalMarks, avgGpa: avgGpa, status: status);
}

/// ---------------------------------------------------------------------
/// ACADEMIC YEAR OPTIONS
/// ---------------------------------------------------------------------
/// Real academic years counting back from the current calendar year
/// (most recent first) — driven by the device clock, never a fixed
/// or arbitrary list, and never includes years in the future.
List<String> academicYearOptions({int pastYears = 6}) {
  final currentYear = DateTime.now().year;
  return List.generate(pastYears + 1, (i) => (currentYear - i).toString());
}

/// Combines a scholar's Semester 1 and Semester 2 university results
/// for a given year into a single annual average GPA.
double calculateAnnualGpa(List<ResultRecord> semester1, List<ResultRecord> semester2) {
  final all = [...semester1, ...semester2];
  if (all.isEmpty) return 0;
  return all.fold(0.0, (sum, r) => sum + (r.gpa ?? 0)) / all.length;
}