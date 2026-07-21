import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import '../services/api_service.dart';
import 'school_dialogs.dart';

class SchoolProfileComponent extends StatefulWidget {
  const SchoolProfileComponent({super.key});

  @override
  State<SchoolProfileComponent> createState() => _SchoolProfileComponentState();
}

class _SchoolProfileComponentState extends State<SchoolProfileComponent> {
  bool _isLoading = true;
  Map<String, dynamic>? _schoolData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_schoolData == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String? id = args?['id'];
      if (id != null) {
        _fetchSchoolDetails(id);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSchoolDetails(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSchoolById(id);
      if (response.statusCode == 200) {
        setState(() {
          _schoolData = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching school details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final data = _schoolData;
    if (data == null) {
      return const Center(child: Text("School details not found."));
    }

    final String name = data['name'] ?? 'N/A';
    final String code = data['code'] ?? 'N/A';
    final String type = data['type'] ?? 'N/A';
    final String genderPolicy = data['gender_policy'] ?? 'N/A';
    final String region = data['region'] ?? 'N/A';
    final String district = data['district'] ?? 'N/A';
    final String address = data['address'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String website = data['website'] ?? 'N/A';
    final String adminName = data['admin_name'] ?? 'N/A';
    final String adminRole = data['admin_role'] ?? 'N/A';
    final String adminPhone = data['admin_phone'] ?? 'N/A';
    final String description = data['description'] ?? '';
    final String notes = data['notes'] ?? '';
    final String status = data['status'] ?? 'Active';

    final bool isActive = status == 'Active';

    // --- School Statistics from backend ---
    final stats = data['stats'] ?? {};
    final int scholarsCount = stats['totalScholars'] ?? 0;
    final double schoolAvg = double.tryParse(stats['averageMarks']?.toString() ?? '0.0') ?? 0.0;
    final band = performanceBand(schoolAvg);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Summary (Clean)
          _buildSectionContainer(
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge("CODE: $code", Colors.grey.shade100, Colors.grey.shade700),
                          const SizedBox(width: 8),
                          _badge(status, isActive ? Colors.green.shade50 : Colors.red.shade50, isActive ? Colors.green.shade700 : Colors.red.shade700),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Statistics Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: _statCard("Total Scholars", "$scholarsCount", Colors.blue, Icons.people_outline_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _statCard("Overall Avg", "${schoolAvg.toStringAsFixed(1)}%", band.color, Icons.auto_graph_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _statCard("Performance", band.label, band.color, Icons.stars_outlined)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. School Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionContainer(
                  title: "Location Details",
                  icon: Icons.location_on_outlined,
                  child: Column(
                    children: [
                      _infoRow(Icons.map_outlined, "Region", region),
                      _infoRow(Icons.my_location_outlined, "District", district),
                      _infoRow(Icons.home_outlined, "Physical Address", address),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSectionContainer(
                  title: "Contact Info",
                  icon: Icons.contact_phone_outlined,
                  child: Column(
                    children: [
                      _infoRow(Icons.phone_outlined, "Primary Phone", phone),
                      _infoRow(Icons.email_outlined, "Email Address", email),
                      _infoRow(Icons.language_outlined, "Website", website),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Administration
          _buildSectionContainer(
            title: "Administration",
            icon: Icons.person_outline,
            child: Row(
              children: [
                Expanded(child: _infoListTile("Contact Person", adminName, isHighlight: true)),
                Expanded(child: _infoListTile("Role / Designation", adminRole)),
                Expanded(child: _infoListTile("Direct Phone", adminPhone)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Policy & Notes
          _buildSectionContainer(
            title: "Additional Information",
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _infoListTile("Gender Policy", genderPolicy)),
                    Expanded(child: _infoListTile("Agency Type", type)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text("Profile Description", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(fontSize: 14, height: 1.5, color: kBrandBrown)),
                const SizedBox(height: 24),
                const Text("Internal Notes", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(notes, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 6. Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final updatedSchool = await showDialog<Map<String, dynamic>>(
                    context: context,
                    barrierDismissible: false,
                    builder: (editContext) => EditSchoolDialog(school: data),
                  );
                  if (updatedSchool != null) {
                    _fetchSchoolDetails(updatedSchool['id']!);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Edit School"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  side: const BorderSide(color: Colors.blue),
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete School"),
                      content: Text("Are you sure you want to delete $name? This action cannot be undone."),
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
                      final response = await ApiService.deleteSchool(data['id'].toString());
                      if (response.statusCode == 200) {
                        if (mounted) {
                          Navigator.pop(context); // Go back after delete
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("School deleted successfully."), backgroundColor: Colors.red),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error deleting school: $e');
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text("Delete School"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child, String? title, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: Colors.green), const SizedBox(width: 8)],
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
              ],
            ),
            const SizedBox(height: 20),
          ],
          child,
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

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoListTile(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isHighlight ? 16 : 14, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600, color: kBrandBrown)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
