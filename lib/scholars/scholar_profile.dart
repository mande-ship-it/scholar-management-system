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
        _student = Student.fromMap(item);
        
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
              kResults.add(ResultRecord.fromMap(rItem));
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

  Future<void> _rejectScholar() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Registration"),
        content: Text("Are you sure you want to reject and remove the registration for ${_student?.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final response = await ApiService.rejectActivity('scholar', _student!.id);
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Scholar registration rejected."), backgroundColor: Colors.orange),
            );
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context, true);
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.data['message'] ?? "Rejection failed.")),
            );
          }
        }
      } catch (e) {
        debugPrint('Error rejecting scholar: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  Future<void> _approveScholar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.approveActivity('scholar', _student!.id);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scholar approved successfully!"), backgroundColor: kBrandOlive),
          );
          _fetchScholarData(_student!.id, null);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? "Approval failed.")),
          );
        }
      }
    } catch (e) {
      debugPrint('Error approving scholar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    
    if (_student == null) {
      return const Center(child: Text("Scholar not found."));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        final bool isMobile = constraints.maxWidth < 900;
        final double horizontalPadding = isSmall ? 16 : (isMobile ? 24 : 32);

        return Container(
          color: const Color(0xFFF8F9FA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPortalHero(_student!, _extraData, isSmall, isMobile),
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, isSmall ? 8 : 16, horizontalPadding, 8),
                child: _buildPortalTabBar(isSmall, isMobile),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: _buildTabContent(_student!, _extraData, isSmall, isMobile),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPortalHero(Student student, Map<String, dynamic>? args, bool isSmall, bool isMobile) {
    final String status = args?['status'] ?? 'Active';
    final bool isActive = status == 'Active';
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              _heroAvatar(student, isVerySmall ? 32 : 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name.toUpperCase(), 
                      style: TextStyle(fontSize: isVerySmall ? 13 : 15, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32), letterSpacing: -0.2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text("ID: ${student.scholarId}", style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isVerySmall) _statusIndicator(status, isActive),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                onSelected: (val) {
                   if (val == 'ai') Scaffold.of(context).openEndDrawer();
                   if (val == 'edit') {
                     final scholarMap = _getScholarMap(student);
                     showEditScholarDialog(context, scholarMap).then((_) => _fetchScholarData(student.id, null));
                   }
                   if (val == 'approve') _approveScholar();
                   if (val == 'reject') _rejectScholar();
                   if (val == 'delete') _deleteScholar();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'ai', child: Row(children: [Icon(Icons.auto_awesome, size: 18, color: kBrandOlive), SizedBox(width: 8), Text("AI Assistant")])),
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text("Modify Profile")])),
                  if (student.status == 'Pending' && ['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole)) ...[
                    const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: kBrandOlive), SizedBox(width: 8), Text("Approve")])),
                    const PopupMenuItem(value: 'reject', child: Row(children: [Icon(Icons.close_rounded, size: 18, color: kBrandOrange), SizedBox(width: 8), Text("Reject")])),
                  ],
                  if (['Administrator', 'Program Coordinator', 'Country Director'].contains(_userRole))
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text("Archive / Delete")])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator(String status, bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF9AB334) : const Color(0xFFE05B1C),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _heroAvatar(Student student, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2DB),
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFF9AB334).withOpacity(0.3), width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      alignment: Alignment.center,
      child: Text(
        getInitials(student.name),
        style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w900, color: const Color(0xFF4C3C32)),
      ),
    );
  }

  Widget _heroBadges(Student student, String status, bool isActive) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge("SCHOLAR ID: ${student.scholarId}", Colors.grey.shade100, Colors.grey.shade600),
        _badge(status, isActive ? Color(0xFF9AB334).withOpacity(0.1) : Color(0xFFE05B1C).withOpacity(0.1), 
               isActive ? const Color(0xFF9AB334) : const Color(0xFFE05B1C)),
        if (student.flag != null)
          _badge(student.flag!.toUpperCase(), Color(0xFFE05B1C).withOpacity(0.1), Color(0xFFE05B1C)),
      ],
    );
  }

  Widget _portalActionBtn(IconData icon, String label, Color color, VoidCallback onTap, {bool isOutlined = false, bool compact = false}) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: compact ? 14 : 16),
        label: Text(label, style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 12 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: compact ? 14 : 16),
      label: Text(label, style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPortalTabBar(bool isSmall, bool isMobile) {
    final items = ["OVERVIEW", "TRANSCRIPT", "LEDGER"];
    final fullItems = ["OVERVIEW", "ACADEMIC TRANSCRIPT", "PROGRESSION LEDGER"];
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(items.length, (index) {
            final isSelected = _selectedTab == index;
            return Padding(
              padding: EdgeInsets.only(right: isSmall ? 16 : 32),
              child: InkWell(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: isSelected ? const Border(bottom: BorderSide(color: Color(0xFF9AB334), width: 3)) : null,
                  ),
                  child: Text(
                    isSmall ? items[index] : fullItems[index],
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 12,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF4C3C32) : Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
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

  Widget _buildTabContent(Student student, Map<String, dynamic>? args, bool isSmall, bool isMobile) {
    return Column(
      children: [
        switch (_selectedTab) {
          0 => _buildOverviewTab(student, args, isSmall, isMobile),
          1 => _buildStatisticsTab(student, isSmall, isMobile),
          2 => _buildProgressionTab(student, isSmall, isMobile),
          _ => const SizedBox(),
        },
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProgressionTab(Student student, bool isSmall, bool isMobile) {
    return Column(
      children: [
        _infoSection(
          title: "Current Progression Status",
          icon: Icons.track_changes_rounded,
          isMobile: isMobile,
          isSmall: isSmall,
          child: Column(
            children: [
              if (isSmall || isMobile) ...[
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
              Text(
                "Note: Scholars are automatically promoted based on their term/semester averages. A minimum of 50% is required to move to the next class.",
                style: TextStyle(fontSize: isSmall ? 10 : 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoSection(
          title: "Academic Milestone History",
          icon: Icons.history_rounded,
          isMobile: isMobile,
          isSmall: isSmall,
          child: Column(
            children: [
              if (student.progressionHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text("No progression history recorded yet.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: isSmall ? 11 : 13)),
                )
              else
                ...student.progressionHistory.map((h) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(isSmall ? 12 : 16),
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
                          Text("Year: ${h['year']}", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: isSmall ? 12 : 14)),
                          _badge(
                            h['result'],
                            h['result'] == 'Moved' ? Colors.green.shade50 : Colors.red.shade50,
                            h['result'] == 'Moved' ? Colors.green.shade700 : Colors.red.shade700,
                            isSmall: isSmall
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isSmall || isMobile) ...[
                        _infoTile("From", h['from_class'], isSmall: isSmall),
                        const SizedBox(height: 8),
                        _infoTile("To", h['to_class'], isSmall: isSmall),
                        const SizedBox(height: 8),
                        _infoTile("Avg", "${h['average']}%", isSmall: isSmall),
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
                            Text("AI Insight", style: TextStyle(fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.bold, color: kBrandOlive)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(h['ai_insight'], style: TextStyle(fontSize: isSmall ? 11 : 13, color: Colors.black87, height: 1.4)),
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

  Widget _buildOverviewTab(Student student, Map<String, dynamic>? args, bool isSmall, bool isMobile) {
    return Column(
      children: [
        _infoSection(
          title: "Institutional Affiliation",
          icon: Icons.school_outlined,
          isMobile: isMobile,
          isSmall: isSmall,
          child: Column(
            children: [
              _infoTile("Current Institution", student.schoolName, isBold: true, isSmall: isSmall),
              const Divider(height: 32),
              if (isSmall || isMobile) ...[
                _infoTile("Relative Year", student.calculatedRelativeYear, isSmall: isSmall),
                const SizedBox(height: 16),
                _infoTile("Current Label", student.calculatedAcademicYear, isSmall: isSmall),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Relative Year", student.calculatedRelativeYear)),
                    Expanded(child: _infoTile("Current Label", student.calculatedAcademicYear)),
                  ],
                ),
              ],
              const Divider(height: 32),
              if (isSmall || isMobile) ...[
                _infoTile("Program Duration", "${student.programDurationYears} Years", isSmall: isSmall),
                const SizedBox(height: 16),
                _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years", isSmall: isSmall),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _infoTile("Program Duration", "${student.programDurationYears} Years")),
                    Expanded(child: _infoTile("Years Remaining", "${student.calculatedRemainingYears} Years")),
                  ],
                ),
              ],
              const Divider(height: 32),
              if (isSmall || isMobile) ...[
                _infoTile("Previous School", student.previousSchool, isSmall: isSmall),
                const SizedBox(height: 16),
                _infoTile("Qualification", student.programType.isNotEmpty ? student.programType : 'N/A', isSmall: isSmall),
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
                _infoTile("Program of Study", student.programName, isBold: true, isSmall: isSmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isSmall || isMobile) ...[
          _infoSection(
            title: "Personal Details",
            icon: Icons.badge_outlined,
            isMobile: isMobile,
            isSmall: isSmall,
            child: Column(
              children: [
                _infoRow(Icons.wc, "Sex", args?['sex'] ?? 'Female', isSmall: isSmall),
                _infoRow(Icons.cake_outlined, "DOB", args?['dob'] ?? '2009-05-12', isSmall: isSmall),
                _infoRow(Icons.phone_outlined, "Phone", args?['phone'] ?? '+265 888 123 456', isSmall: isSmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoSection(
            title: "Home & Origin",
            icon: Icons.map_outlined,
            isMobile: isMobile,
            isSmall: isSmall,
            child: Column(
              children: [
                _infoRow(Icons.location_on_outlined, "District", args?['district'] ?? 'Mzimba', isSmall: isSmall),
                _infoRow(Icons.home_outlined, "Village", args?['village'] ?? 'Chilinde', isSmall: isSmall),
                _infoRow(Icons.volunteer_activism_outlined, "Donor", args?['donor'] ?? 'PMI', isSmall: isSmall),
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
          isMobile: isMobile,
          isSmall: isSmall,
          child: Column(
            children: [
              _infoTile("Primary Guardian", student.guardianName ?? 'Not Provided', isBold: true, isSmall: isSmall),
              const Divider(height: 32),
              if (isSmall || isMobile) ...[
                _infoTile("Relationship", student.guardianRelation ?? 'N/A', isSmall: isSmall),
                const SizedBox(height: 16),
                _infoTile("Phone", student.guardianPhone ?? 'N/A', isSmall: isSmall),
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
                if (isSmall || isMobile) ...[
                  _infoTile("Email", student.guardianEmail ?? 'N/A', isSmall: isSmall),
                  const SizedBox(height: 16),
                  _infoTile("Occupation", student.guardianOccupation ?? 'N/A', isSmall: isSmall),
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

  Widget _buildStatisticsTab(Student student, bool isSmall, bool isMobile) {
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

    if (isSmall || isMobile) {
      return Column(
        children: [
          _statCard("Average Mark", "${avg.toStringAsFixed(1)}%", band.color, Icons.analytics_rounded, true, isSmall: isSmall),
          const SizedBox(height: 12),
          if (student.schoolType == SchoolType.university) ...[
            _statCard("Cumulative GPA", totalGpa.toStringAsFixed(2), kBrandOlive, Icons.school_rounded, true, isSmall: isSmall),
            const SizedBox(height: 12),
          ],
          _statCard("Standing", band.label, band.color, Icons.stars_rounded, true, isSmall: isSmall),
          const SizedBox(height: 12),
          _statCard("Best Subject", bestResult?.subject ?? 'N/A', kBrandOlive, Icons.emoji_events_outlined, true, isSmall: isSmall),
          const SizedBox(height: 12),
          _statCard("Total Records", "${records.length}", kBrandBrown, Icons.inventory_2_outlined, true, isSmall: isSmall),
          const SizedBox(height: 24),
          _buildPerformanceBreakdown(records, isSmall, isMobile),
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
        _buildPerformanceBreakdown(records, isSmall, isMobile),
      ],
    );
  }

  Widget _buildPerformanceBreakdown(List<ResultRecord> records, bool isSmall, bool isMobile) {
    return _infoSection(
      title: "Subject Performance",
      icon: Icons.bar_chart_rounded,
      isMobile: isMobile,
      isSmall: isSmall,
      child: Column(
        children: [
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text("No academic records found.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: isSmall ? 11 : 13)),
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
                      Expanded(child: Text(r.subject, style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: isSmall ? 11 : 13), overflow: TextOverflow.ellipsis)),
                      Text("${r.marks.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: r.marks >= 50 ? kBrandOlive : Colors.red, fontSize: isSmall ? 11 : 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: r.marks / 100,
                      minHeight: isSmall ? 6 : 8,
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

  Widget _statCard(String label, String value, Color color, IconData icon, bool isFullWidth, {bool isSmall = false}) {
    Widget card = Container(
      padding: EdgeInsets.all(isSmall ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isSmall ? 16 : 20),
          SizedBox(height: isSmall ? 8 : 12),
          Text(value, style: TextStyle(fontSize: isSmall ? 13 : 16, fontWeight: FontWeight.bold, color: kBrandBrown), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: isSmall ? 8 : 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }


  Widget _infoSection({required String title, required IconData icon, required Widget child, bool isMobile = false, bool isSmall = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 16 : (isMobile ? 20 : 32)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 10),
                decoration: BoxDecoration(
                  color: Color(0xFF9AB334).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: isSmall ? 16 : 20, color: const Color(0xFF9AB334)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.toUpperCase(), 
                  style: TextStyle(
                    fontSize: isSmall ? 9 : 12, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF4C3C32), 
                    letterSpacing: 1.0
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 20 : 32),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool isBold = false, bool isSmall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(), 
          style: TextStyle(color: Colors.grey.shade400, fontSize: isSmall ? 8 : 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)
        ),
        const SizedBox(height: 6),
        Text(
          value, 
          style: TextStyle(
            fontSize: isBold ? (isSmall ? 14 : 16) : (isSmall ? 12 : 14), 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, 
            color: const Color(0xFF4C3C32),
            letterSpacing: -0.2
          )
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 16 : 24.0),
      child: Row(
        children: [
          Icon(icon, size: isSmall ? 16 : 18, color: Colors.grey.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(), 
                  style: TextStyle(color: Colors.grey.shade400, fontSize: isSmall ? 8 : 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                ),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.w700, color: Color(0xFF4C3C32))
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.bold)),
    );
  }


}