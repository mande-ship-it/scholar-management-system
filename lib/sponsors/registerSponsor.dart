import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Model representing a Sponsor record.
class Sponsor {
  final String name;
  final String organization;
  final String email;
  final String phone;
  final String contactPerson;
  final String sponsorshipType;
  final double amount;
  final DateTime registrationDate;
  final String address;
  final String notes;

  Sponsor({
    required this.name,
    required this.organization,
    required this.email,
    required this.phone,
    required this.contactPerson,
    required this.sponsorshipType,
    required this.amount,
    required this.registrationDate,
    required this.address,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'organization': organization,
    'email': email,
    'phone': phone,
    'contactPerson': contactPerson,
    'sponsorshipType': sponsorshipType,
    'amount': amount,
    'registrationDate': registrationDate.toIso8601String(),
    'address': address,
    'notes': notes,
  };
}

/// Callback signature for when a sponsor is successfully registered.
typedef OnSponsorRegistered = Future<void> Function(Sponsor sponsor);

class RegisterSponsorComponent extends StatefulWidget {
  /// Optional callback invoked with the built Sponsor when the form is
  /// submitted and validated. If not provided, the widget just simulates
  /// a save (useful for demos / before backend wiring is done).
  final OnSponsorRegistered? onRegister;

  const RegisterSponsorComponent({super.key, this.onRegister});

  @override
  State<RegisterSponsorComponent> createState() =>
      _RegisterSponsorComponentState();
}

class _RegisterSponsorComponentState extends State<RegisterSponsorComponent> {
  final _formKey = GlobalKey<FormState>();

  // Brand Color Palette (consistent with Scholar / School registration)
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandCreamDark = Color(0xFFF3E7C4);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _sponsorshipTypes = const [
    'Platinum',
    'Gold',
    'Silver',
    'Bronze',
    'In-Kind',
  ];

