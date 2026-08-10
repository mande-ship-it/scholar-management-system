import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'sponsors_utils.dart';

typedef OnSponsorRegistered = Future<void> Function(Sponsor sponsor);

class RegisterSponsorComponent extends StatefulWidget {
  final OnSponsorRegistered? onRegister;
  final Sponsor? existingSponsor;
  final VoidCallback? onBack;

  const RegisterSponsorComponent({super.key, this.onRegister, this.existingSponsor, this.onBack});

  @override
  State<RegisterSponsorComponent> createState() => _RegisterSponsorComponentState();
}

class _RegisterSponsorComponentState extends State<RegisterSponsorComponent> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _registrationDate = DateTime.now();
  bool _isLoading = false;

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
      _addressController.text = existing.address;
      _notesController.text = existing.notes;
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
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
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
        'sponsorshipType': 'Standard',
        'amount': 0,
        'registrationDate': _registrationDate.toIso8601String(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': widget.existingSponsor?.status ?? 'Active',
      };

      try {
        Sponsor? sponsorResult;
        Response response;
        
        if (_isEditing) {
          response = await ApiService.updateSponsor(widget.existingSponsor!.id, sponsorData);
          if (response.statusCode == 200) {
            sponsorResult = Sponsor.fromJson(response.data['data']);
          } else {
            _showErrorSnackBar(response.data['message'] ?? "Failed to update profile.");
          }
        } else {
          response = await ApiService.createSponsor(sponsorData);
          if (response.statusCode == 201) {
            sponsorResult = Sponsor.fromJson(response.data['data']);
          } else {
            _showErrorSnackBar(response.data['message'] ?? "Registration failed. Please check inputs.");
          }
        }

        if (mounted && sponsorResult != null) {
          if (widget.onRegister != null) {
             await widget.onRegister!(sponsorResult);
          }
          _showSuccessDialog(sponsorResult);
        }
      } catch (e) {
        String errorMessage = "Failed to synchronize with server.";
        if (e is DioException) {
          if (e.response?.data != null && e.response?.data['message'] != null) {
            errorMessage = e.response?.data['message'];
          } else {
            errorMessage = "Connection error. Please try again.";
          }
        }
        _showErrorSnackBar(errorMessage);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog(Sponsor sponsor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_rounded, color: kBrandOlive, size: 40),
              ),
              const SizedBox(height: 24),
              const Text("Transaction Successful", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kBrandBrown)),
              const SizedBox(height: 12),
              Text("Sponsor profile for '${sponsor.name}' has been securely synchronized with the registry.", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (!_isEditing) _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("RETURN TO DIRECTORY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _organizationController.clear();
    _emailController.clear();
    _phoneController.clear();
    _contactPersonController.clear();
    _addressController.clear();
    _notesController.clear();
    setState(() {
      _registrationDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionPortalHeader("IDENTITY & ENTITY PROFILE", Icons.business_rounded),
                        const SizedBox(height: 24),
                        _buildIdentitySection(isMobile),
                        
                        const SizedBox(height: 48),
                        _sectionPortalHeader("LIAISON & COMMUNICATION", Icons.contact_phone_rounded),
                        const SizedBox(height: 24),
                        _buildContactSection(isMobile),

                        const SizedBox(height: 48),
                        _sectionPortalHeader("STRATEGIC PROGRAM NOTES", Icons.description_rounded),
                        const SizedBox(height: 24),
                        _executiveCard(
                          isMobile: isMobile,
                          children: [
                            TextFormField(
                              controller: _notesController,
                              maxLines: 4,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4C3C32)),
                              decoration: _inputDeco("Internal Philanthropic Notes", Icons.notes_rounded),
                            ),
                          ],
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildPortalFixedFooter(isMobile),
        ],
      ),
    );
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
          Expanded(
            child: Text(
              _isEditing ? "Partner Update" : "Partner Onboarding",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          IconButton(
            onPressed: _resetForm,
            icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
            tooltip: "Reset Form",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _sectionPortalHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
          title, 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            color: Colors.grey.shade500, 
            letterSpacing: 1.2
          )
        ),
      ],
    );
  }

  Widget _buildPortalFixedFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isMobile) ...[
            TextButton(
              onPressed: () => _resetForm(),
              child: const Text("DISCARD DRAFT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
            ),
            const SizedBox(width: 24),
          ],
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitForm,
            icon: _isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_isEditing ? Icons.save_as_rounded : Icons.verified_user_rounded, size: 18),
            label: Text(_isLoading ? "SYNCING..." : (_isEditing ? "AUTHORIZE UPDATES" : "FINALIZE ONBOARDING"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3C32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(_isEditing ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: kBrandBrown, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? "Modify Sponsor Profile" : "Register Strategic Partner", 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                Text(_isEditing ? "Update institutional or individual benefactor records." : "Onboard a new philanthropic entity to the scholarship ecosystem.", 
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive.withOpacity(0.8), letterSpacing: 1.5));
  }

  Widget _buildIdentitySection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_nameController, "Sponsor / Entity Name", Icons.badge_outlined, required: true),
          const SizedBox(height: 24),
          _buildTextField(_organizationController, "Parent Organization", Icons.business_outlined),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildTextField(_nameController, "Sponsor / Entity Name", Icons.badge_outlined, required: true)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_organizationController, "Parent Organization", Icons.business_outlined)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(_contactPersonController, "Primary Liaison / Contact Person", Icons.person_pin_rounded, required: true),
      ],
    );
  }

  Widget _buildContactSection(bool isMobile) {
    return _executiveCard(
      isMobile: isMobile,
      children: [
        if (isMobile) ...[
          _buildTextField(_emailController, "Official Email Address", Icons.alternate_email_rounded, required: true),
          const SizedBox(height: 24),
          _buildTextField(_phoneController, "Direct Phone Line", Icons.phone_iphone_rounded, required: true),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildTextField(_emailController, "Official Email Address", Icons.alternate_email_rounded, required: true)),
              const SizedBox(width: 24),
              Expanded(child: _buildTextField(_phoneController, "Direct Phone Line", Icons.phone_iphone_rounded, required: true)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        _buildTextField(_addressController, "Physical / Mailing Address", Icons.location_on_outlined, maxLines: 2),
      ],
    );
  }

  Widget _buildSubmitAction(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_isEditing ? Icons.save_as_rounded : Icons.verified_user_rounded, size: 20),
        label: Text(_isLoading ? "PROCESSING..." : (_isEditing ? "SYNCHRONIZE UPDATES" : "FINALIZE ONBOARDING"), 
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 11 : 13, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kBrandOlive,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _executiveCard({required List<Widget> children, bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
      decoration: _inputDeco(label, icon),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Required Field" : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withOpacity(0.4)),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
