import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'sponsors_utils.dart';

typedef OnSponsorRegistered = Future<void> Function(Sponsor sponsor);

class RegisterSponsorComponent extends StatefulWidget {
  final OnSponsorRegistered? onRegister;
  final Sponsor? existingSponsor;

  const RegisterSponsorComponent({super.key, this.onRegister, this.existingSponsor});

  @override
  State<RegisterSponsorComponent> createState() => _RegisterSponsorComponentState();
}

class _RegisterSponsorComponentState extends State<RegisterSponsorComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandCreamDark = Color(0xFFF3E7C4);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  String? _selectedSponsorshipType;
  DateTime _registrationDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _sponsorshipTypes = const [
    'Platinum',
    'Gold',
    'Silver',
    'Bronze',
    'In-Kind'
  ];

  bool get _isEditing => widget.existingSponsor != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSponsor;
    if (existing != null) {
      _nameController.text = existing.name;
      _organizationController.text = existing.organization;
      _emailController.text = existing.email;
      _phoneController.text = existing.phone;
      _contactPersonController.text = existing.contactPerson;
      _amountController.text = existing.amount.toStringAsFixed(0);
      _addressController.text = existing.address;
      _notesController.text = existing.notes;
      _selectedSponsorshipType = existing.sponsorshipType;
      _registrationDate = existing.registrationDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPersonController.dispose();
    _amountController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: brandBrown,
              onPrimary: Colors.white,
              onSurface: brandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final sponsorData = {
        'name': _nameController.text.trim(),
        'organization': _organizationController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'contactPerson': _contactPersonController.text.trim(),
        'sponsorshipType': _selectedSponsorshipType!,
        'amount': double.tryParse(_amountController.text.trim()) ?? 0,
        'registrationDate': _registrationDate.toIso8601String(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': widget.existingSponsor?.status ?? 'Active',
      };

      try {
        Sponsor? sponsorResult;
        if (_isEditing) {
          final response = await ApiService.updateSponsor(widget.existingSponsor!.id, sponsorData);
          if (response.statusCode == 200) {
            sponsorResult = widget.existingSponsor!.copyWith(
              name: sponsorData['name'] as String,
              organization: sponsorData['organization'] as String,
              email: sponsorData['email'] as String,
              phone: sponsorData['phone'] as String,
              contactPerson: sponsorData['contactPerson'] as String,
              sponsorshipType: sponsorData['sponsorshipType'] as String,
              amount: sponsorData['amount'] as double,
              registrationDate: DateTime.parse(sponsorData['registrationDate'] as String),
              address: sponsorData['address'] as String,
              notes: sponsorData['notes'] as String,
              status: sponsorData['status'] as String,
            );
          }
        } else {
          final response = await ApiService.createSponsor(sponsorData);
          if (response.statusCode == 201) {
            final data = response.data['data'];
            sponsorResult = Sponsor(
              id: data['id'].toString(),
              name: sponsorData['name'] as String,
              organization: sponsorData['organization'] as String,
              email: sponsorData['email'] as String,
              phone: sponsorData['phone'] as String,
              contactPerson: sponsorData['contactPerson'] as String,
              sponsorshipType: sponsorData['sponsorshipType'] as String,
              amount: sponsorData['amount'] as double,
              registrationDate: DateTime.parse(sponsorData['registrationDate'] as String),
              address: sponsorData['address'] as String,
              notes: sponsorData['notes'] as String,
              status: sponsorData['status'] as String,
            );
          }
        }

        if (mounted && sponsorResult != null) {
          _showSuccessDialog(sponsorResult);
        }
      } catch (e) {
        _showErrorSnackBar("Failed to save sponsor. Please check your connection.");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog(Sponsor sponsor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandOlive.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: brandOlive, size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Registration Complete",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sponsor ${sponsor.name} has been successfully added to the program.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _rowDetail("Tier", sponsor.sponsorshipType),
                      const Divider(height: 16),
                      _rowDetail("Amount", "MWK ${sponsor.amount.toStringAsFixed(0)}"),
                      const Divider(height: 16),
                      _rowDetail("Contact", sponsor.contactPerson),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      if (widget.onRegister != null) {
                        await widget.onRegister!(sponsor);
                      } else {
                        if (_isEditing) {
                          Navigator.of(context).pop(true);
                        } else {
                          _resetForm();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Sponsor registered. Visit the Sponsors Registry to view details."),
                              backgroundColor: brandOlive,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(_isEditing ? "Close" : "Go to Sponsors Registry", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, color: brandBrown, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedSponsorshipType = null;
      _registrationDate = DateTime.now();
      _nameController.clear();
      _organizationController.clear();
      _emailController.clear();
      _phoneController.clear();
      _contactPersonController.clear();
      _amountController.clear();
      _addressController.clear();
      _notesController.clear();
    });
  }

  // --- UI COMPONENTS ---

  InputDecoration _getInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      prefixIcon: Icon(prefixIcon, color: brandBrown.withValues(alpha: 0.7)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brandOlive, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 700;

        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isEditing) _buildFormHeader(),
                  const SizedBox(height: 40),

                  _sectionTitle("1. Sponsor Identity"),
                  const SizedBox(height: 16),
                  _buildIdentityCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("2. Contact Information"),
                  const SizedBox(height: 16),
                  _buildContactCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("3. Commitment Details"),
                  const SizedBox(height: 16),
                  _buildCommitmentCard(isWide),

                  const SizedBox(height: 32),
                  _sectionTitle("4. Additional Information"),
                  const SizedBox(height: 16),
                  _buildAdditionalInfoCard(),

                  const SizedBox(height: 48),
                  _buildSubmitButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: brandBrown,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandOlive.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.handshake_rounded, color: brandOlive, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Register Sponsor",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  "Onboard a new partner to the scholarship program.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardShell({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: brandOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBrown),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(bool isWide) {
    final nameField = TextFormField(
      controller: _nameController,
      decoration: _getInputDecoration(labelText: "Sponsor / Entity Name", prefixIcon: Icons.badge_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter sponsor name" : null,
    );

    final orgField = TextFormField(
      controller: _organizationController,
      decoration: _getInputDecoration(labelText: "Parent Organization (if any)", prefixIcon: Icons.business_outlined),
    );

    final tierField = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _selectedSponsorshipType,
      decoration: _getInputDecoration(labelText: "Sponsorship Tier", prefixIcon: Icons.workspace_premium_outlined),
      items: _sponsorshipTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedSponsorshipType = v),
      validator: (v) => v == null ? "Select tier" : null,
    );

    return _buildCardShell(
      title: "Sponsor Identity",
      icon: Icons.person_outline,
      children: [
        if (isWide) ...[
          Row(children: [Expanded(flex: 2, child: nameField), const SizedBox(width: 16), Expanded(child: tierField)]),
          const SizedBox(height: 16),
          orgField,
        ] else ...[
          nameField,
          const SizedBox(height: 16),
          tierField,
          const SizedBox(height: 16),
          orgField,
        ]
      ],
    );
  }

  Widget _buildContactCard(bool isWide) {
    final contactField = TextFormField(
      controller: _contactPersonController,
      decoration: _getInputDecoration(labelText: "Primary Contact Person", prefixIcon: Icons.person_outline),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter contact person" : null,
    );

    final emailField = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(labelText: "Email Address", prefixIcon: Icons.email_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter email" : null,
    );

    final phoneField = TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _getInputDecoration(labelText: "Phone Number", prefixIcon: Icons.phone_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter phone number" : null,
    );

    final addressField = TextFormField(
      controller: _addressController,
      maxLines: 2,
      decoration: _getInputDecoration(labelText: "Physical Address", prefixIcon: Icons.location_on_outlined),
    );

    return _buildCardShell(
      title: "Contact Details",
      icon: Icons.contact_phone_outlined,
      children: [
        if (isWide) ...[
          Row(children: [Expanded(child: contactField), const SizedBox(width: 16), Expanded(child: phoneField)]),
          const SizedBox(height: 16),
          emailField,
          const SizedBox(height: 16),
          addressField,
        ] else ...[
          contactField,
          const SizedBox(height: 16),
          phoneField,
          const SizedBox(height: 16),
          emailField,
          const SizedBox(height: 16),
          addressField,
        ]
      ],
    );
  }

  Widget _buildCommitmentCard(bool isWide) {
    final amountField = TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: _getInputDecoration(labelText: "Committed Amount (MWK)", prefixIcon: Icons.payments_outlined),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Enter amount" : null,
    );

    final dateField = InkWell(
      onTap: _pickRegistrationDate,
      child: InputDecorator(
        decoration: _getInputDecoration(labelText: "Registration Date", prefixIcon: Icons.calendar_today_rounded),
        child: Text("${_registrationDate.day}/${_registrationDate.month}/${_registrationDate.year}"),
      ),
    );

    return _buildCardShell(
      title: "Commitment Details",
      icon: Icons.monetization_on_outlined,
      children: [
        if (isWide) ...[
          Row(children: [Expanded(child: amountField), const SizedBox(width: 16), Expanded(child: dateField)]),
        ] else ...[
          amountField,
          const SizedBox(height: 16),
          dateField,
        ]
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    return _buildCardShell(
      title: "Notes & Remarks",
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: _getInputDecoration(labelText: "Additional Notes", prefixIcon: Icons.sticky_note_2_outlined),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitForm,
      icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 20),
      label: Text(
        _isLoading ? "Saving..." : (_isEditing ? "Update Sponsor Record" : "Complete Sponsor Registration"),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: brandOlive,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: brandOlive.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
