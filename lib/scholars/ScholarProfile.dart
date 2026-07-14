import 'package:flutter/material.dart';

class ScholarProfileComponent extends StatelessWidget {
  const ScholarProfileComponent({super.key});

  @override
  Widget build(BuildContext context) {
    // Attempt to read the passed scholar arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Use passed data or fall back to a rich default profile (Mary Banda)
    final String name = args?['name'] ?? 'Mary Banda';
    final String id = args?['id'] ?? '001';
    final String schoolType = args?['schoolType'] ?? 'Secondary';
    final String school = args?['school'] ?? 'Mzuzu Government Secondary School';
    final String scholarClass = args?['class'] ?? 'Form 3';
    final String status = args?['status'] ?? 'Active';
    final String district = args?['district'] ?? 'Mzimba';
    final String donor = args?['donor'] ?? 'PMI';
    final String sex = args?['sex'] ?? 'Female';
    final String dob = args?['dob'] ?? '2009-05-12';
    final String village = args?['village'] ?? 'Chilinde';
    final String phone = args?['phone'] ?? '+265 888 12 34 56';
    final String programType = args?['programType'] ?? '';
    final String startYear = args?['startYear'] ?? '2023';
    final String endYear = args?['endYear'] ?? '2027';

    final bool isActive = status == 'Active';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Summary Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      name.split(' ').map((e) => e[0]).take(2).join(''),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "ID: $id",
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. School / Institution Affiliation Section (Prominently Highlighted)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.domain, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "School Affiliation",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Assigned Institution", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    subtitle: Text(
                      school,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Level", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          subtitle: Text(schoolType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Year / Class", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          subtitle: Text(scholarClass, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (schoolType == 'University' && programType.isNotEmpty)
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Program Type", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            subtitle: Text(programType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blue)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            schoolType == 'University' ? "Program Start" : "Session Start",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          subtitle: Text(startYear, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            schoolType == 'University' ? "Program End" : "Session End",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          subtitle: Text(endYear, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      if (schoolType == 'University' && programType.isNotEmpty)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Information Grid (Personal Details & Sponsorship)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(height: 20),
                        _infoRow(Icons.wc, "Sex", sex),
                        _infoRow(Icons.cake, "Date of Birth", dob),
                        _infoRow(Icons.phone, "Phone Number", phone),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Origin & Sponsorship
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Origin & Sponsorship", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(height: 20),
                        _infoRow(Icons.map, "District", district),
                        _infoRow(Icons.home, "Home Village", village),
                        _infoRow(Icons.monetization_on, "Assigned Donor", donor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/editScholar',
                    arguments: args ?? {
                      'id': id,
                      'name': name,
                      'schoolType': schoolType,
                      'school': school,
                      'class': scholarClass,
                      'status': status,
                      'district': district,
                      'donor': donor,
                      'sex': sex,
                      'dob': dob,
                      'village': village,
                      'phone': phone,
                      'programType': programType,
                      'startYear': startYear,
                      'endYear': endYear,
                    },
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit Scholar Profile"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/deleteScholar',
                    arguments: args ?? {
                      'id': id,
                      'name': name,
                      'schoolType': schoolType,
                      'school': school,
                      'class': scholarClass,
                      'status': status,
                      'district': district,
                      'donor': donor,
                      'sex': sex,
                      'dob': dob,
                      'village': village,
                      'phone': phone,
                      'programType': programType,
                      'startYear': startYear,
                      'endYear': endYear,
                    },
                  );
                },
                icon: const Icon(Icons.person_remove),
                label: const Text("Delete Scholar"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}