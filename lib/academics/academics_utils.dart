import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

String getInitials(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .map((e) => e.isNotEmpty ? e[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

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

  // --- Progression Tracking (New Fields - Spec Section 1) ---
  final String? registeredClass; 
  final String? programStartYearLabel;
  final int programDurationYears;
  final int yearsCompleted;
  final String? flag; // REPEAT, SUPPLEMENTARY
  // ----------------------------------------------------------

  // Guardian Details
  final String? guardianName;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? guardianRelation;
  final String? guardianOccupation;

  // Progression Tracking (Legacy/UI compatibility)
  final String progressionStatus; // Moved, Failed, Pending
  final List<dynamic> progressionHistory;
  final int yearsRemaining;

  // Additional Data
  final List<dynamic> documents;
  final List<dynamic> payments;

  int get calculatedRemainingYears {
    // Spec Section 2: yearsRemaining = programDurationYears - yearsCompleted
    final remaining = programDurationYears - yearsCompleted;
    return remaining > 0 ? remaining : 0;
  }

  String get calculatedRelativeYear {
    // Spec Section 2: currentRelativeYear = yearsCompleted + 1
    return "Year ${yearsCompleted + 1} of $programDurationYears";
  }

  String get calculatedAcademicYear {
    // Robust detection: prioritize actual labels over placeholders
    final List<String> placeholders = ['N/A', 'nv', 'NV', 'none', 'null', ''];
    
    if (currentClass.isNotEmpty && !placeholders.contains(currentClass.trim())) {
      return currentClass;
    }
    
    if (programStartYearLabel != null && 
        programStartYearLabel!.isNotEmpty && 
        !placeholders.contains(programStartYearLabel!.trim())) {
      return programStartYearLabel!;
    }
    
    // Fallback for Secondary: use registeredClass if available
    if (schoolType == SchoolType.secondary && registeredClass != null && !placeholders.contains(registeredClass!.trim())) {
      return registeredClass!;
    }

    return 'N/A';
  }

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
    this.registeredClass,
    this.programStartYearLabel,
    this.programDurationYears = 4,
    this.yearsCompleted = 0,
    this.flag,
    this.guardianName,
    this.guardianPhone,
    this.guardianEmail,
    this.guardianRelation,
    this.guardianOccupation,
    this.progressionStatus = 'Pending',
    this.progressionHistory = const [],
    this.yearsRemaining = 0,
    this.documents = const [],
    this.payments = const [],
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
    String? registeredClass,
    String? programStartYearLabel,
    int? programDurationYears,
    int? yearsCompleted,
    String? flag,
    String? guardianName,
    String? guardianPhone,
    String? guardianEmail,
    String? guardianRelation,
    String? guardianOccupation,
    String? progressionStatus,
    List<dynamic>? progressionHistory,
    int? yearsRemaining,
    List<dynamic>? documents,
    List<dynamic>? payments,
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
      registeredClass: registeredClass ?? this.registeredClass,
      programStartYearLabel: programStartYearLabel ?? this.programStartYearLabel,
      programDurationYears: programDurationYears ?? this.programDurationYears,
      yearsCompleted: yearsCompleted ?? this.yearsCompleted,
      flag: flag ?? this.flag,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      guardianRelation: guardianRelation ?? this.guardianRelation,
      guardianOccupation: guardianOccupation ?? this.guardianOccupation,
      progressionStatus: progressionStatus ?? this.progressionStatus,
      progressionHistory: progressionHistory ?? this.progressionHistory,
      yearsRemaining: yearsRemaining ?? this.yearsRemaining,
      documents: documents ?? this.documents,
      payments: payments ?? this.payments,
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

  factory ResultRecord.fromMap(Map<String, dynamic> map) {
    return ResultRecord(
      studentId: (map['scholar_id'] ?? map['scholarId'] ?? '').toString(),
      code: (map['subject_code'] ?? map['code'] ?? 'N/A').toString(),
      subject: (map['subject_name'] ?? map['subject'] ?? 'N/A').toString(),
      marks: double.tryParse(map['marks']?.toString() ?? '0') ?? 0.0,
      gpa: map['gpa'] != null ? double.tryParse(map['gpa'].toString()) : null,
      points: map['points'] != null ? double.tryParse(map['points'].toString()) : null,
      year: (map['academic_year'] ?? map['year'] ?? '').toString(),
      term: map['term'],
      semester: map['semester'],
    );
  }

  /// The grade point value regardless of secondary/university (whichever is set).
  double get gradePoint => gpa ?? points ?? 0;
}

/// ---------------------------------------------------------------------
/// PROJECT SOURCE OF TRUTH (Dynamically populated from backend)
/// ---------------------------------------------------------------------

final List<Student> kStudents = [];

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

final List<Subject> kSubjects = [];

final List<ResultRecord> kResults = [];

const List<String> kTerms = ['Term 1', 'Term 2', 'Term 3'];
const List<String> kSemesters = ['Semester 1', 'Semester 2'];

const List<String> kMalawiDistricts = [
  'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa', 'Dedza', 'Dowa',
  'Karonga', 'Kasungu', 'Likoma', 'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji',
  'Mulanje', 'Mwanza', 'Mzimba', 'Nkhata Bay', 'Nkhotakota', 'Nsanje', 'Ntcheu',
  'Ntchisi', 'Phalombe', 'Rumphi', 'Salima', 'Thyolo', 'Zomba'
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
/// Returns academic year strings from 2005 (AGE Africa foundation)
/// up to a reasonable future buffer (e.g., current year + 20).
List<String> academicYearOptions() {
  final currentYear = DateTime.now().year;
  const foundationYear = 2005;
  const futureBuffer = 50; // High buffer for future-proofing
  
  return List.generate(
    (currentYear + futureBuffer) - foundationYear + 1,
    (i) => (foundationYear + i).toString()
  ).reversed.toList();
}

/// Combines a scholar's Semester 1 and Semester 2 university results
/// for a given year into a single annual average GPA.
double calculateAnnualGpa(List<ResultRecord> semester1, List<ResultRecord> semester2) {
  final all = [...semester1, ...semester2];
  if (all.isEmpty) return 0;
  return all.fold(0.0, (sum, r) => sum + (r.gpa ?? 0)) / all.length;
}

/// Simple Translation Engine for Chichewa support
class Translator {
  static String currentLanguage = "English (Malawi)";

  static const Map<String, Map<String, String>> _dictionary = {
    'Chichewa': {
      // Core Navigation
      'Dashboard': 'Tsamba Laukulu',
      'Scholars': 'Ophunzira',
      'Schools': 'Masukulu',
      'Sponsors': 'Othandizira',
      'Academics': 'Maphunziro',
      'Attendance': 'Ofika',
      'Users': 'Ogwiritsa Ntchito',
      'Settings': 'Zosintha',
      'Operations': 'Ntchito',
      'Notifications': 'Zilengezo',
      
      // Sub-items & Actions
      'Overview': 'Chidule',
      'View Scholars': 'Onani Ophunzira',
      'Register Scholar': 'Lembetsani Wophunzira',
      'University Graduates': 'Omaliza Maphunziro a Ukachenjede',
      'Internship Allocation': 'Kugawira Ntchito Zoyeserera',
      'View Schools': 'Onani Masukulu',
      'Register School': 'Lembetsani Sukulu',
      'View Sponsors': 'Onani Othandizira',
      'Register Sponsor': 'Lembetsani Wothandizira',
      'Enter Results': 'Lembani Zotsatira',
      'View Results': 'Onani Zotsatira',
      'Report Cards': 'Malipoti a Maphunziro',
      'Performance Analysis': 'Kupenda Mmene Akuchitira',
      'Scholar Attendance': 'Ofika mwa Ophunzira',
      'View Attendance': 'Onani Ofika',
      'User Profile': 'Mbiri ya Wogwiritsa Ntchito',
      'Pending Approvals': 'Zodikira Chivomerezo',
      'Admin Overview': 'Chidule cha Maendetsedwe',
      'Command Center': 'Likulu la Maendetsedwe',
      
      // Settings
      'Organisation Profile': 'Mbiri ya Bungwe',
      'Backup & Restore': 'Kusunga & Kubwezeretsa Deta',
      'System Settings': 'Zosintha za Dongosolo',
      'Account Settings': 'Zosintha za Akaunti',
      
      // Dashboard & UI Labels
      'System Control Center': 'Likulu la Maendetsedwe',
      'Manage Users': 'Samalirani Ogwiritsa Ntchito',
      'Total Users': 'Onse Ogwiritsa Ntchito',
      'Active Sponsors': 'Othandizira Omwe Alipo',
      'Intelligence Hub': 'Likulu la Nzeru',
      'Executive Overview': 'Chidule cha Akuluakulu',
      'Data Continuity': 'Kusungika kwa Deta',
      'Security Profile': 'Mbiri ya Chitetezo',
      'Events & Programs': 'Zochitika & Mapulogalamu',
      'AI Strategy': 'Nzeru za AI',
      'AI Analyst': 'Wopenda wa AI',
      'Logout Session': 'Tulukani mu Dongosolo',
    }
  };

  static String translate(String key) {
    if (currentLanguage == "English (Malawi)" || currentLanguage == "English (UK)") return key;
    return _dictionary[currentLanguage]?[key] ?? key;
  }
}
