import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'package:scholar_management_system/services/api_service.dart';
import 'academics_utils.dart';

class ReportCardsComponent extends StatefulWidget {
  final VoidCallback? onBack;
  const ReportCardsComponent({super.key, this.onBack});

  @override
  State<ReportCardsComponent> createState() => _ReportCardsComponentState();
}

class _ReportCardsComponentState extends State<ReportCardsComponent> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _allScholars = [];
  List<Student> _filteredScholars = [];
  Student? _selectedStudent;
  bool _isLoading = true;
  bool _isSearchExpanded = false;

  // Selection Options
  String _selectedYear = DateTime.now().year.toString();
  String _selectedPeriod = "ANNUAL"; 
  SchoolType _reportType = SchoolType.secondary;

  String _generationMode = "Individual"; // "Individual", "Batch"
  String _batchScope = "School"; // "All", "District", "School"
  String? _selectedBatchDistrict;
  String? _selectedBatchSchool;
  String? _selectedBatchClass;

  List<String> _availableSchools = [];
  List<String> _availableClasses = [];

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllScholars();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _allScholars = data.map((item) => Student.fromMap(item)).toList();
        _updateAvailableFilters();
        _filterScholars(_searchController.text);
      }
    } catch (e) {
      debugPrint('Error loading scholars: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterScholars(String query) {
    setState(() {
      _filteredScholars = _allScholars
          .where((s) => s.status == 'Active' && 
                        s.schoolType == _reportType &&
                        (s.name.toLowerCase().contains(query.toLowerCase()) || 
                         s.scholarId.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  void _updateAvailableFilters() {
    final typeFiltered = _allScholars.where((s) => s.schoolType == _reportType);
    
    _availableSchools = typeFiltered.map((s) => s.schoolName).toSet().toList()..sort();
    
    Iterable<Student> schoolFiltered = typeFiltered;
    if (_selectedBatchSchool != null) {
      schoolFiltered = schoolFiltered.where((s) => s.schoolName == _selectedBatchSchool);
    }
    _availableClasses = schoolFiltered.map((s) => s.currentClass).toSet().toList()..sort();
    
    setState(() {});
  }

  void _selectStudent(Student student) {
    setState(() {
      _selectedStudent = student;
      _reportType = student.schoolType;
      _selectedPeriod = "ANNUAL"; 
      _generationMode = "Individual";
    });
  }

  Future<void> _generateReport() async {
    if (_generationMode == "Individual" && _selectedStudent == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: kBrandOlive)),
    );

    try {
      if (_generationMode == "Individual") {
        final response = await ApiService.getResultsByScholar(_selectedStudent!.id, year: _selectedYear);
        if (mounted) Navigator.pop(context);

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['data'] ?? [];
          final results = _processResults(data);

          if (results.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No results found for $_selectedPeriod $_selectedYear.'), backgroundColor: Colors.orange),
            );
            return;
          }
          await _printPdf(results, _selectedStudent!);
        }
      } else {
        // Batch Mode
        List<Student> targetGroup = _allScholars.where((s) => s.schoolType == _reportType && s.status == 'Active').toList();
        
        if (_batchScope == "District" && _selectedBatchDistrict != null) {
          targetGroup = targetGroup.where((s) => s.district == _selectedBatchDistrict).toList();
        } else if (_batchScope == "School" && _selectedBatchSchool != null) {
          targetGroup = targetGroup.where((s) => s.schoolName == _selectedBatchSchool).toList();
          if (_selectedBatchClass != null) {
            targetGroup = targetGroup.where((s) => s.currentClass == _selectedBatchClass).toList();
          }
        }

        if (targetGroup.isEmpty) {
          if (mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No scholars found in the selected group.'), backgroundColor: Colors.orange),
          );
          return;
        }

        // Fetch all results for the school/district in one go
        final response = await ApiService.getResultsBySchool(
          _batchScope == "School" ? _selectedBatchSchool : null,
          year: int.tryParse(_selectedYear),
        );
        
        if (mounted) Navigator.pop(context);

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data['data'] ?? [];
          final allBatchResults = _processResults(data);
          
          await _printBatchPdf(targetGroup, allBatchResults);
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('Error generating report: $e');
    }
  }

  List<ResultRecord> _processResults(List<dynamic> data) {
    final allResults = data.map((item) => ResultRecord(
      studentId: (item['scholar_id'] ?? item['scholarId'] ?? '').toString(),
      code: item['subject_code'] ?? 'N/A',
      subject: item['subject_name'] ?? item['subject'] ?? 'N/A',
      marks: double.tryParse(item['marks'].toString()) ?? 0.0,
      gpa: item['gpa'] != null ? double.tryParse(item['gpa'].toString()) : null,
      points: item['points'] != null ? double.tryParse(item['points'].toString()) : null,
      year: item['academic_year']?.toString() ?? item['year']?.toString() ?? '',
      term: item['term'],
      semester: item['semester'],
    )).toList();

    if (_selectedPeriod == "ANNUAL") return allResults;
    
    return allResults.where((r) => _reportType == SchoolType.university 
        ? r.semester == _selectedPeriod 
        : r.term == _selectedPeriod).toList();
  }

  Future<void> _printPdf(List<ResultRecord> results, Student student) async {
    final doc = pw.Document();
    final logo = await rootBundle.load('assets/images/age-logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    _addReportPage(doc, logoImage, results, student);

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: 'ReportCard_${student.name.replaceAll(' ', '_')}.pdf');
  }

  Future<void> _printBatchPdf(List<Student> students, List<ResultRecord> allResults) async {
    final doc = pw.Document();
    final logo = await rootBundle.load('assets/images/age-logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    int pagesAdded = 0;
    for (var student in students) {
      final studentResults = allResults.where((r) => r.studentId == student.id).toList();
      if (studentResults.isNotEmpty) {
        _addReportPage(doc, logoImage, studentResults, student);
        pagesAdded++;
      }
    }

    if (pagesAdded == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching results found for any scholar in this group.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final title = _batchScope == "School" ? _selectedBatchSchool : (_batchScope == "District" ? _selectedBatchDistrict : "All_Scholars");
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: 'BatchReports_${title?.replaceAll(' ', '_')}.pdf');
  }

  void _addReportPage(pw.Document doc, pw.MemoryImage logoImage, List<ResultRecord> results, Student student) {
    final isUni = student.schoolType == SchoolType.university;
    final totalMarks = results.fold(0.0, (sum, r) => sum + r.marks);
    final avgMarks = results.isEmpty ? 0 : totalMarks / results.length;
    
    // Group results by period for separate tables
    final periods = results.map((r) => (isUni ? r.semester : r.term) ?? 'Unknown').toSet().toList()..sort();

    String outcome = "";
    String aggregateLabel = "";
    
    if (isUni) {
      final validGpas = results.where((r) => r.gpa != null).map((r) => r.gpa!).toList();
      final avgGpa = validGpas.isEmpty ? 0.0 : validGpas.reduce((a, b) => a + b) / validGpas.length;
      outcome = "GPA: ${avgGpa.toStringAsFixed(2)}";
      aggregateLabel = "CUMULATIVE GPA:";
    } else {
      // MSCE Style for Secondary
      final outcomeData = calculateSecondaryOutcome(results);
      outcome = "${outcomeData.totalPoints.toInt()} Points (${outcomeData.passed ? 'PASS' : 'FAIL'})";
      aggregateLabel = "MSCE BEST 6 AGGREGATE:";
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, height: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("AGE AFRICA", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(kBrandBrown.value))),
                    pw.Text("Advancing Girls' Education", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(kBrandOlive.value))),
                    pw.Text("P.O. Box 31211, Chichiri, Blantyre 3, Malawi", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text("www.ageafrica.org", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColor.fromInt(kBrandBrown.value), thickness: 1.5),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) {
          final primaryColor = PdfColor.fromInt(kBrandBrown.value);
          
          return [
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: primaryColor, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  _selectedPeriod == "ANNUAL" 
                      ? "ANNUAL ACADEMIC PROGRESS TRANSCRIPT" 
                      : "OFFICIAL ACADEMIC REPORT CARD", 
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2, color: primaryColor),
                ),
              ),
            ),
            pw.SizedBox(height: 25),
            
            // Scholar Details Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(100),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(100),
                  3: const pw.FlexColumnWidth(),
                },
                children: [
                  _pwTableRow("SCHOLAR NAME:", student.name.toUpperCase(), "SCHOLAR ID:", student.scholarId),
                  _pwTableRow("INSTITUTION:", student.schoolName, "LEVEL:", isUni ? "UNIVERSITY" : "SECONDARY SCHOOL"),
                  _pwTableRow("ACADEMIC YEAR:", _selectedYear, "PERIOD:", _selectedPeriod),
                  _pwTableRow("PROGRAM/CLASS:", student.currentClass, "STATUS:", student.status),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Results Tables
            for (final period in periods) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(4), topRight: pw.Radius.circular(4))
                ),
                child: pw.Text(period.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white)),
              ),
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 9),
                headers: ['Subject / Course Description', 'Marks (%)', isUni ? 'GPA' : 'Points', 'Grade/Remark'],
                data: results.where((r) => (isUni ? r.semester : r.term) == period).map((r) {
                  final grade = gradeFromMarks(r.marks, isUniversity: isUni);
                  return [
                    r.subject,
                    "${r.marks.toStringAsFixed(0)}%",
                    isUni ? (r.gpa?.toStringAsFixed(2) ?? '-') : (r.points?.toStringAsFixed(0) ?? '-'),
                    grade.letter
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              if (isUni) ...[
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  child: pw.Text(
                    "Semester Average: ${(results.where((r) => r.semester == period).fold(0.0, (sum, r) => sum + r.marks) / (results.where((r) => r.semester == period).length.clamp(1, 999))).toStringAsFixed(1)}%",
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
              pw.SizedBox(height: 20),
            ],
            
            // Performance Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primaryColor, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    color: PdfColors.white,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PERFORMANCE SUMMARY", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                      pw.SizedBox(height: 8),
                      if (_selectedPeriod == "ANNUAL") ...[
                        for (final period in periods) ...[
                          _pwStatRow("$period AVG:", "${(results.where((r) => (isUni ? r.semester : r.term) == period).fold(0.0, (sum, r) => sum + r.marks) / results.where((r) => (isUni ? r.semester : r.term) == period).length).toStringAsFixed(1)}%"),
                          pw.SizedBox(height: 4),
                        ],
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 4),
                      ],
                      _pwStatRow("OVERALL AVERAGE:", "${avgMarks.toStringAsFixed(1)}%"),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(aggregateLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                          pw.Text(outcome, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),
            
            pw.Text("Official Certification:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor)),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                "This document is an official transcript of the academic performance for the scholar named above. "
                "The marks and grades reflected herein are verified by the AGE Africa academic governance committee. "
                "AGE Africa is committed to providing comprehensive support to ensure our scholars excel in their academic pursuits.",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800, lineSpacing: 1.5),
              ),
            ),
            
            pw.SizedBox(height: 50),
            
            // Footer Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Date Issued: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 15),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: 160,
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1))),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("PROGRAM COORDINATOR", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 15),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: 200,
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1))),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("COUNTRY DIRECTOR - AGE AFRICA", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ];
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text("Official AGE Africa Academic Document - Page ${context.pageNumber} of ${context.pagesCount}", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
        ),
      ),
    );
  }

  pw.TableRow _pwTableRow(String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(label2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.Widget _pwStatRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: isMobile
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildScholarListPanel(height: 400, isMobile: true),
                      const Divider(height: 1),
                      _buildReportConfigPanel(isMobile: true),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildScholarListPanel(),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                    Expanded(
                      flex: 5,
                      child: _buildReportConfigPanel(),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack ?? () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          if (!_isSearchExpanded)
            Expanded(
              child: Text(
                "Report Generator",
                style: TextStyle(
                  fontSize: isVerySmall ? 13 : 16, 
                  fontWeight: FontWeight.w900, 
                  color: const Color(0xFF4C3C32), 
                  letterSpacing: -0.2
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (isMobile) _buildMobileSearchToggle(),
          if (!_isSearchExpanded) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _fetchData,
              icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
              tooltip: "Refresh Scholars",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileSearchToggle() {
    if (!_isSearchExpanded) {
      return IconButton(
        icon: const Icon(Icons.search_rounded, color: Color(0xFF4C3C32), size: 20),
        onPressed: () => setState(() => _isSearchExpanded = true),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }

    return Expanded(
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterScholars,
          autofocus: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Search scholar...",
            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 18), 
              onPressed: () => setState(() {
                _isSearchExpanded = false;
                _searchController.clear();
                _filterScholars('');
              }),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildScholarListPanel({double? height, bool isMobile = false}) {
    return Container(
      height: height,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, isMobile ? 16 : 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SCHOLAR DIRECTORY",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF9AB334), letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),
                _buildDirectoryTypeToggle(),
                if (!isMobile) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterScholars,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: "Search name or ID...",
                        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF9AB334)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredScholars.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: Color(0xFFF3F4F6)),
                  itemBuilder: (context, index) {
                    final student = _filteredScholars[index];
                    final isSelected = _selectedStudent?.id == student.id;
                    final initials = getInitials(student.name);

                    return ListTile(
                      onTap: () => _selectStudent(student),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      selected: isSelected,
                      selectedTileColor: Color(0xFF9AB334).withOpacity(0.05),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4C3C32) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? const Color(0xFF4C3C32) : const Color(0xFFEEEEEE)),
                        ),
                        alignment: Alignment.center,
                        child: Text(initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF4C3C32))),
                      ),
                      title: Text(student.name.toUpperCase(), 
                        style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, fontSize: 13, color: const Color(0xFF4C3C32), letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(student.scholarId, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.circle, size: 2, color: Colors.grey),
                          ),
                          Expanded(child: Text(student.schoolName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade400), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF9AB334), size: 20) 
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportConfigPanel({bool isMobile = false}) {
    final isUni = _reportType == SchoolType.university;
    final periodOptions = isUni 
        ? ["ANNUAL", "Semester 1", "Semester 2"] 
        : ["ANNUAL", "Term 1", "Term 2", "Term 3"];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("GENERATION MODE", Icons.batch_prediction_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  _modeChip("INDIVIDUAL", "Individual", Icons.person_outline),
                  const SizedBox(width: 12),
                  _modeChip("BATCH / GROUP", "Batch", Icons.groups_outlined),
                ],
              ),
              const SizedBox(height: 32),

              if (_generationMode == "Batch") ...[
                _sectionHeader("BATCH SCOPE", Icons.analytics_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _scopeChip("BY SCHOOL", "School"),
                    const SizedBox(width: 8),
                    _scopeChip("BY DISTRICT", "District"),
                    const SizedBox(width: 8),
                    _scopeChip("ALL SYSTEM", "All"),
                  ],
                ),
                const SizedBox(height: 20),
                if (_batchScope == "District") 
                  _portalDropdown(_selectedBatchDistrict, kMalawiDistricts, (v) => setState(() => _selectedBatchDistrict = v)),
                if (_batchScope == "School") ...[
                  _portalDropdown(_selectedBatchSchool, _availableSchools, (v) {
                    setState(() {
                      _selectedBatchSchool = v;
                      _availableClasses = _allScholars
                          .where((s) => s.schoolName == v && s.schoolType == _reportType)
                          .map((s) => s.currentClass)
                          .toSet().toList()..sort();
                      _selectedBatchClass = null;
                    });
                  }),
                  const SizedBox(height: 12),
                  _portalDropdown(_selectedBatchClass, _availableClasses, (v) => setState(() => _selectedBatchClass = v), hint: "Filter by Class (Optional)"),
                ],
                const SizedBox(height: 32),
              ],

              _sectionHeader("ACADEMIC CYCLE", Icons.settings_rounded),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _portalLabel("Academic Report Tier"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _reportTypeChip("SECONDARY LEVEL", SchoolType.secondary, Icons.school_outlined),
                        const SizedBox(width: 16),
                        _reportTypeChip("UNIVERSITY LEVEL", SchoolType.university, Icons.account_balance_outlined),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _portalLabel("Academic Year"),
                              const SizedBox(height: 8),
                              _portalDropdown(_selectedYear, _academicYears, (v) { if (v != null) setState(() => _selectedYear = v); }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _portalLabel(isUni ? "Semester Period" : "School Term"),
                              const SizedBox(height: 8),
                              _portalDropdown(_selectedPeriod, periodOptions, (v) { if (v != null) setState(() => _selectedPeriod = v); }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              _sectionHeader("AUTHORIZATION & OUTPUT", Icons.verified_user_rounded),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Color(0xFF9AB334).withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF9AB334), size: 20),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SYSTEM AUTHORIZATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 0.5)),
                              Text("COUNTRY DIRECTOR", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 15, letterSpacing: -0.2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _generateReport,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(_generationMode == "Individual" 
                          ? "GENERATE OFFICIAL PDF TRANSCRIPT" 
                          : "GENERATE BATCH REPORTS", 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4C3C32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _generationMode == "Individual" 
                        ? "REPORT FOR: ${_selectedStudent?.name.toUpperCase() ?? 'NONE'}"
                        : "BATCH REPORT FOR: ${_batchScope.toUpperCase()} SCOPE",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, String value, IconData icon) {
    final bool isSelected = _generationMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _generationMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kBrandBrown : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? kBrandBrown : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scopeChip(String label, String value) {
    final bool isSelected = _batchScope == value;
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kBrandBrown)),
        selected: isSelected,
        onSelected: (v) => setState(() => _batchScope = value),
        selectedColor: kBrandOlive,
        backgroundColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _portalDropdown<T>(T? value, List<T> items, ValueChanged<T?> onChanged, {String? hint}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 12)) : null,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32))))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _portalLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey.shade400, letterSpacing: 0.5)),
  );

  Widget _reportTypeChip(String label, SchoolType type, IconData icon) {
    final bool isSelected = _reportType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _reportType = type;
          _selectedPeriod = type == SchoolType.university ? "Semester 1" : "Term 1";
          if (_selectedStudent?.schoolType != type) _selectedStudent = null;
          _filterScholars(_searchController.text);
        }),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? kBrandOlive.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? kBrandOlive : Colors.grey, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? kBrandOlive : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _directoryToggleBtn("Secondary", SchoolType.secondary)),
          const SizedBox(width: 4),
          Expanded(child: _directoryToggleBtn("University", SchoolType.university)),
        ],
      ),
    );
  }

  Widget _directoryToggleBtn(String label, SchoolType type) {
    final isSelected = _reportType == type;
    return InkWell(
      onTap: () => setState(() {
        _reportType = type;
        _selectedPeriod = type == SchoolType.university ? "Semester 1" : "Term 1";
        if (_selectedStudent?.schoolType != type) _selectedStudent = null;
        _filterScholars(_searchController.text);
      }),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? kBrandBrown : Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54, letterSpacing: 0.5));


  Widget _choiceChip(String label, dynamic value, bool selected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: kBrandOlive.withOpacity(0.2),
      labelStyle: TextStyle(color: selected ? kBrandOlive : Colors.black54, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
    );
  }

  InputDecoration _inputDeco() => InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
