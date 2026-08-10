import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class SponsorStatsComponent extends StatefulWidget {
  final VoidCallback? onBack;
  const SponsorStatsComponent({super.key, this.onBack});

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

  Widget _buildPortalHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: widget.onBack ?? () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              "Partnership Analytics",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchStats,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Refresh Stats",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: Color(0xFF9AB334))));

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final averageSponsorship = _totalSponsors > 0 ? _totalFunding / _totalSponsors : 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isMobile)
                        Column(
                          children: [
                            _statTile("STRATEGIC PARTNERS", "$_totalSponsors", Icons.handshake_rounded, const Color(0xFF4C3C32), true),
                            const SizedBox(height: 16),
                            _statTile("TOTAL FUNDING", _formatAmount(_totalFunding), Icons.payments_rounded, const Color(0xFF9AB334), true),
                            const SizedBox(height: 16),
                            _statTile("AVG. COMMITMENT", _formatAmount(averageSponsorship), Icons.analytics_rounded, const Color(0xFFE05B1C), true),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _statTile("STRATEGIC PARTNERS", "$_totalSponsors", Icons.handshake_rounded, const Color(0xFF4C3C32), false)),
                            const SizedBox(width: 24),
                            Expanded(child: _statTile("TOTAL FUNDING", _formatAmount(_totalFunding), Icons.payments_rounded, const Color(0xFF9AB334), false)),
                            const SizedBox(width: 24),
                            Expanded(child: _statTile("AVG. COMMITMENT", _formatAmount(averageSponsorship), Icons.analytics_rounded, const Color(0xFFE05B1C), false)),
                          ],
                        ),

                      const SizedBox(height: 32),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _AnalysisCard(
                              title: "Sponsorship Distribution",
                              subtitle: "Analysis by partnership tier",
                              child: Column(
                                children: _tierDistribution.map((t) {
                                  final count = int.tryParse(t['count'].toString()) ?? 0;
                                  final percent = _totalSponsors > 0 ? count / _totalSponsors : 0.0;
                                  return _DonorProgress(
                                    label: t['sponsorship_type']?.toString().toUpperCase() ?? 'OTHER',
                                    percent: percent,
                                    amount: "$count PARTNERS",
                                    color: const Color(0xFF9AB334)
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 32),
                            Expanded(flex: 2, child: _buildHealthCard()),
                          ],
                        ],
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 32),
                        _buildHealthCard(),
                      ],

                      const SizedBox(height: 32),
                      _AnalysisCard(
                        title: "Growth Projections",
                        subtitle: "Quarterly strategic contribution trend",
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
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color, bool isFullWidth) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF4C3C32), 
                    letterSpacing: -1
                  )
                ),
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 9, 
                    color: Colors.grey.shade400, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 1.2
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    return _AnalysisCard(
      title: "Network Health",
      subtitle: "Retention & commitment indicators",
      child: const Column(
        children: [
          _HealthGauge(label: "Donor Retention", value: 0.92, color: Color(0xFF9AB334)),
          SizedBox(height: 24),
          _HealthGauge(label: "Target Achievement", value: 0.78, color: Color(0xFFE05B1C)),
          SizedBox(height: 24),
          _HealthGauge(label: "Multi-year Pledges", value: 0.65, color: Color(0xFF4C3C32)),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
          Text(
            title.toUpperCase(), 
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF9AB334), 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle, 
            style: const TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF4C3C32), 
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: 0.5)),
              Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF9AB334))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent, 
              minHeight: 10, 
              color: color, 
              backgroundColor: const Color(0xFFF8F9FA)
            ),
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
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            value: value, 
            strokeWidth: 6, 
            color: color, 
            backgroundColor: const Color(0xFFF8F9FA),
            strokeCap: StrokeCap.round,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
              Text("${(value * 100).toInt()}% SCORE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
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
          width: isMobile ? 32 : 44,
          height: 140 * value,
          decoration: BoxDecoration(
            color: isCurrent ? const Color(0xFFE05B1C) : const Color(0xFF9AB334),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isCurrent ? const Color(0xFF4C3C32) : Colors.grey)),
      ],
    );
  }
}
