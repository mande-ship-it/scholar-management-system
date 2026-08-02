import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Deletion", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text("Are you sure you want to delete ${school['name']}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text("DELETE"),
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
              const SnackBar(content: Text("School deleted successfully."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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

      PdfTextElement(
        text: 'AGE AFRICA',
        font: headerFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)),
      ).draw(page: page, bounds: Rect.fromLTWH(90, 10, pageSize.width - 90, 25))!;

      PdfTextElement(
        text: 'Advancing Girls\' Education in Africa\nBlantyre, Malawi | www.ageafrica.org\nOfficial Schools Registry Report',
        font: subHeaderFont,
        brush: PdfBrushes.black,
      ).draw(page: page, bounds: Rect.fromLTWH(90, 35, pageSize.width - 90, 50))!;

      page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(154, 179, 52)),
          brush: PdfSolidBrush(PdfColor(250, 242, 219)),
          bounds: Rect.fromLTWH(0, 100, pageSize.width, 30));

      PdfTextElement(
        text: 'SCHOOLS REGISTRY - ${DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase()}',
        font: titleFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      ).draw(page: page, bounds: Rect.fromLTWH(10, 108, pageSize.width - 20, 30))!;

      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 6);
      final PdfGridRow header = grid.headers.add(1)[0];
      header.cells[0].value = 'Code';
      header.cells[1].value = 'School Name';
      header.cells[2].value = 'Level';
      header.cells[3].value = 'Region';
      header.cells[4].value = 'District';
      header.cells[5].value = 'Status';

      final PdfGridCellStyle headerStyle = PdfGridCellStyle();
      headerStyle.backgroundBrush = PdfSolidBrush(PdfColor(76, 60, 50));
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

      grid.style = PdfGridStyle(cellPadding: PdfPaddings(left: 5, right: 3, top: 5, bottom: 5), font: PdfStandardFont(PdfFontFamily.helvetica, 9));
      grid.draw(page: page, bounds: Rect.fromLTWH(0, 150, pageSize.width, pageSize.height - 160));

      final List<int> bytes = await document.save();
      document.dispose();
      await FileDownloadService.downloadFile(bytes: bytes, fileName: 'age_africa_schools_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      debugPrint('Export PDF error: $e');
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
          TextCellValue(s['code'] ?? ''), TextCellValue(s['name'] ?? ''), TextCellValue(s['level'] ?? ''),
          TextCellValue(s['type'] ?? ''), TextCellValue(s['region'] ?? ''), TextCellValue(s['district'] ?? ''),
          TextCellValue(s['status'] ?? ''), TextCellValue(s['phone'] ?? ''), TextCellValue(s['email'] ?? ''),
          TextCellValue(s['adminName'] ?? ''),
        ]);
      }
      final bytes = excel.encode();
      if (bytes != null) {
        await FileDownloadService.downloadFile(bytes: bytes, fileName: 'age_africa_schools_${DateTime.now().millisecondsSinceEpoch}.xlsx');
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
                Navigator.pop(ctx);
                final updatedSchool = await showDialog<Map<String, dynamic>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (editContext) => EditSchoolDialog(school: school),
                );
                if (updatedSchool != null) {
                  setState(() {
                    final idx = _allSchools.indexWhere((s) => s['id'] == school['id']);
                    if (idx != -1) _allSchools[idx] = updatedSchool;
                  });
                  _openSchoolProfile(updatedSchool);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSchools = _getFilteredSchools();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(),
          _buildToolbar(),
          Expanded(
            child: _buildBody(filteredSchools),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Institutional Registry", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -1.0)),
                Text("Comprehensive management of secondary and tertiary educational partners.", 
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        if (_userRole == 'Administrator' || PermissionService.hasPermission('schools.create')) ...[
          ElevatedButton.icon(
            onPressed: () async {
              if (widget.onRegisterSchool != null) {
                widget.onRegisterSchool!();
              } else {
                final result = await Navigator.pushNamed(context, '/schools/register');
                if (result == true) _fetchSchools();
              }
            },
            icon: const Icon(Icons.add_business_rounded, size: 20),
            label: const Text("REGISTER SCHOOL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
        _exportAction(Icons.table_view_rounded, "EXCEL", Colors.green.shade700, _exportToExcel),
        const SizedBox(width: 12),
        _exportAction(Icons.picture_as_pdf_rounded, "PDF", Colors.red.shade700, _exportToPDF),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, color: kBrandBrown, size: 20),
            onPressed: _isLoading ? null : _fetchSchools,
            tooltip: 'Synchronize Registry',
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
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

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by school name, code, or geographic district...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 24),
          _toolbarDropdown("Level", _selectedLevel, _schoolLevels, (v) => setState(() => _selectedLevel = v!)),
          const SizedBox(width: 16),
          _toolbarDropdown("Region", _selectedRegion, _regions, (v) => setState(() => _selectedRegion = v!)),
        ],
      ),
    );
  }

  Widget _toolbarDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: kBrandBrown, fontWeight: FontWeight.w600),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> schools) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3));

    if (schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.grey.shade200, size: 100),
            const SizedBox(height: 24),
            Text(_allSchools.isEmpty ? 'REGISTRY IS CURRENTLY EMPTY' : 'NO SEARCH MATCHES', 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: schools.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = schools[index];
        final bool isUni = s['level']!.contains('University') || s['level']!.contains('Tertiary');
        final bool isActive = s['status'] == 'Active';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: (isUni ? kBrandBrown : kBrandOlive).withValues(alpha: 0.05), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(isUni ? Icons.account_balance_rounded : Icons.school_rounded, color: isUni ? kBrandBrown : kBrandOlive, size: 24),
            ),
            title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.w800, color: kBrandBrown, fontSize: 17)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _metaBadge(s['code']!, Colors.grey.shade100, Colors.grey.shade700),
                  _metaBadge(s['level']!.toUpperCase(), (isUni ? kBrandBrown : kBrandOrange).withValues(alpha: 0.05), isUni ? kBrandBrown : kBrandOrange),
                  Text(s['district']!, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusIndicator(s['status']!),
                if (PermissionService.hasPermission('schools.edit')) ...[
                  const SizedBox(width: 16),
                  _actionIcon(Icons.edit_note_rounded, kBrandBrown, () async {
                    final updated = await showDialog<Map<String, dynamic>>(context: context, builder: (c) => EditSchoolDialog(school: s));
                    if (updated != null) _fetchSchools();
                  }),
                ],
                if (PermissionService.hasPermission('schools.delete')) ...[
                  _actionIcon(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteSchool(s)),
                ],
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            onTap: () => _openSchoolProfile(s),
          ),
        );
      },
    );
  }

  Widget _metaBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _statusIndicator(String status) {
    final isActive = status == 'Active';
    final color = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.shade700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    );
  }
}
