import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:scholar_management_system/services/api_service.dart';
import '../services/file_download_service.dart';
import 'school_dialogs.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandCreamDark = Color(0xFFF3E7C4);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

// ============================================================
// VIEW SCHOOLS COMPONENT (registry table + profile pop-up)
// ============================================================

class ViewSchoolsComponent extends StatefulWidget {
  final VoidCallback? onRegisterSchool;
  const ViewSchoolsComponent({super.key, this.onRegisterSchool});

  @override
  State<ViewSchoolsComponent> createState() => _ViewSchoolsComponentState();
}

class _ViewSchoolsComponentState extends State<ViewSchoolsComponent> {
  String _searchQuery = '';
  String _selectedLevel = 'All';
  String _selectedRegion = 'All';
  bool _isLoading = true;
  String _userRole = 'User';

  List<Map<String, dynamic>> _allSchools = [];

  @override
  void initState() {
    super.initState();
    _fetchSchools();
    _fetchUserRole();
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

  Future<void> _fetchSchools() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllSchools();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        if (mounted) {
          setState(() {
            _allSchools = data.map((s) => {
              'id': s['id'].toString(),
              'name': s['name']?.toString() ?? '',
              'code': s['code']?.toString() ?? '',
              'level': s['level']?.toString() ?? '',
              'type': s['type']?.toString() ?? '',
              'genderPolicy': s['gender_policy']?.toString() ?? '',
              'region': s['region']?.toString() ?? '',
              'district': s['district']?.toString() ?? '',
              'address': s['address']?.toString() ?? '',
              'postal': s['postal_address']?.toString() ?? '',
              'phone': s['phone']?.toString() ?? '',
              'altPhone': s['alt_phone']?.toString() ?? '',
              'email': s['email']?.toString() ?? '',
              'website': s['website']?.toString() ?? '',
              'adminName': s['admin_name']?.toString() ?? '',
              'adminRole': s['admin_role']?.toString() ?? '',
              'adminPhone': s['admin_phone']?.toString() ?? '',
              'adminEmail': s['admin_email']?.toString() ?? '',
              'description': s['description']?.toString() ?? '',
              'notes': s['notes']?.toString() ?? '',
              'status': s['status']?.toString() ?? 'Active',
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _schoolLevels = [
    'All',
    'Primary School',
    'Secondary School',
    'High School',
    'Tertiary / University',
    'Vocational Training Center',
  ];

  final List<String> _regions = [
    'All',
    'Northern Region',
    'Central Region',
    'Southern Region',
  ];

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedLevel = 'All';
      _selectedRegion = 'All';
    });
    _fetchSchools();
  }

  // ---------------------------------------------------------------------
  // Activate / Deactivate a school
  // ---------------------------------------------------------------------
  void _toggleSchoolStatus(Map<String, dynamic> school) async {
    final bool wasActive = school['status'] == 'Active';
    try {
      final response = await ApiService.toggleSchoolStatus(school['id']!);
      if (response.statusCode == 200) {
        setState(() {
          school['status'] = wasActive ? 'Inactive' : 'Active';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasActive
                  ? "${school['name']} has been deactivated."
                  : "${school['name']} has been activated.",
            ),
            backgroundColor: wasActive ? kBrandOrange : kBrandOlive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling school status: $e');
    }
  }

  void _deleteSchool(Map<String, dynamic> school) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete School"),
        content: Text("Are you sure you want to delete ${school['name']}? This action cannot be undone."),
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
        final response = await ApiService.deleteSchool(school['id']!);
        if (response.statusCode == 200) {
          setState(() {
            _allSchools.removeWhere((s) => s['id'] == school['id']);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("School deleted successfully."), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting school: $e');
      }
    }
  }

  // ---------------------------------------------------------------------
  // EXPORT FUNCTIONALITY
  // ---------------------------------------------------------------------

  Future<void> _exportToPDF() async {
    final filtered = _getFilteredSchools();
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
        text: 'Advancing Girls\' Education in Africa\nBlantyre, Malawi | www.ageafrica.org\nOfficial Schools Registry Report',
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
        text: 'SCHOOLS REGISTRY - ${DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase()}',
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
      header.cells[0].value = 'Code';
      header.cells[1].value = 'School Name';
      header.cells[2].value = 'Level';
      header.cells[3].value = 'Region';
      header.cells[4].value = 'District';
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
        row.cells[0].value = s['code'];
        row.cells[1].value = s['name'];
        row.cells[2].value = s['level'];
        row.cells[3].value = s['region'];
        row.cells[4].value = s['district'];
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
        fileName: 'age_africa_schools_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Export PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
      }
    }
  }

  Future<void> _exportToExcel() async {
    final filtered = _getFilteredSchools();
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data to export.")));
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Schools'];
      excel.delete('Sheet1');

      List<String> headers = ['Code', 'Name', 'Level', 'Type', 'Region', 'District', 'Status', 'Phone', 'Email', 'Admin Name'];
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (final s in filtered) {
        sheetObject.appendRow([
          TextCellValue(s['code'] ?? ''),
          TextCellValue(s['name'] ?? ''),
          TextCellValue(s['level'] ?? ''),
          TextCellValue(s['type'] ?? ''),
          TextCellValue(s['region'] ?? ''),
          TextCellValue(s['district'] ?? ''),
          TextCellValue(s['status'] ?? ''),
          TextCellValue(s['phone'] ?? ''),
          TextCellValue(s['email'] ?? ''),
          TextCellValue(s['adminName'] ?? ''),
        ]);
      }

      final bytes = excel.encode();
      if (bytes != null) {
        await FileDownloadService.downloadFile(
          bytes: bytes,
          fileName: 'age_africa_schools_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        );
      }
    } catch (e) {
      debugPrint('Export Excel error: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredSchools() {
    return _allSchools.where((school) {
      final matchesSearch = school['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['code']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['district']!.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesLevel = _selectedLevel == 'All' || school['level'] == _selectedLevel;
      final matchesRegion = _selectedRegion == 'All' || school['region'] == _selectedRegion;

      return matchesSearch && matchesLevel && matchesRegion;
    }).toList();
  }

  // Opens the professional profile pop-up for a given school.
  // From there the user can launch the Edit pop-up, and any saved
  // changes are written back into _allSchools.
  void _openSchoolProfile(Map<String, dynamic> school) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "School Profile",
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: SchoolProfileDialog(
              school: school,
              onToggleStatus: () => _toggleSchoolStatus(school),
              onEdit: () async {
                Navigator.pop(ctx); // close profile pop-up first

                final updatedSchool = await showDialog<Map<String, dynamic>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (editContext) => EditSchoolDialog(school: school),
                );

                if (updatedSchool != null) {
                  setState(() {
                    final idx = _allSchools
                        .indexWhere((s) => s['id'] == school['id']);
                    if (idx != -1) {
                      _allSchools[idx] = updatedSchool;
                    }
                  });
                  // Re-open the profile pop-up with the freshly saved details.
                  _openSchoolProfile(updatedSchool);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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

  @override
  Widget build(BuildContext context) {
    // Filter the list of schools
    final filteredSchools = _allSchools.where((school) {
      final matchesSearch = school['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['code']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          school['district']!.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesLevel = _selectedLevel == 'All' || school['level'] == _selectedLevel;
      final matchesRegion = _selectedRegion == 'All' || school['region'] == _selectedRegion;

      return matchesSearch && matchesLevel && matchesRegion;
    }).toList();

    final activeCount = _allSchools.where((s) => s['status'] == 'Active').length;
    final tertiaryCount = _allSchools.where((s) => s['level'] == 'Tertiary / University').length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF4F6F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBrandBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: kBrandBrown, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Schools Registry",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${filteredSchools.length} of ${_allSchools.length} schools registered in the system.",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _miniStat(Icons.check_circle_rounded, "$activeCount Active", kBrandOlive),
                    _miniStat(Icons.school_rounded, "$tertiaryCount Tertiary", kBrandBrown),
                    const SizedBox(width: 8),
                    // Export Buttons
                    ElevatedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.table_view_rounded, size: 16),
                      label: const Text("Export Excel"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text("Export PDF"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (_userRole == 'Administrator')
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (widget.onRegisterSchool != null) {
                            widget.onRegisterSchool!();
                          } else {
                            final result = await Navigator.pushNamed(context, '/schools/register');
                            if (result == true) {
                              _fetchSchools();
                            }
                          }
                        },
                        icon: const Icon(Icons.add_business, size: 18),
                        label: const Text("Register School"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: kBrandBrown, size: 22),
                      tooltip: "Reset Filters",
                      onPressed: _resetFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search & Filter Bar — matches Scholars filter card
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
                    color: Colors.black.withValues(alpha: 0.03),
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
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Search by name, code or district",
                        hintText: "Enter search text...",
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
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedLevel,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Education Level",
                        prefixIcon: const Icon(Icons.layers, size: 18),
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
                      items: _schoolLevels.map((l) {
                        return DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedLevel = val ?? 'All';
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      isExpanded: true,
                      initialValue: _selectedRegion,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        labelText: "Region",
                        prefixIcon: const Icon(Icons.map, size: 18),
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
                      items: _regions.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRegion = val ?? 'All';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. School List Card
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
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                    : filteredSchools.isEmpty
                    ? Center(
                  child: Padding(
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
                          "No Schools Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try loosening your filters or clearing search text.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
                    : Scrollbar(
                  child: ListView.separated(
                    itemCount: filteredSchools.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final school = filteredSchools[index];
                      final isActive = school['status'] == 'Active';
                      final isTertiary = school['level'] == 'Tertiary / University';

                      return Container(
                        color: index.isEven ? Colors.white : Colors.grey.shade50.withValues(alpha: 0.6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isTertiary
                                  ? kBrandBrown.withValues(alpha: 0.10)
                                  : kBrandOlive.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTertiary ? Icons.account_balance : Icons.school,
                              color: isTertiary ? kBrandBrown : kBrandOlive,
                            ),
                          ),
                          title: Text(
                            school['name']!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5, color: Colors.black87),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text("Code: ${school['code']!}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isTertiary
                                        ? kBrandBrown.withValues(alpha: 0.08)
                                        : kBrandOrange.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    school['level']!,
                                    style: TextStyle(
                                      color: isTertiary ? kBrandBrown : kBrandOrange,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.circle, size: 4, color: Colors.grey.shade400),
                                Text(school['district']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? kBrandOlive.withValues(alpha: 0.12) : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive ? kBrandOlive.withValues(alpha: 0.4) : Colors.red.shade200,
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
                                      school['status']!,
                                      style: TextStyle(
                                        color: isActive ? kBrandOlive : Colors.red.shade900,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_userRole == 'Administrator') ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                                    color: isActive ? kBrandOlive : Colors.grey.shade500,
                                    size: 26,
                                  ),
                                  onPressed: () => _toggleSchoolStatus(school),
                                  tooltip: isActive ? "Deactivate" : "Activate",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: kBrandBrown),
                                  onPressed: () async {
                                    final updatedSchool = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (editContext) => EditSchoolDialog(school: school),
                                    );
                                    if (updatedSchool != null) {
                                      setState(() {
                                        final idx = _allSchools.indexWhere((s) => s['id'] == school['id']);
                                        if (idx != -1) {
                                          _allSchools[idx] = updatedSchool;
                                        }
                                      });
                                    }
                                  },
                                  tooltip: "Edit School",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteSchool(school),
                                  tooltip: "Delete School",
                                ),
                              ],
                              const SizedBox(width: 2),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          ),
                          onTap: () => _openSchoolProfile(school),
                        ),
                      );
                    },
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
