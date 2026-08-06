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
  const ReportCardsComponent({super.key});

  @override
  State<ReportCardsComponent> createState() => _ReportCardsComponentState();
}

class _ReportCardsComponentState extends State<ReportCardsComponent> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _allScholars = [];
  List<Student> _filteredScholars = [];
  Student? _selectedStudent;
  bool _isLoading = true;
  String _directorName = "Executive Director";

  // Selection Options
  String _selectedYear = DateTime.now().year.toString();
  String _selectedPeriod = "ANNUAL"; 
  SchoolType _reportType = SchoolType.secondary;

  final List<String> _academicYears = academicYearOptions();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDirector();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllScholars();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        _allScholars = data.map((item) => Student(
          id: (item['id'] ?? item['_id'] ?? '').toString(),
          scholarId: item['scholarId'] ?? item['scholar_id'] ?? 'N/A',
          name: item['fullName'] ?? item['full_name'] ?? 'N/A',
          age: item['age'] ?? 16,
          schoolType: item['schoolType'] == 'University' || item['school_type'] == 'University' ? SchoolType.university : SchoolType.secondary,
          schoolName: item['schoolName'] ?? item['school_name'] ?? 'N/A',
          status: item['status'] ?? 'Active',
          donor: item['donor'] ?? 'N/A',
          currentClass: item['academicYear'] ?? item['academic_year'] ?? '',
        )).toList();
        _filteredScholars = _allScholars.where((s) => s.status == 'Active').toList();
      }
    } catch (e) {
      debugPrint('Error loading scholars: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDirector() async {
    try {
      final response = await ApiService.getDirector();
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _directorName = response.data['data']['name'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching director: $e');
    }
  }

  void _filterScholars(String query) {
    setState(() {
      _filteredScholars = _allScholars
          .where((s) => s.status == 'Active' && 
                        (s.name.toLowerCase().contains(query.toLowerCase()) || 
                         s.scholarId.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  void _selectStudent(Student student) {
    setState(() {
      _selectedStudent = student;
      _reportType = student.schoolType;
      _selectedPeriod = "ANNUAL"; 
    });
  }

  Future<void> _generateReport() async {
    if (_selectedStudent == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: kBrandOlive)),
    );

    try {
      final response = await ApiService.getResultsByScholar(_selectedStudent!.id, year: _selectedYear);
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final allResults = data.map((item) => ResultRecord(
          studentId: item['scholar_id'].toString(),
          code: item['subject_code'] ?? 'N/A',
          subject: item['subject_name'] ?? 'N/A',
          marks: double.tryParse(item['marks'].toString()) ?? 0.0,
          gpa: item['gpa'] != null ? double.tryParse(item['gpa'].toString()) : null,
          points: item['points'] != null ? double.tryParse(item['points'].toString()) : null,
          year: item['academic_year'].toString(),
          term: item['term'],
          semester: item['semester'],
        )).toList();

        List<ResultRecord> results;
        if (_selectedPeriod == "ANNUAL") {
          results = allResults;
        } else {
          results = allResults.where((r) => _reportType == SchoolType.university 
              ? r.semester == _selectedPeriod 
              : r.term == _selectedPeriod).toList();
        }

        if (results.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No results found for $_selectedPeriod $_selectedYear.'), backgroundColor: Colors.orange),
          );
          return;
        }

        await _printPdf(results);
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      debugPrint('Error generating report: $e');
    }
  }

  Future<void> _printPdf(List<ResultRecord> results) async {
    final doc = pw.Document();
    final logo = await rootBundle.load('assets/images/age-logo.png');
    final logoImage = pw.MemoryImage(logo.buffer.asUint8List());

    final isUni = _reportType == SchoolType.university;
    final totalMarks = results.fold(0.0, (sum, r) => sum + r.marks);
    final avgMarks = totalMarks / results.length;
    
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
                    pw.Text("AGE AFRICA", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(kBrandBrown.toARGB32()))),
                    pw.Text("Advancing Girls' Education", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(kBrandOlive.toARGB32()))),
                    pw.Text("P.O. Box 2147, Lilongwe, Malawi", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text("www.ageafrica.org", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColor.fromInt(kBrandBrown.toARGB32()), thickness: 1.5),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (pw.Context context) {
          final primaryColor = PdfColor.fromInt(kBrandBrown.toARGB32());
          
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
                  _pwTableRow("SCHOLAR NAME:", _selectedStudent!.name.toUpperCase(), "SCHOLAR ID:", _selectedStudent!.scholarId),
                  _pwTableRow("INSTITUTION:", _selectedStudent!.schoolName, "LEVEL:", isUni ? "UNIVERSITY" : "SECONDARY SCHOOL"),
                  _pwTableRow("ACADEMIC YEAR:", _selectedYear, "PERIOD:", _selectedPeriod),
                  _pwTableRow("PROGRAM/CLASS:", _selectedStudent!.currentClass, "STATUS:", _selectedStudent!.status),
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
                    pw.SizedBox(height: 25),
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
                    pw.Text(_directorName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic, color: primaryColor)),
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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: 'ReportCard_${_selectedStudent!.name.replaceAll(' ', '_')}.pdf');
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
      color: Colors.white,
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
              VerticalDivider(width: 1, color: Colors.grey.shade200),
              Expanded(
                flex: 5,
                child: _buildReportConfigPanel(),
              ),
            ],
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
                Text(
                  "Scholar Directory",
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: kBrandBrown),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _filterScholars,
                  decoration: InputDecoration(
                    hintText: "Search name or ID...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _filteredScholars.length,
                  separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final student = _filteredScholars[index];
                    final isSelected = _selectedStudent?.id == student.id;
                    final initials = student.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

                    return ListTile(
                      onTap: () => _selectStudent(student),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      selected: isSelected,
                      selectedTileColor: kBrandOlive.withOpacity(0.05),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: isSelected ? kBrandOlive : kBrandBrown.withOpacity(0.1),
                        child: Text(initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kBrandBrown)),
                      ),
                      title: Text(student.name, 
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text("${student.scholarId} • ${student.schoolName}", 
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: kBrandOlive, size: 20) : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportConfigPanel({bool isMobile = false}) {
    if (_selectedStudent == null) {
      return Container(
        color: Colors.grey.shade50,
        constraints: BoxConstraints(minHeight: isMobile ? 300 : 400),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
                  child: Icon(Icons.person_search_rounded, size: isMobile ? 32 : 48, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 20),
                const Text("Select a scholar to configure report", 
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isUni = _reportType == SchoolType.university;
    final periodOptions = isUni 
        ? ["ANNUAL", "Semester 1", "Semester 2"] 
        : ["ANNUAL", "Term 1", "Term 2", "Term 3"];

    return SingleChildScrollView(
      physics: isMobile ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.assignment_rounded, color: kBrandOlive, size: isMobile ? 20 : 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Report Settings", style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      const Text("Customize academic output.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            _label("Report Type"),
            const SizedBox(height: 12),
            Row(
              children: [
                _reportTypeChip("SECONDARY", SchoolType.secondary, Icons.school_outlined),
                const SizedBox(width: 16),
                _reportTypeChip("UNIVERSITY", SchoolType.university, Icons.account_balance_outlined),
              ],
            ),
            const SizedBox(height: 32),

            if (isMobile) ...[
              _label("Academic Year"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: _inputDeco(),
                items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
              const SizedBox(height: 24),
              _label(isUni ? "Semester" : "Term"),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: _inputDeco(),
                items: periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _selectedPeriod = v!),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Academic Year"),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedYear,
                          decoration: _inputDeco(),
                          items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(isUni ? "Semester Period" : "School Term"),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPeriod,
                          decoration: _inputDeco(),
                          items: periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setState(() => _selectedPeriod = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 48),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: kBrandOlive, size: 20),
                      const SizedBox(width: 12),
                      const Text("Director", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Expanded(
                        child: Text(_directorName, 
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontStyle: FontStyle.italic, color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.print_rounded),
                      label: Text(isMobile ? "GENERATE REPORT" : "GENERATE OFFICIAL PDF REPORT", 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrandBrown,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: kBrandBrown.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "REPORT FOR: ${_selectedStudent!.name.toUpperCase()}",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTypeChip(String label, SchoolType type, IconData icon) {
    final bool isSelected = _reportType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _reportType = type;
          _selectedPeriod = type == SchoolType.university ? "Semester 1" : "Term 1";
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
