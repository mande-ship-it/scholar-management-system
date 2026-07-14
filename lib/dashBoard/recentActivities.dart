import 'package:flutter/material.dart';

class RecentActivitiesComponent extends StatelessWidget {
  const RecentActivitiesComponent({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    final List<Map<String, String>> upcomingEvents = [
      {
        "month": "JUL",
        "day": "15",
        "title": "Form 4 Career Guidance Workshop",
        "desc": "Equipping final-year secondary students with career planning resources and career talks.",
        "venue": "Zomba Catholic Secondary School"
      },
      {
        "month": "AUG",
        "day": "02",
        "title": "Annual Sponsorship Disbursements",
        "desc": "Distribution of pocket allowances, school materials, and tuition coverage payouts.",
        "venue": "Mzuzu Secondary School & Partner Banks"
      },
      {
        "month": "AUG",
        "day": "20",
        "title": "Mentorship Circle Meeting",
        "desc": "Monthly cohort sync focusing on life-skills, academic hurdles, and community building.",
        "venue": "Virtual Sync (Microsoft Teams)"
      },
      {
        "month": "SEP",
        "day": "05",
        "title": "New Scholar Orientation Day",
        "desc": "Welcoming the newly admitted Form 1 scholars into the AGE Africa support program.",
        "venue": "AGE Africa Zomba Head Office"
      }
    ];

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
                const Icon(Icons.event_note, color: brandOrange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  "Upcoming Events & Program Deadlines",
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
              "Track key activities, cohort syncs, and administrative deadlines scheduled for AGE Africa scholars.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 30),
            
            // Events list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingEvents.length,
              separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFEEECE5)),
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Badge Widget
                    Container(
                      width: 55,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: brandCreamDark),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: const BoxDecoration(
                              color: brandOrange,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                            child: Center(
                              child: Text(
                                event["month"]!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: brandCream,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                              ),
                              child: Center(
                                child: Text(
                                  event["day"]!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: brandBrown,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Event info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event["title"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: brandBrown,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event["desc"]!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: brandOlive.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Venue: ${event["venue"]!}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: brandOlive.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action Arrow
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
