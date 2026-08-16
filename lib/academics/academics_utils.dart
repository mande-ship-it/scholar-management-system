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

  int get calculatedRemainingYears {
    // If the scholar has already graduated or is an alumni, remaining tenure is zero.
    final String normStatus = status.toLowerCase();
    if (normStatus.contains('graduate') || normStatus.contains('alumni') || normStatus.contains('completed')) {
      return 0;
    }

    // Spec Section 2: yearsRemaining = programDurationYears - yearsCompleted
    // For Secondary: Form 1 (0 completed), Form 2 (1), Form 3 (2), Form 4 (3).
    // When Form 4 is completed, they move to Alumni status (handled above).
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
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    int parseAge(dynamic dobValue) {
      if (dobValue == null || dobValue.toString().isEmpty) return 18;
      try {
        // Try standard ISO format first
        return DateTime.now().year - DateTime.parse(dobValue.toString()).year;
      } catch (_) {
        try {
          // Try to extract year from JS-style date string: "Wed Jan 20 1993 ..."
          final parts = dobValue.toString().split(' ');
          for (var part in parts) {
            if (part.length == 4 && int.tryParse(part) != null) {
              final year = int.parse(part);
              if (year > 1900 && year <= DateTime.now().year) {
                return DateTime.now().year - year;
              }
            }
          }
        } catch (_) {}
      }
      return 18;
    }

    return Student(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      scholarId: map['scholar_id']?.toString() ?? map['scholarId']?.toString() ?? 'N/A',
      name: map['full_name'] ?? map['fullName'] ?? 'N/A',
      age: parseAge(map['dob']),
      schoolType: (map['school_type']?.toString().toLowerCase().contains('university') ?? false) ||
                  (map['schoolType']?.toString().toLowerCase().contains('university') ?? false)
          ? SchoolType.university
          : SchoolType.secondary,
      schoolName: map['display_school_name'] ?? 
                  map['schoolName'] ?? 
                  (map['schoolId'] is Map ? map['schoolId']['name'] : 'N/A'),
      currentClass: (map['academic_year'] ?? map['academicYear'] ?? map['current_class'] ?? map['currentClass'] ?? '').toString(),
      status: map['status'] ?? 'Active',
      district: map['district'] ?? 'N/A',
      village: map['village'] ?? 'N/A',
      donor: map['donor'] ?? 'N/A',
      phone: map['phone'] ?? 'N/A',
      email: map['email'] ?? 'N/A',
      sex: map['sex'] ?? 'Female',
      dob: map['dob']?.toString() ?? '',
      programType: map['program_type'] ?? map['programType'] ?? '',
      programName: map['program_name'] ?? map['programName'] ?? 'N/A',
      previousSchool: map['previous_school'] ?? map['previousSchool'] ?? 'N/A',
      startYear: map['start_year']?.toString() ?? map['startYear']?.toString() ?? '2026',
      endYear: map['end_year']?.toString() ?? map['endYear']?.toString() ?? '2030',
      guardianName: map['guardian_name'] ?? map['guardianName'],
      guardianPhone: map['guardian_phone'] ?? map['guardianPhone'],
      guardianEmail: map['guardian_email'] ?? map['guardianEmail'],
      guardianRelation: map['guardian_relation'] ?? map['guardianRelation'],
      guardianOccupation: map['guardian_occupation'] ?? map['guardianOccupation'],
      progressionStatus: map['progression_status'] ?? map['progressionStatus'] ?? 'Pending',
      progressionHistory: map['progression_history'] ?? map['progressionHistory'] ?? [],
      yearsRemaining: int.tryParse(map['years_remaining']?.toString() ?? map['yearsRemaining']?.toString() ?? '0') ?? 0,
      registeredClass: map['registered_class'] ?? map['registeredClass'],
      programStartYearLabel: map['program_start_year_label'] ?? map['programStartYearLabel'],
      programDurationYears: map['program_duration_years'] ?? map['programDurationYears'] ?? 4,
      yearsCompleted: map['years_completed'] ?? map['yearsCompleted'] ?? 0,
      flag: map['flag'],
      documents: map['documents'] ?? [],
    );
  }

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
  final String? currentClass; // e.g. Form 1, Year 1
  final String? term; // secondary: "Term 1" / "Term 2" / "Term 3"
  final String? semester; // university: "Semester 1" / "Semester 2"
  final String? status; // First Attempt, Repeat

  const ResultRecord({
    required this.studentId,
    required this.code,
    required this.subject,
    this.type = 'RC',
    required this.marks,
    this.gpa,
    this.points,
    required this.year,
    this.currentClass,
    this.term,
    this.semester,
    this.status,
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
      currentClass: map['currentClass'] ?? map['current_class'],
      term: map['term'],
      semester: map['semester'],
      status: map['status'],
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
  final String? id; // Allow ID for registry operations
  final String name;
  final String code;
  final String details;
  final String notes;
  final SubjectLevel level;

  const Subject({
    this.id,
    required this.name,
    required this.code,
    required this.details,
    required this.notes,
    required this.level,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'code': code,
    'details': details,
    'notes': notes,
    'level': level,
  };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: (map['id'] ?? map['_id'] ?? '').toString(),
    name: map['name'],
    code: map['code'],
    details: map['details'] ?? '',
    notes: map['notes'] ?? '',
    level: map['level'] is SubjectLevel 
        ? map['level'] 
        : (map['level'].toString().toLowerCase() == 'university' 
            ? SubjectLevel.university 
            : SubjectLevel.secondary),
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
/// Refined Scale:
/// University (User Spec): Distinction (75+), Credit (65-74), Pass (50-64), Fail (<50)
/// Secondary: MSCE standard (1-9 scale)
/// ---------------------------------------------------------------------
({String letter, double point}) gradeFromMarks(double marks, {required bool isUniversity}) {
  if (isUniversity) {
    if (marks >= 75) return (letter: 'Distinction', point: 4.00);
    if (marks >= 65) return (letter: 'Credit', point: 3.00);
    if (marks >= 50) return (letter: 'Pass', point: 2.00);
    return (letter: 'Fail', point: 0.00);
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

  // User Spec: Annual average should be average of terms, each term using best 6
  final terms = ['Term 1', 'Term 2', 'Term 3'];
  double totalTermAvgs = 0;
  int termsCount = 0;
  double lastPoints = 99;

  for (var term in terms) {
    final termResults = results.where((r) => r.term == term).toList();
    if (termResults.isEmpty) continue;

    final sorted = List<ResultRecord>.from(termResults)..sort((a, b) => b.marks.compareTo(a.marks));
    final best6 = sorted.take(6).toList();
    final termAvg = best6.fold(0.0, (sum, r) => sum + r.marks) / best6.length;
    final termPoints = best6.fold(0.0, (sum, r) => sum + (r.points ?? 9));
    
    totalTermAvgs += termAvg;
    termsCount++;
    lastPoints = termPoints; // Typically uses latest or annual best 6
  }

  double finalAvg = termsCount > 0 ? totalTermAvgs / termsCount : 0;
  bool passed = finalAvg >= 50;

  return (totalMarks: finalAvg, totalPoints: lastPoints, passed: passed);
}

({double totalMarks, double avgGpa, String status}) calculateUniversityOutcome(List<ResultRecord> results) {
  if (results.isEmpty) return (totalMarks: 0, avgGpa: 0, status: 'N/A');

  // User Spec: Best 5 per semester, then average of the two semesters
  final sem1 = results.where((r) => r.semester == 'Semester 1').toList();
  final sem2 = results.where((r) => r.semester == 'Semester 2').toList();

  double calcSemAvg(List<ResultRecord> semResults) {
    if (semResults.isEmpty) return 0;
    final sorted = List<ResultRecord>.from(semResults)..sort((a, b) => b.marks.compareTo(a.marks));
    final best5 = sorted.take(5).toList();
    return best5.fold(0.0, (sum, r) => sum + r.marks) / best5.length;
  }

  final avg1 = calcSemAvg(sem1);
  final avg2 = calcSemAvg(sem2);

  double finalAvg = 0;
  if (avg1 > 0 && avg2 > 0) finalAvg = (avg1 + avg2) / 2;
  else finalAvg = avg1 > 0 ? avg1 : avg2;

  final grade = gradeFromMarks(finalAvg, isUniversity: true);
  return (totalMarks: finalAvg, avgGpa: grade.point, status: grade.letter);
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
      'MSCE Trend Forecasting': 'Kunenera za MSCE',
      'Aggregate point projection (Best Six)': 'Kuyerekeza mfundo za Best Six',
      'Current Aggregate': 'Mfundo zapano',
      'Forecasted MSCE': 'Zoyembekezeka pa MSCE',
      'PROJECTED OUTCOME': 'ZOTSATIRA ZOYEMBEKEZEKA',
      'Division 1 (Excellent)': 'Gulu Loyamba (Zabwino Kwambiri)',
      'Division 2': 'Gulu Lachiwiri',
      'Division 3 / Fail': 'Gulu Lachitatu / Kulephera',
      'ASK AI ANALYST': 'FUNSANI WOPENDA WA AI',
    }
  };

  static String translate(String key) {
    if (currentLanguage == "English (Malawi)" || currentLanguage == "English (UK)") return key;
    return _dictionary[currentLanguage]?[key] ?? key;
  }
}
