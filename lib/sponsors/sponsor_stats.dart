import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class SponsorStatsComponent extends StatefulWidget {
  const SponsorStatsComponent({super.key});

  @override
  State<SponsorStatsComponent> createState() => _SponsorStatsComponentState();
}

class _SponsorStatsComponentState extends State<SponsorStatsComponent> {
  bool _isLoading = true;
  int _totalSponsors = 0;
  double _totalFunding = 0;
  List<Map<String, dynamic>> _tierDistribution = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getSponsorStats();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _totalSponsors = data['totalSponsors'];
          _totalFunding = double.parse(data['totalFunding'].toString());
          _tierDistribution = List<Map<String, dynamic>>.from(data['tierDistribution']);
        });
      }
    } catch (e) {
      debugPrint('Error fetching sponsor stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return "MWK ${(amount / 1000000).toStringAsFixed(1)}M";
    }
    return "MWK ${(amount / 1000).toStringAsFixed(0)}K";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: kBrandOlive)));

    final averageSponsorship = _totalSponsors > 0 ? _totalFunding / _totalSponsors : 0.0;

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
                    child: const Icon(Icons.volunteer_activism_rounded, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sponsor Statistics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        SizedBox(height: 2),
                        Text('Overview of donor contributions and sponsorship impact.',
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
                      _StatMetric(label: "Total Sponsors", value: "$_totalSponsors", icon: Icons.handshake_rounded, color: kBrandBrown),
                      const SizedBox(width: 16),
                      _StatMetric(label: "Total Funding", value: _formatAmount(_totalFunding), icon: Icons.payments_rounded, color: kBrandOlive),
                      const SizedBox(height: 16),
                      _StatMetric(label: "Avg. per Donor", value: _formatAmount(averageSponsorship), icon: Icons.analytics_rounded, color: kBrandOrange),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Funding Tiers Breakdown
                      Expanded(
                        child: _StatCard(
                          title: "Sponsorship Tiers",
                          subtitle: "Distribution of partners by tier",
                          child: Column(
                            children: _tierDistribution.map((t) {
                              final count = int.parse(t['count'].toString());
                              final percent = _totalSponsors > 0 ? count / _totalSponsors : 0.0;
                              return _DonorProgress(
                                label: t['sponsorship_type'], 
                                percent: percent, 
                                amount: "$count", 
                                color: kBrandOlive
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Sustainability Health
                      Expanded(
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
                              const Text("Sponsorship Health", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                              const SizedBox(height: 20),
                              _HealthGauge(label: "Donor Retention", value: 0.92, color: kBrandOlive),
                              const SizedBox(height: 16),
                              _HealthGauge(label: "Target Achievement", value: 0.78, color: kBrandOrange),
                              const SizedBox(height: 16),
                              _HealthGauge(label: "Multi-year Pledges", value: 0.65, color: kBrandBrown),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text("Sponsorship Growth Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
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
                        _GrowthBar(label: "Q1", value: 0.5),
                        _GrowthBar(label: "Q2", value: 0.7),
                        _GrowthBar(label: "Q3", value: 0.45),
                        _GrowthBar(label: "Q4", value: 0.82, isCurrent: true),
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
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
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

class _DonorProgress extends StatelessWidget {
  const _DonorProgress({required this.label, required this.percent, required this.amount, required this.color});
  final String label, amount;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.grey.shade100),
          ),
        ],
      ),
    );
  }
}

class _HealthGauge extends StatelessWidget {
  const _HealthGauge({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(value: value, strokeWidth: 4, color: color, backgroundColor: Colors.grey.shade100),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text("${(value * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthBar extends StatelessWidget {
  const _GrowthBar({required this.label, required this.value, this.isCurrent = false});
  final String label;
  final double value;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: 140 * value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCurrent ? [kBrandOrange, kBrandOrange.withValues(alpha: 0.6)] : [kBrandOlive, kBrandOlive.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: kBrandBrown)),
      ],
    );
  }
}
