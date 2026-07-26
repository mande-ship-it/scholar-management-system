import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class SchoolReportsComponent extends StatefulWidget {
  const SchoolReportsComponent({super.key});

  @override
  State<SchoolReportsComponent> createState() => _SchoolReportsComponentState();
}

class _SchoolReportsComponentState extends State<SchoolReportsComponent> {
  String _selectedLevel = 'All Levels';
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSchoolReport(level: _selectedLevel);
      if (response.statusCode == 200) {
        setState(() {
          _data = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching school report: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final metrics = _data?['metrics'] ?? {};
    final types = _data?['types'] as List? ?? [];
    final standings = _data?['standings'] as List? ?? [];
    final schools = _data?['schools'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 2. Control Row
          _buildControls(),
          
          const SizedBox(height: 24),
          
          // 3. Key Metrics
          Row(
            children: [
              _metricCard("Partner Schools", "${metrics['partner_schools'] ?? 0}", Colors.blue, Icons.business_rounded),
              const SizedBox(width: 16),
              _metricCard("Total Enrollment", "${metrics['total_enrollment'] ?? 0}", kBrandOlive, Icons.groups_rounded),
              const SizedBox(width: 16),
              _metricCard("Pending Fees", "MWK ${metrics['pending_fees'] ?? 0}", kBrandOrange, Icons.warning_amber_rounded),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 4. Main Report Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _reportSection(
                  title: "Institution Distribution by Type",
                  child: _buildTypeChart(types),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "School Standing",
                  child: _buildStandingDistribution(standings),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. School List Preview
          _reportSection(
            title: "School Performance Ranking Preview",
            child: _buildSchoolTable(schools),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.apartment_rounded, color: Colors.blue, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('School Reports', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Institutional monitoring and academic performance comparison.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined),
          label: const Text("Export Excel"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _dropdownControl("Education Level", _selectedLevel, ['All Levels', 'Secondary School', 'Tertiary / University'], (v) {
            setState(() => _selectedLevel = v!);
            _fetchReport();
          }),
          const Spacer(),
          TextButton.icon(
            onPressed: _fetchReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _dropdownControl(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandBrown)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _reportSection({required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildTypeChart(List types) {
    if (types.isEmpty) return const Center(child: Text("No distribution data"));
    return Column(
      children: types.map((t) => _chartBar(
        t['type'] ?? 'Other',
        (double.parse(t['percentage'].toString()) / 100),
        kBrandOlive
      )).toList(),
    );
  }

  Widget _chartBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingDistribution(List standings) {
    if (standings.isEmpty) return const Center(child: Text("No standing data"));
    final List<Color> colors = [Colors.green, kBrandOlive, kBrandOrange, Colors.red];
    return Column(
      children: standings.asMap().entries.map((entry) {
        final s = entry.value;
        final color = colors[entry.key % colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Text(s['standing'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
              Text(s['count'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchoolTable(List schools) {
    if (schools.isEmpty) return const Center(child: Text("No school data"));
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("School Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Avg Mark", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Standing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...schools.map((s) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(s['level'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("${s['avg_mark'] ?? 0}%", style: const TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _badge(s['standing'] ?? 'Satisfactory', s['standing'] == "Excellent" ? Colors.green.shade50 : Colors.white, s['standing'] == "Excellent" ? Colors.green.shade700 : Colors.blue.shade700)),
          ],
        )),
      ],
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
