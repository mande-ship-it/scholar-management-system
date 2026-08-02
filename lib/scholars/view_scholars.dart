import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../widgets/custom_loaders.dart';
import '../services/file_download_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';

// Shared validation patterns (kept consistent with Register Scholar).
final RegExp _kEmailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

// ============================================================
// VIEW SCHOLARS COMPONENT (registry table + profile pop-up)
// ============================================================

class ViewScholarsComponent extends StatefulWidget {
  final VoidCallback? onRegisterScholar;
  final Function(String)? onViewProfile;
  final VoidCallback? onViewGraduates;
  const ViewScholarsComponent({super.key, this.onRegisterScholar, this.onViewProfile, this.onViewGraduates});

  @override
  State<ViewScholarsComponent> createState() => _ViewScholarsComponentState();
}

class _ViewScholarsComponentState extends State<ViewScholarsComponent> with SingleTickerProviderStateMixin {
  // Search & Filter state variables
  String _searchQuery = '';
  String _selectedSchoolType = 'All';
  String _selectedSchoolName = 'All';
  String _selectedSex = 'All';
  bool _isLoading = true;
  String _userRole = 'User';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchScholars();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
          });
        }
      }
    } catch (_) {}
  }

  List<String> _registeredSchoolNames = [];

  Future<void> _fetchScholars() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      debugPrint('Syncing scholars and schools from backend...');

      // Parallel fetch for efficiency
      final results = await Future.wait([
        ApiService.getAllScholars(),
        ApiService.getAllSchools(),
      ]);

      final response = results[0];
      final schoolsRes = results[1];

      debugPrint('Scholars Status: ${response.statusCode}, Schools Status: ${schoolsRes.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];

        setState(() {
          kStudents.clear();
          for (var item in data) {
            try {
              kStudents.add(Student(
                id: item['id'].toString(),
                scholarId: item['scholar_id']?.toString() ?? 'N/A',
                name: item['full_name'] ?? 'N/A',
                age: item['dob'] != null && item['dob'].toString().isNotEmpty
                    ? DateTime.now().year - DateTime.parse(item['dob'].toString()).year
                    : 16,
                schoolType: (item['school_type']?.toString().toLowerCase().contains('university') ?? false) ||
                            (item['schoolType']?.toString().toLowerCase().contains('university') ?? false)
                    ? SchoolType.university
                    : SchoolType.secondary,
                schoolName: item['display_school_name'] ?? 'N/A',
                currentClass: item['academic_year'] ?? 'N/A',
                status: item['status'] ?? 'Active',
                district: item['district'] ?? 'N/A',
                village: item['village'] ?? 'N/A',
                donor: item['donor'] ?? 'N/A',
                phone: item['phone'] ?? 'N/A',
                email: item['email'] ?? 'N/A',
                sex: item['sex'] ?? 'Female',
                dob: item['dob']?.toString() ?? '',
                programType: item['program_type'] ?? '',
                programName: item['program_name'] ?? 'N/A',
                previousSchool: item['previous_primary_school'] ?? item['previous_school'] ?? 'N/A',
                startYear: item['start_year']?.toString() ?? '2026',
                endYear: item['end_year']?.toString() ?? '2030',
                guardianName: item['guardian_name'],
                guardianPhone: item['guardian_phone'],
                guardianEmail: item['guardian_email'],
                guardianRelation: item['guardian_relation'],
                guardianOccupation: item['guardian_occupation'],
                progressionStatus: item['progression_status'] ?? 'Pending',
                progressionHistory: item['progression_history'] ?? [],
                yearsRemaining: int.tryParse(item['years_remaining']?.toString() ?? '0') ?? 0,
              ));
            } catch (e) {
              debugPrint('Failed to map scholar: $e');
            }
          }
        });
      }

      if (schoolsRes.statusCode == 200) {
        final List<dynamic> sData = schoolsRes.data['data'] ?? [];
        setState(() {
          _registeredSchoolNames = sData
              .map((s) => s['name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dynamic getter referencing the global kStudents database as a single source of truth
  List<Map<String, String>> get _allScholars {
    return kStudents.map((s) => {
      'id': s.id,
      'scholarId': s.scholarId,
      'name': s.name,
      'schoolType': s.schoolType == SchoolType.secondary ? 'Secondary' : 'University',
      'school': s.schoolName,
      'class': s.calculatedAcademicYear,
      'status': s.status,
      'district': s.district,
      'donor': s.donor,
      'sex': s.sex,
      'dob': s.dob,
      'village': s.village,
      'phone': s.phone,
      'email': s.email,
      'programType': s.programType,
      'programName': s.programName,
      'previousSchool': s.previousSchool,
      'startYear': s.startYear,
      'endYear': s.endYear,
      'guardianName': s.guardianName ?? '',
      'guardianPhone': s.guardianPhone ?? '',
      'guardianEmail': s.guardianEmail ?? '',
      'guardianRelation': s.guardianRelation ?? '',
      'guardianOccupation': s.guardianOccupation ?? '',
      'progressionStatus': s.progressionStatus,
      'yearsRemaining': s.calculatedRemainingYears.toString(),
    }).toList();
  }

  // Helper to get matching schools list for the dropdown filter based on selected school type
  List<String> _getAvailableSchoolsForFilter() {
    final schoolNamesFromScholars = kStudents.map((s) => s.schoolName).where((n) => n.isNotEmpty && n != 'N/A');
    final combinedSet = <String>{
      ..._registeredSchoolNames,
      ...schoolNamesFromScholars,
    };

    final combinedList = combinedSet.toList();
    combinedList.sort();

    if (_selectedSchoolType == 'Secondary') {
      return combinedList.where((s) => s.toLowerCase().contains('secondary') || s.toLowerCase().contains('high') || s.toLowerCase().contains('school')).toList();
    } else if (_selectedSchoolType == 'University') {
      return combinedList.where((s) => s.toLowerCase().contains('university') || s.toLowerCase().contains('college') || s.toLowerCase().contains('polytechnic')).toList();
    } else {
      return combinedList;
    }
  }

  // Filter scholars list based on current user inputs
  List<Map<String, String>> _getFilteredScholars() {
    final statusFilter = _tabController.index == 0 ? 'Active' : 'Pending';

    return _allScholars.where((scholar) {
      // 0. Filter by status based on tab
      if (scholar['status'] != statusFilter) return false;

      // 1. Search by name (case-insensitive text search)
      final nameMatches = scholar['name']!
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());

      // 2. Filter by school type
      final typeMatches = _selectedSchoolType == 'All' ||
          scholar['schoolType'] == _selectedSchoolType;

      // 3. Filter by school name
      final schoolMatches = _selectedSchoolName == 'All' ||
          scholar['school'] == _selectedSchoolName;

      // 4. Filter by sex
      final sexMatches =
          _selectedSex == 'All' || scholar['sex'] == _selectedSex;

      return nameMatches && typeMatches && schoolMatches && sexMatches;
    }).toList();
  }

  String _initialsOf(String name) {
    if (name.trim().isEmpty) return 'NS';
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  // ---------------------------------------------------------------------
  // Activate / Deactivate a scholar
  // ---------------------------------------------------------------------
  void _toggleScholarStatus(Map<String, String> scholar) async {
    final bool wasActive = scholar['status'] == 'Active';
    final newStatus = wasActive ? 'Inactive' : 'Active';
    
    try {
      final response = await ApiService.updateScholar(scholar['id']!, {'status': newStatus});
      if (response.statusCode == 200) {
        _fetchScholars(); // Refresh list to get updated status
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasActive ? "${scholar['name']} has been deactivated." : "${scholar['name']} has been activated."),
            backgroundColor: wasActive ? kBrandOrange : kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating scholar status: $e');
    }
  }

  void _approveScholar(Map<String, String> scholar) async {
    try {
      final response = await ApiService.approveActivity('scholar', scholar['id']!);
      if (response.statusCode == 200) {
        _fetchScholars();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Scholar registration approved!"), backgroundColor: kBrandOlive),
        );
      }
    } catch (e) {
      debugPrint('Error approving scholar: $e');
    }
  }

  void _deleteScholar(Map<String, String> scholar) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Scholar"),
        content: Text("Are you sure you want to delete ${scholar['name']}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.deleteScholar(scholar['id']!);
        if (response.statusCode == 200) {
          setState(() {
            kStudents.removeWhere((s) => s.id == scholar['id']);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Scholar deleted successfully."), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting scholar: $e');
      }
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT FUNCTIONALITY
  // ---------------------------------------------------------------------

  Future<void> _exportToPDF() async {
    final filtered = _getFilteredScholars();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export.")));
      return;
    }

    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // 1. Add Logo and Header Information
      try {
        final ByteData data = await rootBundle.load('assets/images/age-logo.png');
        final Uint8List logoBytes = data.buffer.asUint8List();
        final PdfBitmap image = PdfBitmap(logoBytes);
        page.graphics.drawImage(image, const Rect.fromLTWH(0, 0, 80, 80));
      } catch (e) {
        debugPrint("Could not load logo for PDF: $e");
      }

      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      final PdfFont subHeaderFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);

      // Draw AGE Africa Info
      PdfTextElement(
        text: 'AGE AFRICA',
        font: headerFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)), // kBrandBrown
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(90, 10, pageSize.width - 90, 25),
      )!;

      PdfTextElement(
        text: 'Advancing Girls\' Education in Africa\nLilongwe, Malawi | www.ageafrica.org\nOfficial Scholars Registry Report',
        font: subHeaderFont,
        brush: PdfBrushes.black,
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(90, 35, pageSize.width - 90, 50),
      )!;

      // Draw Report Title
      page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(154, 179, 52)), // kBrandOlive
          brush: PdfSolidBrush(PdfColor(250, 242, 219)), // kBrandCream
          bounds: Rect.fromLTWH(0, 100, pageSize.width, 30));

      PdfTextElement(
        text: 'SCHOLARS REGISTRY - ${DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase()}',
        font: titleFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(10, 108, pageSize.width - 20, 30),
      )!;

      // 2. Build the Data Grid
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 6);
      
      final PdfGridRow header = grid.headers.add(1)[0];
      header.cells[0].value = 'ID';
      header.cells[1].value = 'Name';
      header.cells[2].value = 'School Type';
      header.cells[3].value = 'School';
      header.cells[4].value = 'Year/Form';
      header.cells[5].value = 'Status';

      // Style Header
      final PdfGridCellStyle headerStyle = PdfGridCellStyle();
      headerStyle.backgroundBrush = PdfSolidBrush(PdfColor(76, 60, 50)); // kBrandBrown
      headerStyle.textBrush = PdfBrushes.white;
      headerStyle.font = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      
      for (int i = 0; i < header.cells.count; i++) {
        header.cells[i].style = headerStyle;
      }

      for (final s in filtered) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = s['scholarId'];
        row.cells[1].value = s['name'];
        row.cells[2].value = s['schoolType'];
        row.cells[3].value = s['school'];
        row.cells[4].value = s['class'];
        row.cells[5].value = s['status'];
      }

      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 5, right: 3, top: 5, bottom: 5),
        font: PdfStandardFont(PdfFontFamily.helvetica, 9),
      );

      // Draw the grid
      grid.draw(page: page, bounds: Rect.fromLTWH(0, 150, pageSize.width, pageSize.height - 160));

      // 3. Add Footer
      final int pageCount = document.pages.count;
      for (int i = 0; i < pageCount; i++) {
        final PdfPage footerPage = document.pages[i];
        PdfTextElement(
          text: 'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} | Page ${i + 1} of $pageCount',
          font: subHeaderFont,
          brush: PdfSolidBrush(PdfColor(128, 128, 128)),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        ).draw(
          page: footerPage,
          bounds: Rect.fromLTWH(0, footerPage.getClientSize().height - 20, footerPage.getClientSize().width, 20),
        );
      }

      final List<int> bytes = await document.save();
      document.dispose();

      await FileDownloadService.downloadFile(
        bytes: bytes,
        fileName: 'age_africa_scholars_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Export PDF error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
    }
  }

  Future<void> _exportToExcel() async {
    final filtered = _getFilteredScholars();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export.")));
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Scholars'];
      excel.delete('Sheet1');

      List<String> headers = ['ID', 'Name', 'School Type', 'School', 'Year/Form', 'Status', 'District', 'Sex', 'Phone', 'Email', 'Donor'];
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (final s in filtered) {
        sheetObject.appendRow([
          TextCellValue(s['scholarId'] ?? ''),
          TextCellValue(s['name'] ?? ''),
          TextCellValue(s['schoolType'] ?? ''),
          TextCellValue(s['school'] ?? ''),
          TextCellValue(s['class'] ?? ''),
          TextCellValue(s['status'] ?? ''),
          TextCellValue(s['district'] ?? ''),
          TextCellValue(s['sex'] ?? ''),
          TextCellValue(s['phone'] ?? ''),
          TextCellValue(s['email'] ?? ''),
          TextCellValue(s['donor'] ?? ''),
        ]);
      }

      final bytes = excel.encode();
      if (bytes != null) {
        await FileDownloadService.downloadFile(
          bytes: bytes,
          fileName: 'scholars_registry_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        );
      }
    } catch (e) {
      debugPrint('Export Excel error: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Scholar Profile Popup
  // ---------------------------------------------------------------------
  void _showScholarProfileDialog(BuildContext context, Map<String, String> scholar) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Scholar Profile",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    final isActive = scholar['status'] == 'Active';
                    final hasProgram = scholar['programType'] != null &&
                        scholar['programType']!.isNotEmpty;
                    final isUniversity = scholar['schoolType'] == 'University';
                    final initials = _initialsOf(scholar['name']!);
                    final hasEmail =
                        scholar['email'] != null && scholar['email']!.isNotEmpty;

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      elevation: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ---------------- Professional White Header ----------------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(32, 32, 24, 24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: kBrandOlive.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kBrandOlive.withOpacity(0.2), width: 1),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: kBrandBrown,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        scholar['name']!.toUpperCase(),
                                        style: const TextStyle(
                                          color: kBrandBrown,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Text(
                                            "ID: ${scholar['scholarId']}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          _badge(scholar['status']!, isActive ? kBrandOlive : Colors.red),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.grey.shade50,
                                    hoverColor: Colors.grey.shade100,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ---------------- Body ----------------
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle("ACADEMIC OVERVIEW"),
                                  const SizedBox(height: 16),
                                  _infoGrid([
                                    _InfoItem(Icons.category_outlined, "Institutional Level", scholar['schoolType']!,
                                        valueColor: isUniversity ? kBrandBrown : kBrandOrange),
                                    _InfoItem(Icons.school_outlined, "Current Institution", scholar['school']!),
                                    _InfoItem(Icons.class_outlined, "Academic Standing", scholar['class']!),
                                    _InfoItem(
                                      Icons.workspace_premium_outlined,
                                      "Qualification",
                                      hasProgram ? scholar['programType']! : 'N/A',
                                    ),
                                    _InfoItem(Icons.assignment_outlined, "Specific Program", scholar['programName'] ?? 'N/A'),
                                    _InfoItem(Icons.history_edu_outlined, "Alumni School", scholar['previousSchool'] ?? 'N/A'),
                                    _InfoItem(Icons.event_outlined, "Entry Year", scholar['startYear'] ?? 'N/A'),
                                    _InfoItem(Icons.event_available_outlined, "Completion Year", scholar['endYear'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 32),
                                  _sectionTitle("INDIVIDUAL PROFILE"),
                                  const SizedBox(height: 16),
                                  _infoGrid([
                                    _InfoItem(Icons.wc_outlined, "Gender Identity", scholar['sex'] ?? 'N/A'),
                                    _InfoItem(Icons.cake_outlined, "Birth Date", scholar['dob'] ?? 'N/A'),
                                    _InfoItem(Icons.location_on_outlined, "Home District", scholar['district'] ?? 'N/A'),
                                    _InfoItem(Icons.home_outlined, "Primary Residence", scholar['village'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 32),
                                  _sectionTitle("COMMUNICATION & SUPPORT"),
                                  const SizedBox(height: 16),
                                  _infoGrid([
                                    _InfoItem(Icons.phone_outlined, "Contact Number", scholar['phone'] ?? 'N/A'),
                                    _InfoItem(Icons.email_outlined, "Official Email", hasEmail ? scholar['email']! : 'N/A'),
                                    _InfoItem(Icons.volunteer_activism_outlined, "Sponsorship Fund", scholar['donor'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 32),
                                  _sectionTitle("GUARDIANSHIP DATA"),
                                  const SizedBox(height: 16),
                                  _infoGrid([
                                    _InfoItem(Icons.supervisor_account_outlined, "Next of Kin", scholar['guardianName'] ?? 'N/A'),
                                    _InfoItem(Icons.family_restroom_outlined, "Relationship", scholar['guardianRelation'] ?? 'N/A'),
                                    _InfoItem(Icons.phone_android_outlined, "K.O.K Phone", scholar['guardianPhone'] ?? 'N/A'),
                                    _InfoItem(Icons.work_outline, "Occupation", scholar['guardianOccupation'] ?? 'N/A'),
                                  ]),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),

                          // ---------------- Footer Actions ----------------
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    if (_userRole == 'Administrator')
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            showEditScholarDialog(context, scholar).then((_) {
                                              _fetchScholars(); // Refresh list after edit
                                            });
                                          },
                                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                                          label: const Text("Edit Information", style: TextStyle(fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 20),
                                            backgroundColor: kBrandOlive,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ),
                                    if (_userRole == 'Administrator') const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          if (widget.onViewProfile != null) {
                                            widget.onViewProfile!(scholar['id']!);
                                          } else {
                                            Navigator.pushNamed(
                                              context,
                                              '/scholarProfile',
                                              arguments: {'id': scholar['id']},
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.person_search_outlined, size: 20),
                                        label: const Text("Comprehensive Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          foregroundColor: kBrandBrown,
                                          side: const BorderSide(color: kBrandBrown),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
        color: kBrandBrown,
      ),
    );
  }

  Widget _infoGrid(List<_InfoItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on wider dialogs, one column if narrow.
        final columns = constraints.maxWidth > 380 ? 2 : 1;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kBrandOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: kBrandOrange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: item.valueColor ?? Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Page-level UI helpers
  // ---------------------------------------------------------------------
  Widget _miniStat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _exportAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        side: BorderSide(color: color.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredScholars = _getFilteredScholars();
    final availableSchools = _getAvailableSchoolsForFilter();
    final activeCount = _allScholars.where((s) => s['status'] == 'Active').length;
    final universityCount = _allScholars.where((s) => s['schoolType'] == 'University' && s['status'] != 'Graduated').length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header (No Banners)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: kBrandBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.groups_rounded, color: kBrandBrown, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Scholars Registry",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${filteredScholars.length} scholars in current selection.",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _miniStat(Icons.check_circle_rounded, "$activeCount Active", kBrandOlive),
                        _miniStat(Icons.account_balance_rounded, "$universityCount University", kBrandBrown),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onViewGraduates != null) {
                              widget.onViewGraduates!();
                            } else {
                              Navigator.pushNamed(context, '/scholars/graduates');
                            }
                          },
                          icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                          label: const Text("VIEW GRADUATES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandBrown,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_userRole == 'Administrator' || PermissionService.hasPermission('scholars.create'))
                          ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onRegisterScholar != null) {
                                widget.onRegisterScholar!();
                              } else {
                                Navigator.pushNamed(context, '/registerScholar');
                              }
                            },
                            icon: const Icon(Icons.person_add_rounded, size: 20),
                            label: const Text("REGISTER SCHOLAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrandOlive,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        // Export Buttons
                        _exportAction(Icons.table_view_rounded, "EXCEL", Colors.green.shade700, _exportToExcel),
                        const SizedBox(width: 4),
                        _exportAction(Icons.picture_as_pdf_rounded, "PDF", Colors.red.shade700, _exportToPDF),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: kBrandBrown, size: 22),
                          tooltip: "Reset Filters",
                          onPressed: () {
                            _fetchScholars();
                            setState(() {
                              _searchQuery = '';
                              _selectedSchoolType = 'All';
                              _selectedSchoolName = 'All';
                              _selectedSex = 'All';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (PermissionService.hasAnyPermission(['scholars.approve', 'scholars.edit']))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: kBrandOlive,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: kBrandOlive,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      onTap: (index) => setState(() {}),
                      tabs: const [
                        Tab(text: "ACTIVE REGISTRY"),
                        Tab(text: "PENDING APPROVAL"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Name Search Field
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Search by Name",
                        hintText: "Enter name...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // School Type Filter
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedSchoolType,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "School Type",
                        prefixIcon: const Icon(Icons.category_outlined, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Types", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Secondary",
                          child: Text("Secondary", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "University",
                          child: Text("University", overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolType = value ?? 'All';
                          _selectedSchoolName = 'All'; // Reset school filter on type change
                        });
                      },
                    ),
                  ),

                  // School Name Filter (Cascading)
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      key: ValueKey(_selectedSchoolType),
                      initialValue: _selectedSchoolName,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "School Name",
                        prefixIcon: const Icon(Icons.school_outlined, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: "All",
                          child: Text("All Schools", overflow: TextOverflow.ellipsis),
                        ),
                        ...availableSchools.map((school) {
                          return DropdownMenuItem(
                            value: school,
                            child: Text(
                              school,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolName = value ?? 'All';
                        });
                      },
                    ),
                  ),

                  // Sex Filter
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedSex,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        labelText: "Sex",
                        prefixIcon: const Icon(Icons.wc_outlined, size: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: kBrandOlive, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "All",
                          child: Text("All Genders", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Male",
                          child: Text("Male", overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: "Other",
                          child: Text("Other", overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSex = value ?? 'All';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Scrollable Table Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading 
                    ? const BeautifulLoader(isOverlay: false, message: "Syncing Registry...")
                    : filteredScholars.isEmpty
                    ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No Scholars Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try loosening your filters or clearing search text.",
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                    : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 120,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(kBrandCream),
                        headingRowHeight: 48,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 64,
                        columnSpacing: 24,
                        horizontalMargin: 24,
                        dividerThickness: 0.6,
                        columns: const [
                          DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("School Type", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("School", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Year / Form", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Remaining", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Progression", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown))),
                        ],
                        rows: filteredScholars.asMap().entries.map((entry) {
                          final index = entry.key;
                          final scholar = entry.value;
                          final isActive = scholar['status'] == 'Active';
                          final hasProgram = scholar['programType'] != null && scholar['programType']!.isNotEmpty;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return kBrandCream.withOpacity(0.6);
                              }
                              return Colors.white;
                            }),
                            onSelectChanged: (selected) {
                              if (selected != null) {
                                _showScholarProfileDialog(context, scholar);
                              }
                            },
                            cells: [
                              DataCell(Text(scholar['scholarId']!, style: TextStyle(color: Colors.grey.shade600))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: kBrandOlive.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _initialsOf(scholar['name']!),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: kBrandBrown,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      scholar['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scholar['schoolType'] == 'University'
                                        ? kBrandBrown.withOpacity(0.08)
                                        : kBrandOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    scholar['schoolType']!,
                                    style: TextStyle(
                                      color: scholar['schoolType'] == 'University'
                                          ? kBrandBrown
                                          : kBrandOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    scholar['school']!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              DataCell(Text(scholar['class']!)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: int.parse(scholar['yearsRemaining']!) <= 1
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${scholar['yearsRemaining']} yrs",
                                    style: TextStyle(
                                      color: int.parse(scholar['yearsRemaining']!) <= 1
                                          ? Colors.red.shade700
                                          : Colors.blue.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scholar['progressionStatus'] == 'Moved'
                                        ? Colors.green.withOpacity(0.1)
                                        : scholar['progressionStatus'] == 'Failed'
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        scholar['progressionStatus'] == 'Moved'
                                            ? Icons.arrow_upward_rounded
                                            : scholar['progressionStatus'] == 'Failed'
                                                ? Icons.warning_amber_rounded
                                                : Icons.hourglass_empty_rounded,
                                        size: 14,
                                        color: scholar['progressionStatus'] == 'Moved'
                                            ? Colors.green.shade700
                                            : scholar['progressionStatus'] == 'Failed'
                                                ? Colors.red.shade700
                                                : Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        scholar['progressionStatus']!,
                                        style: TextStyle(
                                          color: scholar['progressionStatus'] == 'Moved'
                                              ? Colors.green.shade900
                                              : scholar['progressionStatus'] == 'Failed'
                                                  ? Colors.red.shade900
                                                  : Colors.grey.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? kBrandOlive.withOpacity(0.12) : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive ? kBrandOlive.withOpacity(0.4) : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isActive ? kBrandOlive : Colors.red.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        scholar['status']!,
                                        style: TextStyle(
                                          color: isActive ? kBrandOlive : Colors.red.shade900,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_tabController.index == 1 && PermissionService.hasPermission('scholars.approve'))
                                      IconButton(
                                        icon: const Icon(Icons.verified_user_rounded, color: kBrandOlive),
                                        onPressed: () => _approveScholar(scholar),
                                        tooltip: "Approve Registration",
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.person_search_outlined, color: kBrandOlive),
                                      onPressed: () {
                                        if (widget.onViewProfile != null) {
                                          widget.onViewProfile!(scholar['id']!);
                                        } else {
                                          Navigator.pushNamed(
                                            context,
                                            '/scholarProfile',
                                            arguments: {'id': scholar['id']},
                                          ).then((_) => _fetchScholars()); // Sync if deleted from profile
                                        }
                                      },
                                      tooltip: "View Profile",
                                    ),
                                    if (PermissionService.hasPermission('scholars.edit')) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_note, color: kBrandBrown),
                                        onPressed: () {
                                          showEditScholarDialog(context, scholar).then((_) {
                                            _fetchScholars(); // Refresh list after edit
                                          });
                                        },
                                        tooltip: "Edit Scholar",
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                          color: isActive ? kBrandOlive : Colors.grey.shade500,
                                          size: 26,
                                        ),
                                        onPressed: () => _toggleScholarStatus(scholar),
                                        tooltip: isActive ? "Deactivate" : "Activate",
                                      ),
                                    ],
                                    if (PermissionService.hasPermission('scholars.delete'))
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _deleteScholar(scholar),
                                        tooltip: "Delete Scholar",
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoItem(this.icon, this.label, this.value, {this.valueColor});
}


// ============================================================
// EDIT SCHOLAR POP-UP
// ============================================================

/// Call this to open the Edit Scholar form as a beautiful popup dialog.
/// Pass the scholar map (e.g. from a table row) or leave null to use
/// fallback demo data.
Future<void> showEditScholarDialog(
    BuildContext context,
    Map<String, String>? scholar,
    ) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Edit Scholar",
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.94 + (0.06 * curved.value),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
              child: EditScholarComponent(scholarData: scholar),
            ),
          ),
        ),
      );
    },
  );
}

class EditScholarComponent extends StatefulWidget {
  final Map<String, String>? scholarData;

  const EditScholarComponent({super.key, this.scholarData});

  @override
  State<EditScholarComponent> createState() => _EditScholarComponentState();
}

class _EditScholarComponentState extends State<EditScholarComponent> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _isLoadingSponsors = false;
  bool _isLoadingSchools = false;
  List<String> _registeredSponsors = [];
  List<Map<String, dynamic>> _registeredSchools = [];
  String? _selectedSchoolId;

  // Form Field States
  String? _selectedDistrict;
  String? _selectedSchoolType;
  String? _selectedSchool;
  String? _selectedProgramType;
  String? _selectedDonor;
  String? _selectedSex;
  DateTime? _selectedDateOfBirth;
  String? _selectedStartYear;
  String? _selectedEndYear;
  int? _selectedDuration;

  // Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _homeVillageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _previousSchoolController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  // Data lists
  final List<String> _districts = [
    'Balaka', 'Blantyre', 'Chikwawa', 'Chiradzulu', 'Chitipa',
    'Dedza', 'Dowa', 'Karonga', 'Kasungu', 'Likoma',
    'Lilongwe', 'Machinga', 'Mangochi', 'Mchinji', 'Mulanje',
    'Mwanza', 'Mzimba', 'Neno', 'Nkhata Bay', 'Nkhotakota',
    'Nsanje', 'Ntcheu', 'Ntchisi', 'Phalombe', 'Rumphi',
    'Salima', 'Thyolo', 'Zomba'
  ];

  final List<String> _schoolTypes = ['Secondary', 'University'];
  final List<String> _sexOptions = ['Female', 'Male', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchSponsors();
    _fetchSchools();
  }

  Future<void> _fetchSponsors() async {
    setState(() => _isLoadingSponsors = true);
    try {
      final response = await ApiService.getAllSponsors();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSponsors = data.map((s) => s['name'].toString()).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching sponsors: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSponsors = false);
    }
  }

  Future<void> _fetchSchools() async {
    setState(() => _isLoadingSchools = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _registeredSchools = data.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSchools = false);
    }
  }

  List<Map<String, dynamic>> _getAvailableSchoolsForScholar() {
    if (_selectedSchoolType == null) return [];

    final typeLower = _selectedSchoolType!.toLowerCase();
    return _registeredSchools.where((school) {
      final level = (school['level'] ?? '').toString().toLowerCase();

      if (typeLower == 'secondary') {
        return level.contains('secondary') || level.contains('high');
      } else if (typeLower == 'university') {
        return level.contains('university') || level.contains('tertiary') || level.contains('college');
      }
      return false;
    }).toList();
  }

  void _updateGraduationYear() {
    if (_selectedStartYear != null && _selectedDuration != null) {
      final start = int.parse(_selectedStartYear!);
      setState(() {
        _selectedEndYear = (start + _selectedDuration! - 1).toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = widget.scholarData;

      if (args != null) {
        _selectedDistrict = args['district'];
        _selectedSchoolType = args['schoolType'];
        _selectedSchool = args['school'];
        _selectedProgramType = (args['programType'] != null && args['programType']!.isNotEmpty)
            ? args['programType']
            : null;
        _selectedDonor = args['donor'];
        _selectedSex = args['sex'];
        _selectedStartYear = args['startYear'];
        _selectedEndYear = args['endYear'];

        // Calculate initial duration
        if (_selectedStartYear != null && _selectedEndYear != null) {
          try {
            final start = int.parse(_selectedStartYear!);
            final end = int.parse(_selectedEndYear!);
            _selectedDuration = (end - start) + 1;
            if (_selectedDuration! < 1 || _selectedDuration! > 6) _selectedDuration = null;
          } catch (_) {}
        }

        _fullNameController.text = args['name'] ?? '';
        _yearController.text = args['class'] ?? '';
        _homeVillageController.text = args['village'] ?? '';
        _phoneController.text = args['phone'] ?? '';
        _emailController.text = args['email'] ?? '';
        _dobController.text = args['dob'] ?? '';
        _previousSchoolController.text = args['previousSchool'] ?? '';
        _programNameController.text = args['programName'] ?? '';

        if (args['dob'] != null && args['dob']!.isNotEmpty) {
          try {
            _selectedDateOfBirth = DateTime.parse(args['dob']!);
          } catch (_) {}
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _yearController.dispose();
    _homeVillageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _previousSchoolController.dispose();
    _programNameController.dispose();
    super.dispose();
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (!_kEmailRegex.hasMatch(value.trim())) {
      return "Please enter a valid email address";
    }
    return null;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrandOlive,
              onPrimary: Colors.white,
              onSurface: kBrandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        'fullName': _fullNameController.text.trim(),
        'schoolType': _selectedSchoolType,
        'schoolName': _selectedSchool,
        'schoolId': _selectedSchoolId,
        'sex': _selectedSex,
        'dob': _dobController.text.trim(),
        'currentClass': _yearController.text.trim(),
        'district': _selectedDistrict,
        'village': _homeVillageController.text.trim(),
        'donor': _selectedDonor,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'programType': _selectedProgramType ?? '',
        'programName': _programNameController.text.trim(),
        'previousSchool': _previousSchoolController.text.trim(),
        'startYear': _selectedStartYear,
        'endYear': _selectedEndYear,
      };

      try {
        final response = await ApiService.updateScholar(widget.scholarData!['id']!, updatedData);
        if (response.statusCode == 200) {
          final index = kStudents.indexWhere((s) => s.id == widget.scholarData?['id']);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(
              name: _fullNameController.text.trim(),
              schoolType: _selectedSchoolType == 'University' ? SchoolType.university : SchoolType.secondary,
              schoolName: _selectedSchool ?? 'N/A',
              sex: _selectedSex ?? 'Female',
              dob: _dobController.text.trim(),
              currentClass: _yearController.text.trim(),
              district: _selectedDistrict ?? 'Lilongwe',
              village: _homeVillageController.text.trim(),
              donor: _selectedDonor ?? 'General Fund',
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              programType: _selectedProgramType ?? '',
              programName: _programNameController.text.trim(),
              previousSchool: _previousSchoolController.text.trim(),
              startYear: _selectedStartYear ?? '2026',
              endYear: _selectedEndYear ?? '2030',
            );
          }
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Scholar profile updated successfully!"),
                  ],
                ),
                backgroundColor: kBrandOlive,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          final errorMsg = response.data['message'] ?? "Unknown validation error.";
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to save: $errorMsg"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Critical error: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      enabled: enabled,
      isDense: true,
      filled: true,
      fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBrandOlive, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
          color: kBrandBrown,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> yearsList = List.generate(21, (index) => (DateTime.now().year - 5 + index).toString());
    if (_selectedStartYear != null && !yearsList.contains(_selectedStartYear)) {
      yearsList.add(_selectedStartYear!);
      yearsList.sort();
    }
    if (_selectedEndYear != null && !yearsList.contains(_selectedEndYear)) {
      yearsList.add(_selectedEndYear!);
      yearsList.sort();
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBrandBrown, kBrandOlive],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Edit Scholar Profile",
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullNameController.text.isEmpty
                              ? "Update the scholar's information"
                              : "Updating ${_fullNameController.text}",
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Body ----------------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle("Academic Information"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      decoration: _fieldDecoration(label: "District", icon: Icons.map_outlined, helperText: "Select district in Malawi"),
                      items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                      validator: (value) => value == null ? "Please select a district" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolType,
                      decoration: _fieldDecoration(label: "School Type", icon: Icons.category_outlined),
                      items: _schoolTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchoolType = value;
                          _selectedSchool = null;
                        });
                      },
                      validator: (value) => value == null ? "Please select a school type" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _previousSchoolController,
                      decoration: _fieldDecoration(
                        label: _selectedSchoolType == 'University' ? "Previous Secondary School" : "Previous Primary School",
                        icon: Icons.history_edu_outlined,
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('school_name_$_selectedSchoolType'),
                      initialValue: _selectedSchool,
                      isExpanded: true,
                      decoration: _fieldDecoration(
                        label: _isLoadingSchools
                          ? "Loading Institutions..."
                          : (_getAvailableSchoolsForScholar().isEmpty && _selectedSchoolType != null ? "No matching schools found" : "School Name"),
                        icon: Icons.school_outlined
                      ),
                      items: _getAvailableSchoolsForScholar().map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSchool = value;
                          try {
                            final found = _registeredSchools.firstWhere((s) => s['name'] == value);
                            _selectedSchoolId = (found['id'] ?? found['_id']).toString();
                          } catch (_) {
                            _selectedSchoolId = null;
                          }
                        });
                      },
                      validator: (value) => value == null ? "Please select a school" : null,
                    ),
                    if (_selectedSchoolType == 'University') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('programType_$_selectedSchoolType'),
                        initialValue: _selectedProgramType,
                        decoration: _fieldDecoration(label: "Program Type", icon: Icons.bookmark_outline),
                        items: const [
                          DropdownMenuItem(value: "Degree", child: Text("Degree")),
                          DropdownMenuItem(value: "Diploma", child: Text("Diploma")),
                          DropdownMenuItem(value: "Certificate", child: Text("Certificate")),
                        ],
                        onChanged: (value) => setState(() => _selectedProgramType = value),
                        validator: (value) => value == null ? "Please select a program type" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _programNameController,
                        decoration: _fieldDecoration(label: "Program of Study", icon: Icons.assignment_outlined),
                        validator: (value) => (_selectedSchoolType == 'University' && (value == null || value.trim().isEmpty)) ? "Required" : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: _fieldDecoration(label: "Year / Form", icon: Icons.calendar_today_outlined, helperText: "e.g., Form 3, Year 2"),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the academic year or form" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStartYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "Start Year" : "Session Start",
                              icon: Icons.event_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStartYear = value;
                                _updateGraduationYear();
                              });
                            },
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedDuration,
                            decoration: _fieldDecoration(label: "Duration", icon: Icons.timer_outlined),
                            items: [1, 2, 3, 4, 5, 6].map((d) => DropdownMenuItem(value: d, child: Text("$d Years"))).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedDuration = v;
                                _updateGraduationYear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('end_year_${_selectedStartYear}_$_selectedDuration'),
                            initialValue: _selectedEndYear,
                            decoration: _fieldDecoration(
                              label: _selectedSchoolType == 'University' ? "End Year" : "Session End",
                              icon: Icons.event_available_outlined,
                            ),
                            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                            onChanged: (value) => setState(() => _selectedEndYear = value),
                            validator: (value) {
                              if (value == null) return "Required";
                              if (_selectedStartYear != null) {
                                final start = int.parse(_selectedStartYear!);
                                final end = int.parse(value);
                                if (end < start) return "Must be ≥ start";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Personal Information"),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: _fieldDecoration(label: "Full Name", icon: Icons.person_outline),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the scholar's full name" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSex,
                            decoration: _fieldDecoration(label: "Sex", icon: Icons.wc_outlined),
                            items: _sexOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (value) => setState(() => _selectedSex = value),
                            validator: (value) => value == null ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDateOfBirth(context),
                            decoration: _fieldDecoration(
                              label: "Date of Birth",
                              icon: Icons.cake_outlined,
                              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeVillageController,
                      decoration: _fieldDecoration(label: "Home Village", icon: Icons.home_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the home village" : null,
                    ),
                    const SizedBox(height: 24),

                    _sectionTitle("Contact & Sponsorship"),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecoration(label: "Phone Number", icon: Icons.phone_outlined),
                      validator: (value) => (value == null || value.trim().isEmpty) ? "Please enter the phone number" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(label: "Email Address (optional)", icon: Icons.email_outlined),
                      validator: _validateOptionalEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDonor,
                      decoration: _fieldDecoration(label: "Donor / Sponsor", icon: Icons.volunteer_activism_outlined),
                      items: _registeredSponsors.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (value) => setState(() => _selectedDonor = value),
                      validator: (value) => value == null ? "Please select a donor" : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ---------------- Footer Actions ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Cancel"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: kBrandOlive,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
