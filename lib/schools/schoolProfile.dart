import 'package:flutter/material.dart';

class SchoolProfileComponent extends StatelessWidget {
  const SchoolProfileComponent({super.key});

  @override
  Widget build(BuildContext context) {
    // Attempt to read the passed school arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;

    // Use passed data or fall back to a rich default profile (Mzuzu Government Secondary School)
    final String name = args?['name'] ?? 'Mzuzu Government Secondary School';
    final String code = args?['code'] ?? 'SCH-001';
    final String level = args?['level'] ?? 'Secondary School';
    final String type = args?['type'] ?? 'Public / Government';
    final String genderPolicy = args?['genderPolicy'] ?? 'Co-educational (Mixed)';
    final String region = args?['region'] ?? 'Northern Region';
    final String district = args?['district'] ?? 'Mzimba';
    final String address = args?['address'] ?? 'Off M1 Road, Mzuzu';
    final String phone = args?['phone'] ?? '+265 1 311 234';
    final String altPhone = args?['altPhone'] ?? '+265 888 123 456';
    final String email = args?['email'] ?? 'info@mzuzugovsec.edu.mw';
    final String postal = args?['postal'] ?? 'P.O. Box 201, Mzuzu';
    final String website = args?['website'] ?? 'www.mzuzugovsec.edu.mw';
    final String adminName = args?['adminName'] ?? 'Mr. Charles Nyirenda';
    final String adminRole = args?['adminRole'] ?? 'Headteacher';
    final String adminPhone = args?['adminPhone'] ?? '+265 999 456 789';
    final String adminEmail = args?['adminEmail'] ?? 'cnyirenda@mzuzugovsec.edu.mw';
    final String description = args?['description'] ?? 'One of the oldest government secondary schools in the Northern Region of Malawi.';
    final String notes = args?['notes'] ?? 'Partner school since 2018. Active scholar support programs in place.';
    final String status = args?['status'] ?? 'Active';

    final bool isActive = status == 'Active';

    // Map properties back to a String Map for arguments forwarding
    final Map<String, String> schoolData = {
      'name': name,
      'code': code,
      'level': level,
      'type': type,
      'genderPolicy': genderPolicy,
      'region': region,
      'district': district,
      'address': address,
      'phone': phone,
      'altPhone': altPhone,
      'email': email,
      'postal': postal,
      'website': website,
      'adminName': adminName,
      'adminRole': adminRole,
      'adminPhone': adminPhone,
      'adminEmail': adminEmail,
      'description': description,
      'notes': notes,
      'status': status,
    };

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
                      name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "CODE: $code",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                level,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
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

          // 2. Main Details Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address & Location
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text("Location Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow(Icons.map, "Region", region),
                        _infoRow(Icons.my_location, "District", district),
                        _infoRow(Icons.home, "Physical Address", address.isNotEmpty ? address : 'N/A'),
                        _infoRow(Icons.local_post_office, "Postal Address", postal.isNotEmpty ? postal : 'N/A'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // School Contacts & General Policy
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.contact_phone, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text("School Contact Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20),
                        _infoRow(Icons.phone, "Primary Phone", phone),
                        _infoRow(Icons.phone_android, "Alternative Phone", altPhone.isNotEmpty ? altPhone : 'N/A'),
                        _infoRow(Icons.email, "School Email", email),
                        _infoRow(Icons.language, "Website", website.isNotEmpty ? website : 'N/A'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Administrator / Contact Person Card
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
                      Icon(Icons.person, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text("Contact Person / Administration", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(Icons.badge, "Contact Name", adminName.isNotEmpty ? adminName : 'N/A'),
                            _infoRow(Icons.work, "Designation / Role", adminRole.isNotEmpty ? adminRole : 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(Icons.phone, "Phone Number", adminPhone.isNotEmpty ? adminPhone : 'N/A'),
                            _infoRow(Icons.contact_mail, "Email Address", adminEmail.isNotEmpty ? adminEmail : 'N/A'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Policy, Description & Notes Card
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
                      Icon(Icons.info_outline, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text("Additional Information & Policy", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(child: _infoRow(Icons.wc, "Gender Policy", genderPolicy)),
                      Expanded(child: _infoRow(Icons.account_balance, "School Type / Agency", type)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("Description / Profile Details", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    description.isNotEmpty ? description : 'No description available.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text("Administrative Notes", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    notes.isNotEmpty ? notes : 'No notes available.',
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Edit and Delete Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/schools/edit',
                    arguments: schoolData,
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit School"),
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
                    '/schools/delete',
                    arguments: schoolData,
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete School"),
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
