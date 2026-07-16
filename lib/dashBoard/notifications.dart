import 'package:flutter/material.dart';

class NotificationsComponent extends StatelessWidget {
  const NotificationsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    final List<Map<String, dynamic>> activities = [
      {
        "role": "Program Officer",
        "name": "Alice",
        "action": "added 5 new scholars in Zomba district",
        "time": "2 hours ago",
        "icon": Icons.person_add,
        "color": brandOlive
      },
      {
        "role": "Finance Officer",
        "name": "Bob",
        "action": "approved allowance payouts for July cohort",
        "time": "4 hours ago",
        "icon": Icons.payments,
        "color": brandOrange
      },
      {
        "role": "Data Clerk",
        "name": "Clara",
        "action": "uploaded Term 1 report cards for Marymount Secondary",
        "time": "1 day ago",
        "icon": Icons.upload_file,
        "color": brandBrown
      },
      {
        "role": "Administrator",
        "name": "Edward Shaba",
        "action": "completed system database backup and encryption verification",
        "time": "2 days ago",
        "icon": Icons.backup,
        "color": brandOlive
      }
    ];

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 950) {
            // Side-by-side layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildActivityCard(activities, brandBrown, brandOrange),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildQuickActionsCard(brandBrown, brandOlive, brandOrange, brandCream),
                ),
              ],
            );
          } else {
            // Stacked layout
            return Column(
              children: [
                _buildActivityCard(activities, brandBrown, brandOrange),
                const SizedBox(height: 24),
                _buildQuickActionsCard(brandBrown, brandOlive, brandOrange, brandCream),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildActivityCard(List<Map<String, dynamic>> activities, Color brandBrown, Color brandOrange) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off, color: brandBrown, size: 28),
                const SizedBox(width: 12),
                Text(
                  "Recent System Activity Log",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: brandBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Audit logs showing updates and inputs made by different department roles.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF7F5EE)),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: activity["color"].withValues(alpha: 0.12),
                        child: Icon(activity["icon"], color: activity["color"], size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                                children: [
                                  TextSpan(
                                    text: "[${activity["role"]}] ",
                                    style: TextStyle(
                                      color: brandOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "${activity["name"]} ",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: activity["action"]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity["time"],
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(Color brandBrown, Color brandOlive, Color brandOrange, Color brandCream) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Operations",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: brandBrown,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Generate files, back up directories, and execute processes.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 30),
            
            _buildActionRow(
              icon: Icons.table_view,
              label: "Export Scholar Excel",
              btnColor: brandOlive,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.picture_as_pdf,
              label: "Download Q2 Reports",
              btnColor: brandOrange,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.backup_outlined,
              label: "Run Database Backup",
              btnColor: brandBrown,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            _buildActionRow(
              icon: Icons.print,
              label: "Disbursement Sheets",
              btnColor: Colors.blueGrey,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required Color btnColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
