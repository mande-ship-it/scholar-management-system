import 'package:flutter/material.dart';

class StatisticsComponent extends StatelessWidget {
  const StatisticsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCreamDark = Color(0xFFD4AF37); // Gold accent color for budget visual
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        const Text(
          "System Metrics Summary",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: brandBrown,
          ),
        ),
        const SizedBox(height: 16),

        // KPI metrics grid
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            double cardWidth;

            if (width > 1150) {
              // 5 cards side-by-side on very wide screens
              cardWidth = (width - 64) / 5;
            } else if (width > 800) {
              // 3 columns layout
              cardWidth = (width - 32) / 3;
            } else if (width > 550) {
              // 2 columns layout
              cardWidth = (width - 16) / 2;
            } else {
              // 1 column layout
              cardWidth = width;
            }
            
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricCard(
                    title: "Total Scholars",
                    value: "342",
                    icon: Icons.school,
                    color: brandOlive,
                    bg: Colors.white,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricCard(
                    title: "Active Scholars",
                    value: "298",
                    icon: Icons.how_to_reg,
                    color: brandOrange,
                    bg: Colors.white,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricCard(
                    title: "Graduated Scholars",
                    value: "44",
                    icon: Icons.workspace_premium,
                    color: brandBrown,
                    bg: Colors.white,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricCard(
                    title: "Partner Schools",
                    value: "18",
                    icon: Icons.domain,
                    color: brandOlive,
                    bg: Colors.white,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMetricCard(
                    title: "Active Sponsors",
                    value: "25",
                    icon: Icons.handshake,
                    color: brandOrange,
                    bg: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // Charts section
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 950) {
              // Side by side row layout on desktop/wide screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildBarChart(brandOlive, brandOrange, brandBrown),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildBudgetAllocation(brandOlive, brandOrange, brandBrown, brandCreamDark),
                  ),
                ],
              );
            } else {
              // Stacked column layout on tablet/mobile screens
              return Column(
                children: [
                  _buildBarChart(brandOlive, brandOrange, brandBrown),
                  const SizedBox(height: 24),
                  _buildBudgetAllocation(brandOlive, brandOrange, brandBrown, brandCreamDark),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Card(
      elevation: 1,
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color.withValues(alpha: 0.9),
                      ),
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

  Widget _buildBarChart(Color brandOlive, Color brandOrange, Color brandBrown) {
    final List<Map<String, dynamic>> districtData = [
      {"district": "Zomba", "count": 120},
      {"district": "Lilongwe", "count": 85},
      {"district": "Mzimba", "count": 60},
      {"district": "Blantyre", "count": 45},
      {"district": "Mulanje", "count": 32},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Scholar Enrollment by District",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown),
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: districtData.map((data) {
              final String district = data["district"];
              final int count = data["count"];
              final double heightPercent = count / 120.0;
              
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$count",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: brandBrown.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: 150 * heightPercent,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            brandOlive,
                            brandOlive.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          district,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetAllocation(Color brandOlive, Color brandOrange, Color brandBrown, Color brandGold) {
    final List<Map<String, dynamic>> allocations = [
      {"label": "Tuition Fees", "percent": 55, "color": brandOlive},
      {"label": "Allowances", "percent": 25, "color": brandOrange},
      {"label": "Learning Materials", "percent": 15, "color": brandGold},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sponsorship Budget Allocation",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown),
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stacked Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 28,
                  child: Row(
                    children: allocations.map((alloc) {
                      final int percent = alloc["percent"];
                      final Color color = alloc["color"];
                      
                      return Expanded(
                        flex: percent,
                        child: Container(
                          color: color,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "$percent%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Legend list
              Column(
                children: allocations.map((alloc) {
                  final String label = alloc["label"];
                  final int percent = alloc["percent"];
                  final Color color = alloc["color"];
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "$percent%",
                          style: TextStyle(
                            fontSize: 12,
                            color: brandBrown.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
