import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import '../services/api_service.dart';
import 'sponsorsUtils.dart';

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

  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _sponsorshipTypes = const ['Platinum', 'Gold', 'Silver', 'Bronze', 'In-Kind'];

  String? _selectedSponsorshipType;
  DateTime _registrationDate = DateTime.now();
  bool _isSaving = false;

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
    
    for (final c in [_nameController, _organizationController, _emailController, _phoneController, _contactPersonController, _amountController]) {
      c.addListener(() => setState(() {}));
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

  String? _validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  Future<void> _pickRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _registrationDate = picked);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

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
      if (_isEditing) {
        await ApiService.updateSponsor(widget.existingSponsor!.id, sponsorData);
      } else {
        await ApiService.createSponsor(sponsorData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sponsor "${_nameController.text.trim()}" saved successfully'), backgroundColor: kBrandOlive),
      );
      if (widget.onRegister != null) {
        // If it was a dialog/component callback, we might need a full object
        // but for now just pop or notify
        Navigator.of(context).pop(true);
      }
      if (!_isEditing) _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _organizationController.clear();
    _emailController.clear();
    _phoneController.clear();
    _contactPersonController.clear();
    _amountController.clear();
    _addressController.clear();
    _notesController.clear();
    setState(() {
      _selectedSponsorshipType = null;
      _registrationDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            _buildHeader(),
            const SizedBox(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildForm()),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: _buildPreview()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person_add_alt_1_rounded, color: kBrandBrown, size: 28),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Register New Sponsor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandBrown)),
            Text("Onboard a new partner to the scholarship program.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildCard(
            title: "Basic Information",
            children: [
              _buildTextField(_nameController, "Sponsor / Entity Name", Icons.badge_outlined, required: true),
              const SizedBox(height: 16),
              _buildTextField(_organizationController, "Parent Organization (if any)", Icons.business_outlined),
              const SizedBox(height: 16),
              _buildTextField(_contactPersonController, "Primary Contact Person", Icons.person_outline, required: true),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Contact Details",
            children: [
              Row(
                children: [
                  Expanded(child: _buildTextField(_emailController, "Email Address", Icons.email_outlined, required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined, required: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_addressController, "Physical Address", Icons.location_on_outlined, maxLines: 2),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: "Sponsorship Commitment",
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSponsorshipType,
                      decoration: _inputDeco("Tier", Icons.workspace_premium_outlined),
                      items: _sponsorshipTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _selectedSponsorshipType = v),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_amountController, "Amount (MWK)", Icons.payments_outlined, required: true, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickRegistrationDate,
                child: InputDecorator(
                  decoration: _inputDeco("Registration Date", Icons.calendar_today_rounded),
                  child: Text(_formatDate(_registrationDate)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSubmit,
                  icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded),
                  label: Text(_isEditing ? "Update Record" : "Save Sponsor Record", style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandOlive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (!_isEditing)
                OutlinedButton(
                  onPressed: _isSaving ? null : _resetForm,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Reset", style: TextStyle(color: kBrandBrown)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final typeColor = getSponsorshipTypeColor(_selectedSponsorshipType ?? 'Other');
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Live Preview", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: typeColor.withValues(alpha: 0.1),
              child: Text(
                _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: typeColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _nameController.text.isEmpty ? "New Sponsor Name" : _nameController.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown),
            ),
          ),
          Center(child: Text(_organizationController.text.isEmpty ? "Organization" : _organizationController.text, style: TextStyle(color: Colors.grey.shade600))),
          const Divider(height: 48),
          _previewRow(Icons.person_outline, "Contact", _contactPersonController.text),
          _previewRow(Icons.email_outlined, "Email", _emailController.text),
          _previewRow(Icons.workspace_premium_outlined, "Tier", _selectedSponsorshipType ?? "Not selected", color: typeColor),
          _previewRow(Icons.payments_outlined, "Funding", _amountController.text.isEmpty ? "MWK 0" : "MWK ${_amountController.text}"),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? kBrandBrown),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value.isEmpty ? "—" : value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? kBrandBrown), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDeco(label, icon),
      validator: required ? (v) => _validateRequired(v, fieldName: label) : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withValues(alpha: 0.6)),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
