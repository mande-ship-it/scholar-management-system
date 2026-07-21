import 'package:flutter/material.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class SchoolStatsComponent extends StatefulWidget {
  const SchoolStatsComponent({super.key});

  @override
  State<SchoolStatsComponent> createState() => _SchoolStatsComponentState();
}

class _SchoolStatsComponentState extends State<SchoolStatsComponent> {
  @override
  Widget build(BuildContext context) {
    // Mock data for display
    const totalSchools = 32;
    const secondaryCount = 24;
    const universityCount = 8;
    const totalPartnershipDuration = "8.4 Years";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.apartment_rounded, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        SizedBox(height: 2),
                        Text('Regional distribution of partner institutions.',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Key Metrics ---
                  Row(
                    children: [
                      _StatMetric(label: "Partner Schools", value: "$totalSchools", icon: Icons.domain_rounded, color: kBrandBrown),
                      const SizedBox(width: 16),
                      _StatMetric(label: "Avg. Duration", value: totalPartnershipDuration, icon: Icons.history_rounded, color: kBrandOlive),
                      const SizedBox(width: 16),
                      _StatMetric(label: "Active Scholars", value: "246", icon: Icons.groups_rounded, color: kBrandOrange),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School Level Distribution
                      Expanded(
                        child: _StatCard(
                          title: "Institutional Levels",
                          subtitle: "Breakdown of secondary vs tertiary partners",
                          child: Column(
                            children: [
                              _DistributionBar(label: "Secondary Schools", value: secondaryCount, total: totalSchools, color: kBrandBrown),
                              const SizedBox(height: 12),
                              _DistributionBar(label: "Public Universities", value: universityCount, total: totalSchools, color: kBrandOlive),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Regional Presence
                      Expanded(
                        child: _StatCard(
                          title: "Regional Distribution",
                          subtitle: "Geographic spread of partner schools",
                          child: Column(
                            children: [
                              _RegionItem(label: "Northern Region", count: 12, percent: 0.38, color: kBrandOlive),
                              const Divider(height: 20),
                              _RegionItem(label: "Central Region", count: 15, percent: 0.46, color: kBrandBrown),
                              const Divider(height: 20),
                              _RegionItem(label: "Southern Region", count: 5, percent: 0.16, color: kBrandOrange),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text("Yearly Onboarding Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  // Simple Growth Chart
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TrendBar(label: "2023", value: 0.4),
                        _TrendBar(label: "2024", value: 0.65),
                        _TrendBar(label: "2025", value: 0.5),
                        _TrendBar(label: "2026", value: 0.85, isCurrent: true),
                      ],
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

class _StatMetric extends StatelessWidget {
  const _StatMetric({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.label, required this.value, required this.total, required this.color});
  final String label;
  final int value, total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text("$value", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: percent, minHeight: 12, color: color, backgroundColor: Colors.grey.shade100),
        ),
      ],
    );
  }
}

class _RegionItem extends StatelessWidget {
  const _RegionItem({required this.label, required this.count, required this.percent, required this.color});
  final String label;
  final int count;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(value: percent, strokeWidth: 4, color: color, backgroundColor: Colors.grey.shade100),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$count Schools", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text("${(percent * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.label, required this.value, this.isCurrent = false});
  final String label;
  final double value;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 140 * value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrent ? [kBrandOrange, kBrandOrange.withValues(alpha: 0.6)] : [kBrandOlive, kBrandOlive.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: kBrandBrown)),
      ],
    );
  }
}
