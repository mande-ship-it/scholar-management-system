import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

class ScholarStatsComponent extends StatefulWidget {
  const ScholarStatsComponent({super.key});

  @override
  State<ScholarStatsComponent> createState() => _ScholarStatsComponentState();
}

class _ScholarStatsComponentState extends State<ScholarStatsComponent> {
  @override
  Widget build(BuildContext context) {
    final totalScholars = kStudents.length;
    final universityScholars = kStudents.where((s) => s.schoolType == SchoolType.university).length;
    final secondaryScholars = totalScholars - universityScholars;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- Header (No Banners) ----------------
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.analytics_rounded, color: kBrandOlive, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scholar Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      SizedBox(height: 2),
                      Text('Demographics and enrollment overview of all program scholars.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(indent: 24, endIndent: 24),

          // --- Metric Cards ---
          Row(
            children: [
              _StatMetric(label: "Total Scholars", value: "$totalScholars", icon: Icons.groups_rounded, color: kBrandBrown),
              const SizedBox(width: 16),
              _StatMetric(label: "University", value: "$universityScholars", icon: Icons.account_balance_rounded, color: kBrandOlive),
              const SizedBox(width: 16),
              _StatMetric(label: "Secondary", value: "$secondaryScholars", icon: Icons.school_rounded, color: kBrandOrange),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DistributionSection(
                  title: "Enrollment by Level",
                  items: [
                    (label: "Secondary", value: secondaryScholars, color: kBrandOrange),
                    (label: "University", value: universityScholars, color: kBrandOlive),
                  ],
                  total: totalScholars,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
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
                      const Text("Program Health", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 16)),
                      const SizedBox(height: 24),
                      _HealthIndicator(label: "Retention Rate", value: 0.94, color: kBrandOlive),
                      const SizedBox(height: 16),
                      _HealthIndicator(label: "Attendance Avg", value: 0.88, color: kBrandBrown),
                      const SizedBox(height: 16),
                      _HealthIndicator(label: "Academic Growth", value: 0.76, color: kBrandOrange),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text("Top Participating Schools", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _SchoolListItem(name: "Kamuzu Academy", count: 12, color: kBrandOlive),
                const Divider(height: 1),
                _SchoolListItem(name: "University of Malawi", count: 28, color: kBrandBrown),
                const Divider(height: 1),
                _SchoolListItem(name: "Chichiri Secondary School", count: 8, color: kBrandOrange),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({required this.title, required this.items, required this.total});
  final String title;
  final List<({String label, int value, Color color})> items;
  final int total;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 16)),
          const SizedBox(height: 24),
          ...items.map((item) {
            final percent = total == 0 ? 0.0 : item.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent, 
                      minHeight: 10, 
                      color: item.color, 
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HealthIndicator extends StatelessWidget {
  const _HealthIndicator({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(value: value, strokeWidth: 5, color: color, backgroundColor: Colors.grey.shade100),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text("${(value * 100).toInt()}%", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SchoolListItem extends StatelessWidget {
  const _SchoolListItem({required this.name, required this.count, required this.color});
  final String name;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
      trailing: Text("$count Scholars", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }
}
