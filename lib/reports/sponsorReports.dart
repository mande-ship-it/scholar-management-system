import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

class SponsorReportsComponent extends StatefulWidget {
  const SponsorReportsComponent({super.key});

  @override
  State<SponsorReportsComponent> createState() => _SponsorReportsComponentState();
}

class _SponsorReportsComponentState extends State<SponsorReportsComponent> {
  String _selectedRegion = 'All Regions';

  @override
  Widget build(BuildContext context) {
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
              _metricCard("Active Sponsors", "18", kBrandOrange, Icons.volunteer_activism_rounded),
              const SizedBox(width: 16),
              _metricCard("Total Funding", "MWK 85.2M", kBrandOlive, Icons.account_balance_wallet_rounded),
              const SizedBox(width: 16),
              _metricCard("Impacted Scholars", "312", kBrandBrown, Icons.auto_awesome_rounded),
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
                  title: "Funding Distribution by Category",
                  child: _buildFundingChart(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Sponsor Types",
                  child: _buildTypeDistribution(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Sponsor List Preview
          _reportSection(
            title: "Major Donors & Contribution Preview",
            child: _buildSponsorTable(),
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
            color: kBrandOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.handshake_rounded, color: kBrandOrange, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sponsor Impact Reports', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Donor contribution tracking and scholar impact analysis.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.email_outlined, size: 18),
          label: const Text("Share with Donors"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBrown,
            foregroundColor: Colors.white,
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
          _dropdownControl("Focus Region", _selectedRegion, ['All Regions', 'USA', 'Malawi', 'International'], (v) => setState(() => _selectedRegion = v!)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
            label: const Text("Filter Results"),
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

  Widget _buildFundingChart() {
    return Column(
      children: [
        _chartBar("Tuition Fees", 0.65, kBrandOlive),
        _chartBar("Scholar Stipends", 0.20, kBrandOrange),
        _chartBar("Educational Resources", 0.10, kBrandBrown),
        _chartBar("Admin & Support", 0.05, Colors.grey),
      ],
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
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.grey.shade50),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDistribution() {
    final types = [
      ("Individual", 45, kBrandBrown),
      ("Corporate", 30, kBrandOlive),
      ("Foundation", 25, kBrandOrange),
    ];
    return Column(
      children: types.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: t.$3, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(t.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Text("${t.$2}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSponsorTable() {
    final donors = [
      ("PMI Foundation", "MWK 25.0M", 82, "Annual"),
      ("AGE Africa US", "MWK 18.5M", 64, "Monthly"),
      ("Standard Bank", "MWK 5.2M", 12, "One-time"),
      ("Malawi Government", "MWK 12.0M", 45, "Quarterly"),
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1.2),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Donor Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Contribution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Scholars", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Cycle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...donors.map((d) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(d.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(d.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandOlive))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(d.$3.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _badge(d.$4, Colors.grey.shade50, Colors.grey.shade700)),
          ],
        )).toList(),
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
