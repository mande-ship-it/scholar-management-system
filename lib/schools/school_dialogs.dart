import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../services/file_download_service.dart';

// ============================================================
// SCHOOL PROFILE POP-UP
// ============================================================

class SchoolProfileDialog extends StatefulWidget {
  final Map<String, dynamic> school;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const SchoolProfileDialog({
    super.key,
    required this.school,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  State<SchoolProfileDialog> createState() => _SchoolProfileDialogState();
}

class _SchoolProfileDialogState extends State<SchoolProfileDialog> {
  String _initialsOf(String name) {
    return name
        .trim()
        .split(RegExp(r'\s+'))
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: kBrandOlive,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    if (value.trim().isEmpty || value == 'N/A') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBrandOlive.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: kBrandOlive),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kBrandCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBrandOlive.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kBrandBrown),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: kBrandBrown, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // INDIVIDUAL SCHOOL PROFILE EXPORT
  // ---------------------------------------------------------------------

  Future<void> _exportProfileToPDF() async {
    final school = widget.school;
    try {
      final PdfDocument document = PdfDocument();
      final PdfPage page = document.pages.add();
      final Size pageSize = page.getClientSize();

      // 1. Header with Logo
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
      final PdfFont labelFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
      final PdfFont valueFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

      PdfTextElement(
        text: 'AGE AFRICA',
        font: headerFont,
        brush: PdfSolidBrush(PdfColor(76, 60, 50)), // kBrandBrown
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(90, 10, pageSize.width - 90, 25),
      );

      PdfTextElement(
        text: 'Advancing Girls\' Education in Africa\nBlantyre, Malawi | www.ageafrica.org\nOfficial School Information Profile',
        font: subHeaderFont,
        brush: PdfBrushes.black,
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(90, 35, pageSize.width - 90, 50),
      );

      // 2. School Name Header
      page.graphics.drawRectangle(
          pen: PdfPen(PdfColor(154, 179, 52)), // kBrandOlive
          brush: PdfSolidBrush(PdfColor(250, 242, 219)), // kBrandCream
          bounds: Rect.fromLTWH(0, 100, pageSize.width, 35));

      PdfTextElement(
        text: (school['name'] ?? 'School Profile').toUpperCase(),
        font: PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(PdfColor(76, 60, 50)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(10, 110, pageSize.width - 20, 30),
      );

      // 3. Information Grid (Manual Layout)
      double currentY = 150;
      void drawInfoRow(String label, String value) {
        if (value.isEmpty || value == 'N/A') return;
        PdfTextElement(text: label, font: labelFont).draw(page: page, bounds: Rect.fromLTWH(0, currentY, 150, 20));
        PdfTextElement(text: ': $value', font: valueFont).draw(page: page, bounds: Rect.fromLTWH(150, currentY, pageSize.width - 150, 20));
        currentY += 20;
      }

      drawInfoRow('School Code', school['code'] ?? 'N/A');
      drawInfoRow('Education Level', school['level'] ?? 'N/A');
      drawInfoRow('School Type', school['type'] ?? 'N/A');
      drawInfoRow('Gender Policy', school['genderPolicy'] ?? 'N/A');
      drawInfoRow('Status', school['status'] ?? 'Active');
      currentY += 10;

      drawInfoRow('Region', school['region'] ?? 'N/A');
      drawInfoRow('District', school['district'] ?? 'N/A');
      drawInfoRow('Address', school['address'] ?? 'N/A');
      currentY += 10;

      drawInfoRow('Phone', school['phone'] ?? 'N/A');
      drawInfoRow('Email', school['email'] ?? 'N/A');
      drawInfoRow('Website', school['website'] ?? 'N/A');
      currentY += 10;

      drawInfoRow('Contact Person', school['adminName'] ?? 'N/A');
      drawInfoRow('Admin Role', school['adminRole'] ?? 'N/A');
      drawInfoRow('Admin Phone', school['adminPhone'] ?? 'N/A');

      if ((school['description'] ?? '').isNotEmpty) {
        currentY += 20;
        PdfTextElement(text: 'Description:', font: labelFont).draw(page: page, bounds: Rect.fromLTWH(0, currentY, pageSize.width, 20));
        currentY += 18;
        PdfTextElement(
          text: school['description']!,
          font: valueFont,
          brush: PdfBrushes.black,
        ).draw(
          page: page,
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, 100),
        );
      }

      // 4. Footer
      PdfTextElement(
        text: 'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} | Blantyre Regional Office',
        font: subHeaderFont,
        brush: PdfSolidBrush(PdfColor(128, 128, 128)),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      ).draw(
        page: page,
        bounds: Rect.fromLTWH(0, pageSize.height - 20, pageSize.width, 20),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      await FileDownloadService.downloadFile(
        bytes: bytes,
        fileName: 'school_profile_${school['code']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('Export PDF error: $e');
    }
  }

  Future<void> _exportProfileToExcel() async {
    final school = widget.school;
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['School Profile'];
      excel.delete('Sheet1');

      sheetObject.appendRow([TextCellValue('OFFICIAL SCHOOL PROFILE - AGE AFRICA')]);
      sheetObject.appendRow([TextCellValue('Location: Blantyre, Malawi')]);
      sheetObject.appendRow([TextCellValue('')]);

      void addRow(String label, String? value) {
        sheetObject.appendRow([TextCellValue(label), TextCellValue(value ?? 'N/A')]);
      }

      addRow('School Name', school['name']);
      addRow('School Code', school['code']);
      addRow('Education Level', school['level']);
      addRow('Agency Type', school['type']);
      addRow('Gender Policy', school['genderPolicy']);
      addRow('Status', school['status']);
      addRow('', '');
      addRow('Region', school['region']);
      addRow('District', school['district']);
      addRow('Physical Address', school['address']);
      addRow('', '');
      addRow('Phone', school['phone']);
      addRow('Email', school['email']);
      addRow('Website', school['website']);
      addRow('', '');
      addRow('Admin Name', school['adminName']);
      addRow('Admin Role', school['adminRole']);
      addRow('Admin Phone', school['adminPhone']);
      addRow('', '');
      addRow('Description', school['description']);

      final bytes = excel.encode();
      if (bytes != null) {
        await FileDownloadService.downloadFile(
          bytes: bytes,
          fileName: 'school_profile_${school['code']}.xlsx',
        );
      }
    } catch (e) {
      debugPrint('Export Excel error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.school;
    final isActive = school['status'] == 'Active';
    final isTertiary = school['level'] == 'Tertiary / University';
    final initials = _initialsOf(school['name'] ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          elevation: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------- Header ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: kBrandOlive.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: kBrandOlive.withOpacity(0.2), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: initials.isNotEmpty
                          ? Text(
                        initials,
                        style: const TextStyle(color: kBrandBrown, fontSize: 20, fontWeight: FontWeight.w900),
                      )
                          : Icon(
                        isTertiary ? Icons.account_balance : Icons.school,
                        color: kBrandBrown,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (school['name'] ?? '').toUpperCase(),
                            style: const TextStyle(color: kBrandBrown, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                school['code'] ?? '',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? kBrandOlive.withOpacity(0.1) : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isActive ? kBrandOlive.withOpacity(0.2) : Colors.red.shade100),
                                ),
                                child: Text(
                                  school['status']?.toUpperCase() ?? '',
                                  style: TextStyle(
                                    color: isActive ? kBrandOlive : Colors.red.shade800,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              ),

              // ---------------- Body ----------------
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _badge(Icons.layers, school['level'] ?? ''),
                          _badge(Icons.account_balance, school['type'] ?? ''),
                          _badge(Icons.wc, school['genderPolicy'] ?? ''),
                        ],
                      ),
                      if ((school['description'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          school['description']!,
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
                        ),
                      ],
                      const SizedBox(height: 24),

                      _sectionTitle("Institutional Profile"),
                      _infoRow("Education Level", school['level'] ?? '', Icons.layers_outlined),
                      _infoRow("Agency Type", school['type'] ?? '', Icons.account_balance_outlined),
                      _infoRow("Gender Policy", school['genderPolicy'] ?? '', Icons.wc_outlined),

                      _sectionTitle("Location"),
                      _infoRow("Region", school['region'] ?? '', Icons.map_outlined),
                      _infoRow("District", school['district'] ?? '', Icons.my_location_outlined),
                      _infoRow("Address", school['address'] ?? '', Icons.home_outlined),
                      _infoRow("Postal", school['postal'] ?? '', Icons.local_post_office_outlined),

                      _sectionTitle("School Contacts"),
                      _infoRow("Phone", school['phone'] ?? '', Icons.phone_outlined),
                      _infoRow("Alt. Phone", school['altPhone'] ?? '', Icons.phone_android_outlined),
                      _infoRow("Email", school['email'] ?? '', Icons.email_outlined),
                      _infoRow("Website", school['website'] ?? '', Icons.language_outlined),

                      _sectionTitle("Administrator"),
                      _infoRow("Name", school['adminName'] ?? '', Icons.badge_outlined),
                      _infoRow("Role", school['adminRole'] ?? '', Icons.work_outline),
                      _infoRow("Phone", school['adminPhone'] ?? '', Icons.contact_phone_outlined),
                      _infoRow("Email", school['adminEmail'] ?? '', Icons.contact_mail_outlined),

                      if ((school['notes'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle("Notes"),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            school['notes']!,
                            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800, height: 1.4),
                          ),
                        ),
                      ],
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportProfileToExcel,
                            icon: const Icon(Icons.table_view_rounded, size: 16),
                            label: const Text("Excel", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _exportProfileToPDF,
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text("PDF", style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onToggleStatus();
                              setState(() {}); // reflect new status immediately in this dialog
                            },
                            icon: Icon(
                              isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                              size: 18,
                              color: isActive ? kBrandOrange : kBrandOlive,
                            ),
                            label: Text(
                              isActive ? "Deactivate" : "Activate",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? kBrandOrange : kBrandOlive),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(color: (isActive ? kBrandOrange : kBrandOlive).withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text("Close"),
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
                          child: ElevatedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text("Edit School"),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// EDIT SCHOOL POP-UP
// ============================================================

class EditSchoolDialog extends StatefulWidget {
  final Map<String, dynamic> school;

  const EditSchoolDialog({super.key, required this.school});

  @override
  State<EditSchoolDialog> createState() => _EditSchoolDialogState();
}

class _EditSchoolDialogState extends State<EditSchoolDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _postalController;
  late TextEditingController _websiteController;
  late TextEditingController _adminNameController;
  late TextEditingController _adminRoleController;
  late TextEditingController _adminPhoneController;
  late TextEditingController _adminEmailController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String? _selectedLevel;
  String? _selectedType;
  String? _selectedGenderType;
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedStatus;

  final List<String> _schoolLevels = [
    'Primary School',
    'Secondary School',
    'High School',
    'Tertiary / University',
    'Vocational Training Center',
  ];

  final List<String> _schoolTypes = [
    'Public / Government',
    'Private',
    'Community Day (CDSS)',
    'Grant-Aided',
    'Mission / Religious School',
  ];

  final List<String> _genderTypes = [
    'Co-educational (Mixed)',
    'Boys Only',
    'Girls Only',
  ];

  final List<String> _regions = [
    'Northern Region',
    'Central Region',
    'Southern Region',
  ];

  final List<String> _statuses = ['Active', 'Inactive'];

  final Map<String, List<String>> _regionDistricts = {
    'Northern Region': [
      'Chitipa',
      'Karonga',
      'Likoma',
      'Mzimba',
      'Nkhata Bay',
      'Rumphi',
    ],
    'Central Region': [
      'Dedza',
      'Dowa',
      'Kasungu',
      'Lilongwe',
      'Mchinji',
      'Nkhotakota',
      'Ntcheu',
      'Ntchisi',
      'Salima',
    ],
    'Southern Region': [
      'Balaka',
      'Blantyre',
      'Chikwawa',
      'Chiradzulu',
      'Machinga',
      'Mangochi',
      'Mulanje',
      'Mwanza',
      'Neno',
      'Nsanje',
      'Phalombe',
      'Thyolo',
      'Zomba',
    ],
  };

  @override
  void initState() {
    super.initState();
    final args = widget.school;

    _nameController = TextEditingController(text: args['name'] ?? '');
    _codeController = TextEditingController(text: args['code'] ?? '');
    _addressController = TextEditingController(text: args['address'] ?? '');
    _phoneController = TextEditingController(text: args['phone'] ?? '');
    _altPhoneController = TextEditingController(text: args['altPhone'] ?? '');
    _emailController = TextEditingController(text: args['email'] ?? '');
    _postalController = TextEditingController(text: args['postal'] ?? '');
    _websiteController = TextEditingController(text: args['website'] ?? '');
    _adminNameController = TextEditingController(text: args['adminName'] ?? '');
    _adminRoleController = TextEditingController(text: args['adminRole'] ?? '');
    _adminPhoneController = TextEditingController(text: args['adminPhone'] ?? '');
    _adminEmailController = TextEditingController(text: args['adminEmail'] ?? '');
    _descriptionController = TextEditingController(text: args['description'] ?? '');
    _notesController = TextEditingController(text: args['notes'] ?? '');

    _selectedLevel = args['level'];
    if (_selectedLevel != null && !_schoolLevels.contains(_selectedLevel)) {
      _selectedLevel = null;
    }

    _selectedType = args['type'];
    if (_selectedType != null && !_schoolTypes.contains(_selectedType)) {
      _selectedType = null;
    }

    _selectedGenderType = args['genderPolicy'];
    if (_selectedGenderType != null && !_genderTypes.contains(_selectedGenderType)) {
      _selectedGenderType = null;
    }

    _selectedRegion = args['region'];
    if (_selectedRegion != null && !_regions.contains(_selectedRegion)) {
      _selectedRegion = null;
    }

    _selectedDistrict = args['district'];
    if (_selectedRegion != null && _selectedDistrict != null) {
      final dists = _regionDistricts[_selectedRegion] ?? [];
      if (!dists.contains(_selectedDistrict)) {
        _selectedDistrict = null;
      }
    }

    _selectedStatus = args['status'];
    if (_selectedStatus != null && !_statuses.contains(_selectedStatus)) {
      _selectedStatus = 'Active';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _emailController.dispose();
    _postalController.dispose();
    _websiteController.dispose();
    _adminNameController.dispose();
    _adminRoleController.dispose();
    _adminPhoneController.dispose();
    _adminEmailController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> get _activeDistricts {
    if (_selectedRegion == null) return [];
    return _regionDistricts[_selectedRegion] ?? [];
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'level': _selectedLevel ?? '',
        'type': _selectedType ?? '',
        'genderPolicy': _selectedGenderType ?? '',
        'region': _selectedRegion ?? '',
        'district': _selectedDistrict ?? '',
        'address': _addressController.text.trim(),
        'postal': _postalController.text.trim(),
        'phone': _phoneController.text.trim(),
        'altPhone': _altPhoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'adminName': _adminNameController.text.trim(),
        'adminRole': _adminRoleController.text.trim(),
        'adminPhone': _adminPhoneController.text.trim(),
        'adminEmail': _adminEmailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': _selectedStatus ?? widget.school['status'] ?? 'Active',
      };

      try {
        final response = await ApiService.updateSchool(widget.school['id']!, updatedData);
        if (response.statusCode == 200) {
          final s = response.data['data'];
          final updatedSchool = {
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
          };

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Changes to '${updatedSchool['name']}' successfully saved!"),
                backgroundColor: kBrandOlive,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context, updatedSchool);
          }
        }
      } catch (e) {
        debugPrint('Error updating school: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please correct the errors in the form."),
          backgroundColor: kBrandOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, color: kBrandOlive, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown),
            ),
          ],
        ),
        const Divider(height: 16, thickness: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 780 ? screenWidth * 0.94 : 720.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(32, 32, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBrandOlive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: kBrandBrown, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Update Institution Details",
                          style: TextStyle(color: kBrandBrown, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Modifying record for ${widget.school['name'] ?? 'this school'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: School Identity
                      _buildSectionHeader("School Identity Details", Icons.school),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: _fieldDecoration(label: "School Name / Title *", icon: Icons.edit),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter school name" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _codeController,
                              decoration: _fieldDecoration(label: "School Code / ID *", icon: Icons.pin),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter code" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedLevel,
                              decoration: _fieldDecoration(label: "Education Level *", icon: Icons.layers),
                              items: _schoolLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
                              onChanged: (val) => setState(() => _selectedLevel = val),
                              validator: (val) => val == null ? "Select level" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: _fieldDecoration(label: "School Type / Agency *", icon: Icons.account_balance),
                              items: _schoolTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (val) => setState(() => _selectedType = val),
                              validator: (val) => val == null ? "Select type" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGenderType,
                              decoration: _fieldDecoration(label: "Gender Policy *", icon: Icons.wc),
                              items: _genderTypes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _selectedGenderType = val),
                              validator: (val) => val == null ? "Select policy" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: _fieldDecoration(
                                label: "Status *",
                                icon: Icons.toggle_on_outlined,
                              ),
                              items: _statuses.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: s == 'Active' ? kBrandOlive : Colors.red.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Text(s),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedStatus = val),
                              validator: (val) => val == null ? "Select status" : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 2: Location Information
                      _buildSectionHeader("Location Details", Icons.location_on),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRegion,
                              decoration: _fieldDecoration(label: "Region *", icon: Icons.map),
                              items: _regions.map((region) => DropdownMenuItem(value: region, child: Text(region))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRegion = val;
                                  _selectedDistrict = null;
                                });
                              },
                              validator: (val) => val == null ? "Select region" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_selectedRegion),
                              initialValue: _selectedDistrict,
                              decoration: _fieldDecoration(
                                label: "District *",
                                icon: Icons.my_location,
                                enabled: _selectedRegion != null,
                              ),
                              items: _activeDistricts.map((district) => DropdownMenuItem(value: district, child: Text(district))).toList(),
                              onChanged: _selectedRegion == null ? null : (val) => setState(() => _selectedDistrict = val),
                              validator: (val) => val == null ? "Select district" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: _fieldDecoration(label: "Physical Address / Landmarks", icon: Icons.home),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _postalController,
                        decoration: _fieldDecoration(label: "Postal Address", icon: Icons.local_post_office),
                      ),

                      const SizedBox(height: 16),

                      // SECTION 3: School Contact Info
                      _buildSectionHeader("School Contacts", Icons.contact_phone),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Primary Phone *", icon: Icons.phone),
                              validator: (value) => (value == null || value.trim().isEmpty) ? "Enter primary phone" : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _altPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Alternative Phone", icon: Icons.phone_android),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(label: "School Email *", icon: Icons.email),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return "Enter email";
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value.trim())) return "Enter valid email";
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              decoration: _fieldDecoration(label: "Website URL (e.g. www.school.com)", icon: Icons.language),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 4: Headteacher / Administrator Contact
                      _buildSectionHeader("Contact Person / Headteacher", Icons.person),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _adminNameController,
                              decoration: _fieldDecoration(label: "Contact Full Name", icon: Icons.badge),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminRoleController,
                              decoration: _fieldDecoration(label: "Designation (e.g. Principal)", icon: Icons.work),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _adminPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(label: "Contact Phone", icon: Icons.contact_phone),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _adminEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(label: "Contact Email", icon: Icons.contact_mail),
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                  if (!emailRegex.hasMatch(value.trim())) return "Enter valid email";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // SECTION 5: Additional Info & Description
                      _buildSectionHeader("Additional Information", Icons.info_outline),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: _fieldDecoration(label: "Details / Description", icon: Icons.description),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: _fieldDecoration(label: "Additional Notes", icon: Icons.info),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
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
