import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'view_scholars.dart'; // To access showEditScholarDialog

class ScholarProfileComponent extends StatefulWidget {
  final String? scholarId;
  final VoidCallback? onBack;
  const ScholarProfileComponent({super.key, this.scholarId, this.onBack});

  @override
  State<ScholarProfileComponent> createState() => _ScholarProfileComponentState();
}

class _ScholarProfileComponentState extends State<ScholarProfileComponent> {
  int _selectedTab = 0; // 0 = Overview, 1 = Academic Stats
  bool _isLoading = true;
  Student? _student;
  Map<String, dynamic>? _extraData;
  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    if (widget.scholarId != null) {
      _fetchScholarData(widget.scholarId!, null);
    }
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

  @override
  void didUpdateWidget(ScholarProfileComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scholarId != null && widget.scholarId != oldWidget.scholarId) {
      _fetchScholarData(widget.scholarId!, null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_student == null && widget.scholarId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String id = args?['id'] ?? 's1';
      _fetchScholarData(id, args);
    }
  }

  Future<void> _fetchScholarData(String id, Map<String, dynamic>? args) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getScholarById(id);
      if (response.statusCode == 200) {
        final item = response.data['data'];
        _student = Student(
          id: item['id'].toString(),
          scholarId: item['scholar_id'] ?? 'N/A',
          name: item['full_name'],
          age: item['dob'] != null ? DateTime.now().year - DateTime.parse(item['dob']).year : 16,
          schoolType: item['school_type'] == 'University' || item['schoolType'] == 'University' ? SchoolType.university : SchoolType.secondary,
          schoolName: item['display_school_name'] ?? 'N/A',
          currentClass: item['academic_year'] ?? 'N/A',
          status: item['status'] ?? 'Active',
          district: item['district'] ?? 'N/A',
          village: item['village'] ?? 'N/A',
          donor: item['donor'] ?? 'N/A',
          phone: item['phone'] ?? 'N/A',
          email: item['email'] ?? 'N/A',
          sex: item['sex'] ?? 'Female',
          dob: item['dob'] ?? '',
          programType: item['program_type'] ?? '',
          programName: item['program_name'] ?? 'N/A',
          previousSchool: item['previous_school'] ?? 'N/A',
          startYear: item['start_year']?.toString() ?? '2026',
          endYear: item['end_year']?.toString() ?? '2030',
          registeredClass: item['registeredClass'] ?? item['registered_class'],
          programStartYearLabel: item['programStartYearLabel'] ?? item['program_start_year_label'],
          programDurationYears: item['programDurationYears'] ?? item['program_duration_years'] ?? 4,
          yearsCompleted: item['yearsCompleted'] ?? item['years_completed'] ?? 0,
          flag: item['flag'],
          guardianName: item['guardian_name'],
          guardianPhone: item['guardian_phone'],
          guardianEmail: item['guardian_email'],
          guardianRelation: item['guardian_relation'],
          guardianOccupation: item['guardian_occupation'],
          progressionStatus: item['progression_status'] ?? 'Pending',
          progressionHistory: item['progression_history'] ?? [],
          yearsRemaining: item['years_remaining'] ?? 0,
        );
        
        _extraData = {
          'id': _student!.id,
          'scholarId': _student!.scholarId,
          'class': _student!.currentClass,
          'sex': _student!.sex,
          'dob': _student!.dob,
          'phone': _student!.phone,
          'district': _student!.district,
          'village': _student!.village,
          'donor': _student!.donor,
          'status': _student!.status,
          'guardianName': _student!.guardianName,
          'guardianPhone': _student!.guardianPhone,
          'guardianRelation': _student!.guardianRelation,
          'progressionStatus': _student!.progressionStatus,
          'yearsRemaining': _student!.yearsRemaining,
        };

        // Fetch academic results
        final resultsRes = await ApiService.getResultsByScholar(id);
        if (resultsRes.statusCode == 200) {
          final List<dynamic> rData = resultsRes.data['data'];
          setState(() {
            kResults.removeWhere((r) => r.studentId == id);
            for (var rItem in rData) {
              kResults.add(ResultRecord(
                studentId: rItem['scholar_id'].toString(),
                code: rItem['subject_code'] ?? 'N/A',
                subject: rItem['subject_name'] ?? 'N/A',
                marks: double.parse(rItem['marks'].toString()),
                gpa: rItem['gpa'] != null ? double.parse(rItem['gpa'].toString()) : null,
                points: rItem['points'] != null ? double.parse(rItem['points'].toString()) : null,
                year: rItem['academic_year'].toString(),
                term: rItem['term'],
                semester: rItem['semester'],
              ));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching scholar profile data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScholar() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Scholar"),
        content: Text("Are you sure you want to delete ${_student?.name}? This action cannot be undone."),
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

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService.deleteScholar(_student!.id);
        if (response.statusCode != null && response.statusCode! < 400) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Scholar deleted successfully."), backgroundColor: Colors.red),
            );
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context, true); // Go back with success flag
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['message'] ?? "Failed to delete scholar.")),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting scholar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: kBrandOlive)));
    }
    
    if (_student == null) {
      return const Center(child: Text("Scholar not found."));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(_student!, _extraData, isMobile),
          const SizedBox(height: 24),
          _buildTabBar(isMobile),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
              child: _buildTabContent(_student!, _extraData, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Student student, Map<String, dynamic>? args, bool isMobile) {
    final String status = args?['status'] ?? 'Active';
    final bool isActive = status == 'Active';

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kBrandOlive.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  student.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandOlive),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge("ID: ${student.scholarId}", Colors.grey.shade100, Colors.grey.shade600),
                        _badge(status, isActive ? Colors.green.shade50 : Colors.red.shade50, isActive ? Colors.green.shade700 : Colors.red.shade700),
                        if (student.flag != null)
                          _badge(student.flag!, Colors.orange.shade50, Colors.orange.shade900),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _headerActionBtn(Icons.auto_awesome_rounded, "Ask AI", kBrandOlive, () => Scaffold.of(context).openEndDrawer()),
                if (['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole)) ...[
                  const SizedBox(width: 8),
                  _headerActionBtn(Icons.edit_outlined, "Edit", kBrandBrown, () {
                    final scholarMap = _getScholarMap(student);
                    showEditScholarDialog(context, scholarMap).then((_) => _fetchScholarData(student.id, null));
                  }),
                  const SizedBox(width: 8),
                  _headerActionBtn(Icons.delete_outline_rounded, "Delete", Colors.red, _deleteScholar, isOutlined: true),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kBrandOlive.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBrandOlive),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge("Scholar ID: ${student.scholarId}", Colors.grey.shade100, Colors.grey.shade600),
                    const SizedBox(width: 8),
                    _badge(status, isActive ? Colors.green.shade50 : Colors.red.shade50, isActive ? Colors.green.shade700 : Colors.red.shade700),
                    if (student.flag != null) ...[
                      const SizedBox(width: 8),
                      _badge(student.flag!, Colors.orange.shade50, Colors.orange.shade900),
                    ],
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text("Ask AI"),
            style: OutlinedButton.styleFrom(
              foregroundColor: kBrandOlive,
              side: const BorderSide(color: kBrandOlive),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          if (['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole))
            OutlinedButton.icon(
              onPressed: _deleteScholar,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text("Delete"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          if (['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole))
            const SizedBox(width: 12),
          if (['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole))
            ElevatedButton.icon(
              onPressed: () {
              final scholarMap = _getScholarMap(student);
              showEditScholarDialog(context, scholarMap).then((_) {
                _fetchScholarData(student.id, null);
              });
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text("Edit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getScholarMap(Student student) {
    return {
      'id': student.id,
      'scholarId': student.scholarId,
      'name': student.name,
      'schoolType': student.schoolType == SchoolType.secondary ? 'Secondary' : 'University',
      'school': student.schoolName,
      'class': student.currentClass,
      'status': student.status,
      'district': student.district,
      'donor': student.donor,
      'sex': student.sex,
      'dob': student.dob,
      'village': student.village,
      'phone': student.phone,
      'email': student.email,
      'programType': student.programType,
      'programName': student.programName,
      'previousSchool': student.previousSchool,
      'startYear': student.startYear,
      'endYear': student.endYear,
    };
  }

  Widget _headerActionBtn(IconData icon, String label, Color color, VoidCallback onTap, {bool isOutlined = false}) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildTabBar(bool isMobile) {
    final items = [
      ("Overview", Icons.person_outline_rounded),
      ("Academic", Icons.auto_graph_rounded),
      ("Progression", Icons.trending_up_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index].$2, size: 18, color: isSelected ? kBrandOlive : Colors.grey),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      Text(
                        items[index].$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? kBrandBrown : Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(Student student, Map<String, dynamic>? args, bool isMobile) {
    switch (_selectedTab) {
      case 0: return _buildOverviewTab(student, args, isMobile);
      case 1: return _buildStatisticsTab(student, isMobile);
      case 2: return _buildProgressionTab(student, isMobile);
      default: return const SizedBox();
    }
  }

  Widget _buildProgressionTab(Student student, bool isMobile) {
    return Column(
      children: [
        _infoSection(
          title: "Current Progression Status",
          icon: Icons.track_changes_rounded,
          child: Column(
            children: [
              if (isMobile) ...[
                _infoTile("Progression State", student.progressionStatus, isBold: true),
                const SizedBox(height: 16),
                _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years"),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Progression State", student.progressionStatus, isBold: true)),
                    Expanded(child: _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years")),
                  ],
                ),
              ],
              const Divider(height: 32),
              const Text(
                "Note: Scholars are automatically promoted based on their term/semester averages. A minimum of 50% is required to move to the next class.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoSection(
          title: "Academic Milestone History",
          icon: Icons.history_rounded,
          child: Column(
            children: [
              if (student.progressionHistory.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("No progression history recorded yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                )
              else
                ...student.progressionHistory.map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Year: ${h['year']}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                          _badge(
                            h['result'],
                            h['result'] == 'Moved' ? Colors.green.shade50 : Colors.red.shade50,
                            h['result'] == 'Moved' ? Colors.green.shade700 : Colors.red.shade700
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        _infoTile("From", h['from_class']),
                        const SizedBox(height: 8),
                        _infoTile("To", h['to_class']),
                        const SizedBox(height: 8),
                        _infoTile("Avg", "${h['average']}%"),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: _infoTile("From", h['from_class'])),
                            Expanded(child: _infoTile("To", h['to_class'])),
                            Expanded(child: _infoTile("Avg", "${h['average']}%")),
                          ],
                        ),
                      ],
                      if (h['ai_insight'] != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 16, color: kBrandOlive),
                            const SizedBox(width: 8),
                            const Text("AI Insight", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandOlive)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(h['ai_insight'], style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                      ],
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(Student student, Map<String, dynamic>? args, bool isMobile) {
    return Column(
      children: [
        _infoSection(
          title: "Institutional Affiliation",
          icon: Icons.school_outlined,
          child: Column(
            children: [
              _infoTile("Current Institution", student.schoolName, isBold: true),
              const Divider(height: 32),
              if (isMobile) ...[
                _infoTile("Relative Year", student.calculatedRelativeYear),
                const SizedBox(height: 16),
                _infoTile("Current Label", student.calculatedAcademicYear),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Relative Year", student.calculatedRelativeYear)),
                    Expanded(child: _infoTile("Current Label", student.calculatedAcademicYear)),
                  ],
                ),
              ],
              const Divider(height: 32),
              if (isMobile) ...[
                _infoTile("Program Duration", "${student.programDurationYears} Years"),
                const SizedBox(height: 16),
                _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years"),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Program Duration", "${student.programDurationYears} Years")),
                    Expanded(child: _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years")),
                  ],
                ),
              ],
              const Divider(height: 32),
              if (isMobile) ...[
                _infoTile("Previous School", student.previousSchool),
                const SizedBox(height: 16),
                _infoTile("Qualification", student.programType.isNotEmpty ? student.programType : 'N/A'),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Previous School", student.previousSchool)),
                    Expanded(child: _infoTile("Qualification", student.programType.isNotEmpty ? student.programType : 'N/A')),
                  ],
                ),
              ],
              if (student.schoolType == SchoolType.university) ...[
                const Divider(height: 32),
                _infoTile("Program of Study", student.programName, isBold: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isMobile) ...[
          _infoSection(
            title: "Personal Details",
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                _infoRow(Icons.wc, "Sex", args?['sex'] ?? 'Female'),
                _infoRow(Icons.cake_outlined, "DOB", args?['dob'] ?? '2009-05-12'),
                _infoRow(Icons.phone_outlined, "Phone", args?['phone'] ?? '+265 888 123 456'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoSection(
            title: "Home & Origin",
            icon: Icons.map_outlined,
            child: Column(
              children: [
                _infoRow(Icons.location_on_outlined, "District", args?['district'] ?? 'Mzimba'),
                _infoRow(Icons.home_outlined, "Village", args?['village'] ?? 'Chilinde'),
                _infoRow(Icons.volunteer_activism_outlined, "Donor", args?['donor'] ?? 'PMI'),
              ],
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _infoSection(
                  title: "Personal Details",
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      _infoRow(Icons.wc, "Sex", args?['sex'] ?? 'Female'),
                      _infoRow(Icons.cake_outlined, "DOB", args?['dob'] ?? '2009-05-12'),
                      _infoRow(Icons.phone_outlined, "Phone", args?['phone'] ?? '+265 888 123 456'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _infoSection(
                  title: "Home & Origin",
                  icon: Icons.map_outlined,
                  child: Column(
                    children: [
                      _infoRow(Icons.location_on_outlined, "District", args?['district'] ?? 'Mzimba'),
                      _infoRow(Icons.home_outlined, "Village", args?['village'] ?? 'Chilinde'),
                      _infoRow(Icons.volunteer_activism_outlined, "Donor", args?['donor'] ?? 'PMI'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _infoSection(
          title: "Parent / Guardian Information",
          icon: Icons.family_restroom_outlined,
          child: Column(
            children: [
              _infoTile("Primary Guardian", student.guardianName ?? 'Not Provided', isBold: true),
              const Divider(height: 32),
              if (isMobile) ...[
                _infoTile("Relationship", student.guardianRelation ?? 'N/A'),
                const SizedBox(height: 16),
                _infoTile("Phone", student.guardianPhone ?? 'N/A'),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Relationship", student.guardianRelation ?? 'N/A')),
                    Expanded(child: _infoTile("Phone", student.guardianPhone ?? 'N/A')),
                  ],
                ),
              ],
              if (student.guardianEmail != null || student.guardianOccupation != null) ...[
                const Divider(height: 32),
                if (isMobile) ...[
                  _infoTile("Email", student.guardianEmail ?? 'N/A'),
                  const SizedBox(height: 16),
                  _infoTile("Occupation", student.guardianOccupation ?? 'N/A'),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _infoTile("Email", student.guardianEmail ?? 'N/A')),
                      Expanded(child: _infoTile("Occupation", student.guardianOccupation ?? 'N/A')),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab(Student student, bool isMobile) {
    final records = kResults.where((r) => r.studentId == student.id).toList();
    final double avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
    final band = performanceBand(avg);
    
    final bestResult = records.isEmpty ? null : records.reduce((a, b) => a.marks > b.marks ? a : b);
    
    double totalGpa = 0;
    if (student.schoolType == SchoolType.university && records.isNotEmpty) {
      final gpaRecords = records.where((r) => r.gpa != null).toList();
      if (gpaRecords.isNotEmpty) {
        totalGpa = gpaRecords.map((r) => r.gpa!).reduce((a, b) => a + b) / gpaRecords.length;
      }
    }

    if (isMobile) {
      return Column(
        children: [
          _statCard("Average Mark", "${avg.toStringAsFixed(1)}%", band.color, Icons.analytics_rounded, true),
          const SizedBox(height: 12),
          if (student.schoolType == SchoolType.university) ...[
            _statCard("Cumulative GPA", totalGpa.toStringAsFixed(2), kBrandOlive, Icons.school_rounded, true),
            const SizedBox(height: 12),
          ],
          _statCard("Standing", band.label, band.color, Icons.stars_rounded, true),
          const SizedBox(height: 12),
          _statCard("Best Subject", bestResult?.subject ?? 'N/A', kBrandOlive, Icons.emoji_events_outlined, true),
          const SizedBox(height: 12),
          _statCard("Total Records", "${records.length}", kBrandBrown, Icons.inventory_2_outlined, true),
          const SizedBox(height: 24),
          _buildPerformanceBreakdown(records),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard("Average Mark", "${avg.toStringAsFixed(1)}%", band.color, Icons.analytics_rounded, false)),
            const SizedBox(width: 16),
            if (student.schoolType == SchoolType.university) ...[
              Expanded(child: _statCard("Cumulative GPA", totalGpa.toStringAsFixed(2), kBrandOlive, Icons.school_rounded, false)),
              const SizedBox(width: 16),
            ],
            Expanded(child: _statCard("Standing", band.label, band.color, Icons.stars_rounded, false)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard("Best Subject", bestResult?.subject ?? 'N/A', kBrandOlive, Icons.emoji_events_outlined, false)),
            const SizedBox(width: 16),
            Expanded(child: _statCard("Total Records", "${records.length}", kBrandBrown, Icons.inventory_2_outlined, false)),
          ],
        ),
        const SizedBox(height: 24),
        _buildPerformanceBreakdown(records),
      ],
    );
  }

  Widget _buildPerformanceBreakdown(List<ResultRecord> records) {
    return _infoSection(
      title: "Subject Performance Breakdown",
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("No academic records found for this scholar.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          else
            ...records.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(r.subject, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown), overflow: TextOverflow.ellipsis)),
                      Text("${r.marks.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: r.marks >= 50 ? kBrandOlive : Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: r.marks / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      color: r.marks >= 80 ? Colors.green : (r.marks >= 50 ? kBrandOlive : Colors.orange),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon, bool isFullWidth) {
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }


  Widget _infoSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kBrandOlive),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: kBrandBrown)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
