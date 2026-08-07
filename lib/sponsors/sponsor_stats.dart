import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';

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
          _totalSponsors = data['totalSponsors'] ?? 0;
          _totalFunding = double.tryParse(data['totalFunding'].toString()) ?? 0;
          _tierDistribution = List<Map<String, dynamic>>.from(data['tierDistribution'] ?? []);
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final averageSponsorship = _totalSponsors > 0 ? _totalFunding / _totalSponsors : 0.0;

    return Container(
      color: const Color(0xFFF0F2F5), // Facebook-style background
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 1)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.volunteer_activism_rounded, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sponsor Analysis', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const Text('Donor contributions and impact metrics.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _fetchStats,
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F2F5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Key Metrics ---
            if (isMobile)
              Column(
                children: [
                  _StatMetric(label: "Total Sponsors", value: "$_totalSponsors", icon: Icons.handshake_rounded, color: kBrandBrown, isMobile: true),
                  const SizedBox(height: 12),
                  _StatMetric(label: "Total Funding", value: _formatAmount(_totalFunding), icon: Icons.payments_rounded, color: kBrandOlive, isMobile: true),
                  const SizedBox(height: 12),
                  _StatMetric(label: "Avg. per Donor", value: _formatAmount(averageSponsorship), icon: Icons.analytics_rounded, color: kBrandOrange, isMobile: true),
                ],
              )
            else
              Row(
                children: [
                  _StatMetric(label: "Total Sponsors", value: "$_totalSponsors", icon: Icons.handshake_rounded, color: kBrandBrown, isMobile: false),
                  const SizedBox(width: 16),
                  _StatMetric(label: "Total Funding", value: _formatAmount(_totalFunding), icon: Icons.payments_rounded, color: kBrandOlive, isMobile: false),
                  const SizedBox(width: 16),
                  _StatMetric(label: "Avg. per Donor", value: _formatAmount(averageSponsorship), icon: Icons.analytics_rounded, color: kBrandOrange, isMobile: false),
                ],
              ),

            const SizedBox(height: 20),

            if (isMobile)
              Column(
                children: [
                  _StatCard(
                    title: "Sponsorship Tiers",
                    subtitle: "Partners by tier",
                    child: Column(
                      children: _tierDistribution.map((t) {
                        final count = int.tryParse(t['count'].toString()) ?? 0;
                        final percent = _totalSponsors > 0 ? count / _totalSponsors : 0.0;
                        return _DonorProgress(
                          label: t['sponsorship_type'] ?? 'Other',
                          percent: percent,
                          amount: "$count",
                          color: kBrandOlive
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHealthCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      title: "Sponsorship Tiers",
                      subtitle: "Distribution of partners by tier",
                      child: Column(
                        children: _tierDistribution.map((t) {
                          final count = int.tryParse(t['count'].toString()) ?? 0;
                          final percent = _totalSponsors > 0 ? count / _totalSponsors : 0.0;
                          return _DonorProgress(
                            label: t['sponsorship_type'] ?? 'Other',
                            percent: percent,
                            amount: "$count",
                            color: kBrandOlive
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _buildHealthCard()),
                ],
              ),

            const SizedBox(height: 20),
            _StatCard(
              title: "Sponsorship Growth Trend",
              subtitle: "Quarterly contribution overview",
              child: Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _GrowthBar(label: "Q1", value: 0.5),
                    const _GrowthBar(label: "Q2", value: 0.7),
                    const _GrowthBar(label: "Q3", value: 0.45),
                    _GrowthBar(label: "Q4", value: 0.82, isCurrent: true, isMobile: isMobile),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sponsorship Health", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
          SizedBox(height: 20),
          _HealthGauge(label: "Donor Retention", value: 0.92, color: kBrandOlive),
          SizedBox(height: 16),
          _HealthGauge(label: "Target Achievement", value: 0.78, color: kBrandOrange),
          SizedBox(height: 16),
          _HealthGauge(label: "Multi-year Pledges", value: 0.65, color: kBrandBrown),
        ],
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({required this.label, required this.value, required this.icon, required this.color, this.isMobile = false});
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) Icon(icon, color: color, size: 24),
                if (!isMobile) const SizedBox(height: 12),
                Text(value, style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );

    return isMobile ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
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
  const _GrowthBar({required this.label, required this.value, this.isCurrent = false, this.isMobile = false});
  final String label;
  final double value;
  final bool isCurrent;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: isMobile ? 24 : 36,
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
        Text(label, style: TextStyle(fontSize: 9, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: kBrandBrown)),
      ],
    );
  }
}