  String? _selectedSponsorshipType;
  DateTime _registrationDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _organizationController,
      _emailController,
      _phoneController,
      _contactPersonController,
      _amountController,
      _addressController,
      _notesController,
    ]) {
      c.addListener(_updatePreview);
    }
  }

  void _updatePreview() => setState(() {});

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
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid numeric amount';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }

  String? _validateSponsorshipType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a sponsorship type';
    }
    return null;
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
            colorScheme: ColorScheme.light(
              primary: brandBrown,
              onPrimary: Colors.white,
              onSurface: brandBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _registrationDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "SP";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Required: name, contactPerson, email, phone, sponsorshipType, amount
  // Optional (still tracked for completeness): organization, address
  int _getTotalFieldsCount() => 8;

  int _getCompletedFieldsCount() {
    int count = 0;
    if (_nameController.text.trim().isNotEmpty) count++;
    if (_contactPersonController.text.trim().isNotEmpty) count++;
    if (_emailController.text.trim().isNotEmpty) count++;
    if (_phoneController.text.trim().isNotEmpty) count++;
    if (_selectedSponsorshipType != null) count++;
    if (_amountController.text.trim().isNotEmpty) count++;
    if (_organizationController.text.trim().isNotEmpty) count++;
    if (_addressController.text.trim().isNotEmpty) count++;
    return count;
  }

  double _calculateCompletionPercentage() {
    final total = _getTotalFieldsCount();
    if (total == 0) return 0.0;
    return _getCompletedFieldsCount() / total;
  }

  Color _sponsorshipTypeColor(String? type) {
    switch (type) {
      case 'Platinum':
        return const Color(0xFF6C7A89);
      case 'Gold':
        return const Color(0xFFC9971E);
      case 'Silver':
        return const Color(0xFF9AA5AD);
      case 'Bronze':
        return const Color(0xFFA0622D);
      case 'In-Kind':
        return brandOlive;
      default:
        return Colors.grey;
    }
  }

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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    final sponsor = Sponsor(
      name: _nameController.text.trim(),
      organization: _organizationController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      sponsorshipType: _selectedSponsorshipType!,
      amount: double.parse(_amountController.text.trim()),
      registrationDate: _registrationDate,
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (widget.onRegister != null) {
        await widget.onRegister!(sponsor);
      } else {
        // Simulated network/save delay when no callback is supplied.
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sponsor "${sponsor.name}" registered successfully'),
          backgroundColor: brandOlive,
        ),
      );

      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register sponsor: $e'),
          backgroundColor: Colors.red.shade600,
        ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 950;

        final Widget formContent = Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormHeader(),
              const SizedBox(height: 20),
              _buildContactCard(isWide),
              const SizedBox(height: 16),
              _buildSponsorshipCard(isWide),
              const SizedBox(height: 16),
              _buildAdditionalCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        );

        final Widget previewContent = _buildPreviewCard();

        if (isWide) {
          return SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: formContent,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: previewContent,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              previewContent,
              const SizedBox(height: 24),
              formContent,
            ],
          ),
        );
      },
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
            child: const Icon(Icons.volunteer_activism_rounded, color: brandOlive, size: 28),
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
                  "Enter details below to add a new sponsor record.",
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

  Widget _buildContactCard(bool isWide) {
    final nameField = TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: _getInputDecoration(labelText: "Sponsor Name", prefixIcon: Icons.edit_outlined),
      validator: (v) => _validateRequired(v, fieldName: 'Sponsor name'),
    );

    final orgField = TextFormField(
      controller: _organizationController,
      textCapitalization: TextCapitalization.words,
      decoration: _getInputDecoration(labelText: "Organization / Company", prefixIcon: Icons.business_outlined),
    );

    final contactPersonField = TextFormField(
      controller: _contactPersonController,
      textCapitalization: TextCapitalization.words,
      decoration: _getInputDecoration(labelText: "Contact Person", prefixIcon: Icons.person_outline),
      validator: (v) => _validateRequired(v, fieldName: 'Contact person'),
    );

    final emailField = TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: _getInputDecoration(labelText: "Email", prefixIcon: Icons.email_outlined),
      validator: _validateEmail,
    );

    final phoneField = TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\+\-\s]'))],
      decoration: _getInputDecoration(labelText: "Phone", prefixIcon: Icons.phone_outlined),
      validator: _validatePhone,
    );

    return _buildCardShell(
      title: "Sponsor & Contact Information",
      icon: Icons.badge_outlined,
      children: isWide
          ? [
        Row(children: [Expanded(flex: 2, child: nameField), const SizedBox(width: 16), Expanded(child: orgField)]),
        const SizedBox(height: 16),
        contactPersonField,
        const SizedBox(height: 16),
        Row(children: [Expanded(child: emailField), const SizedBox(width: 16), Expanded(child: phoneField)]),
      ]
          : [
        nameField,
        const SizedBox(height: 16),
        orgField,
        const SizedBox(height: 16),
        contactPersonField,
        const SizedBox(height: 16),
        emailField,
        const SizedBox(height: 16),
        phoneField,
      ],
    );
  }

  Widget _buildSponsorshipCard(bool isWide) {
    final typeField = DropdownButtonFormField<String>(
      initialValue: _selectedSponsorshipType,
      decoration: _getInputDecoration(labelText: "Sponsorship Type", prefixIcon: Icons.workspace_premium_outlined),
      items: _sponsorshipTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: (value) => setState(() => _selectedSponsorshipType = value),
      validator: _validateSponsorshipType,
    );

    final amountField = TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      decoration: _getInputDecoration(labelText: "Amount (\$)", prefixIcon: Icons.attach_money),
      validator: _validateAmount,
    );

    final dateField = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _pickRegistrationDate,
      child: InputDecorator(
        decoration: _getInputDecoration(labelText: "Registration Date", prefixIcon: Icons.calendar_today_outlined),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(_registrationDate)),
            Icon(Icons.arrow_drop_down, color: brandBrown.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );

    return _buildCardShell(
      title: "Sponsorship Details",
      icon: Icons.workspace_premium_outlined,
      children: isWide
          ? [
        Row(children: [Expanded(child: typeField), const SizedBox(width: 16), Expanded(child: amountField)]),
        const SizedBox(height: 16),
        dateField,
      ]
          : [
        typeField,
        const SizedBox(height: 16),
        amountField,
        const SizedBox(height: 16),
        dateField,
      ],
    );
  }

  Widget _buildAdditionalCard() {
    return _buildCardShell(
      title: "Additional Information",
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: _getInputDecoration(labelText: "Address", prefixIcon: Icons.location_on_outlined),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: _getInputDecoration(labelText: "Additional Notes", prefixIcon: Icons.sticky_note_2_outlined),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final completion = _calculateCompletionPercentage();
    final isComplete = completion >= 1.0;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSubmit,
            icon: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isSaving ? "Saving..." : "Save Sponsor Record",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: isComplete ? brandOlive : brandOrange,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: (isComplete ? brandOlive : brandOrange).withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: _isSaving ? null : _resetForm,
          icon: const Icon(Icons.refresh),
          label: const Text("Reset"),
          style: TextButton.styleFrom(
            foregroundColor: brandBrown,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final completion = _calculateCompletionPercentage();
    final completed = _getCompletedFieldsCount();
    final total = _getTotalFieldsCount();
    final name = _nameController.text.trim();
    final initials = _getInitials(name);
    final typeColor = _sponsorshipTypeColor(_selectedSponsorshipType);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [brandBrown, brandOlive],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandBrown),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : "New Sponsor Profile",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _organizationController.text.trim().isNotEmpty
                            ? _organizationController.text.trim()
                            : "No organization specified",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(completion),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandCream,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: brandCreamDark),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined, color: typeColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sponsorship & Amount",
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _selectedSponsorshipType != null
                                  ? "$_selectedSponsorshipType tier${_amountController.text.trim().isNotEmpty ? ' — \$${_amountController.text.trim()}' : ''}"
                                  : "Pending Assignment",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandBrown),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final w = (gridConstraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.person_outline, "Contact Person", _contactPersonController.text.trim(), brandOlive)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.email_outlined, "Email", _emailController.text.trim(), brandOrange)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.phone_outlined, "Phone", _phoneController.text.trim(), brandBrown)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.calendar_today_outlined, "Registered", _formatDate(_registrationDate), brandOlive)),
                        SizedBox(width: w, child: _buildPreviewDetailItem(Icons.location_on_outlined, "Address", _addressController.text.trim(), brandOrange)),
                      ],
                    );
                  },
                ),
                const Divider(height: 32),
                _buildCompletionMeter(completion, completed, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double completion) {
    String text = "DRAFT";
    Color bg = Colors.grey.shade300;
    Color fg = Colors.grey.shade800;

    if (completion >= 1.0) {
      text = "READY";
      bg = brandOlive.withValues(alpha: 0.2);
      fg = brandOlive;
    } else if (completion >= 0.6) {
      text = "PROGRESS";
      bg = Colors.blue.withValues(alpha: 0.2);
      fg = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPreviewDetailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(
                value.isNotEmpty ? value : "Not specified",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: value.isNotEmpty ? brandBrown : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionMeter(double completion, int completed, int total) {
    Color progressColor = brandOrange;
    String message = "Drafting Profile";
    if (completion >= 1.0) {
      progressColor = brandOlive;
      message = "Complete & Ready";
    } else if (completion >= 0.6) {
      progressColor = Colors.blue;
      message = "Almost Ready";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor)),
            Text(
              "${(completion * 100).toInt()}% ($completed of $total)",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandBrown),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: completion,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}