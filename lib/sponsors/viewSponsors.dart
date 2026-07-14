import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// SPONSOR MODEL
// ============================================================

/// Shared Sponsor model used by RegisterSponsorComponent and
/// ViewSponsorsComponent. Keeping this in one file avoids drift between
/// the two screens (e.g. field renames only need to happen once).
class Sponsor {
  final String id;
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
  final String status;

  Sponsor({
    required this.id,
    required this.name,
    required this.organization,
    required this.email,
    required this.phone,
    required this.contactPerson,
    required this.sponsorshipType,
    required this.amount,
    required this.registrationDate,
    this.address = '',
    this.notes = '',
    this.status = 'Active',
  });

  Sponsor copyWith({
    String? id,
    String? name,
    String? organization,
    String? email,
    String? phone,
    String? contactPerson,
    String? sponsorshipType,
    double? amount,
    DateTime? registrationDate,
    String? address,
    String? notes,
    String? status,
  }) {
    return Sponsor(
      id: id ?? this.id,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      contactPerson: contactPerson ?? this.contactPerson,
      sponsorshipType: sponsorshipType ?? this.sponsorshipType,
      amount: amount ?? this.amount,
      registrationDate: registrationDate ?? this.registrationDate,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
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
    'status': status,
  };

  factory Sponsor.fromJson(Map<String, dynamic> json) => Sponsor(
    id: json['id'] as String,
    name: json['name'] as String,
    organization: json['organization'] as String? ?? '',
    email: json['email'] as String,
    phone: json['phone'] as String,
    contactPerson: json['contactPerson'] as String? ?? '',
    sponsorshipType: json['sponsorshipType'] as String,
    amount: (json['amount'] as num).toDouble(),
    registrationDate: DateTime.parse(json['registrationDate'] as String),
    address: json['address'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    status: json['status'] as String? ?? 'Active',
  );
}

// ============================================================
// REGISTER / EDIT SPONSOR FORM
// ============================================================

/// Callback signature for when a sponsor is successfully registered
/// or, in edit mode, successfully updated.
typedef OnSponsorRegistered = Future<void> Function(Sponsor sponsor);

class RegisterSponsorComponent extends StatefulWidget {
  /// Optional callback invoked with the built Sponsor when the form is
  /// submitted and validated. If not provided, the widget just simulates
  /// a save (useful for demos / before backend wiring is done).
  final OnSponsorRegistered? onRegister;

  /// If provided, the form opens pre-filled for editing this sponsor
  /// instead of creating a new one. The sponsor's `id` is preserved on
  /// submit so the caller can tell it apart from a new record.
  final Sponsor? existingSponsor;

  const RegisterSponsorComponent({
    super.key,
    this.onRegister,
    this.existingSponsor,
  });

  @override
  State<RegisterSponsorComponent> createState() =>
      _RegisterSponsorComponentState();
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
      _amountController.text = existing.amount.toStringAsFixed(2);
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

  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    final sponsor = Sponsor(
      id: widget.existingSponsor?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
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
      status: widget.existingSponsor?.status ?? 'Active',
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
          content: Text(_isEditing
              ? 'Sponsor "${sponsor.name}" updated successfully'
              : 'Sponsor "${sponsor.name}" registered successfully'),
          backgroundColor: Colors.green.shade600,
        ),
      );

      if (!_isEditing) {
        _resetForm();
      }
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        // SingleChildScrollView lets the form fit inside a parent with
        // constrained/finite height (e.g. a dashboard grid cell or a
        // SizedBox) instead of overflowing. Without this, Column tries to
        // size itself to its natural (larger) height and Flutter throws
        // "RenderFlex overflowed" when that exceeds the available space.
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditing ? "Edit Sponsor" : "Register Sponsor",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Sponsor / organization name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Sponsor Name *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  validator: (v) =>
                      _validateRequired(v, fieldName: 'Sponsor name'),
                ),
                const SizedBox(height: 16),

                // Organization
                TextFormField(
                  controller: _organizationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Organization / Company",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),

                // Contact person
                TextFormField(
                  controller: _contactPersonController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Contact Person *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      _validateRequired(v, fieldName: 'Contact person'),
                ),
                const SizedBox(height: 16),

                // Email + Phone side by side on wide screens
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    final emailField = TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    );
                    final phoneField = TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9\+\-\s]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Phone *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: _validatePhone,
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: emailField),
                          const SizedBox(width: 16),
                          Expanded(child: phoneField),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        emailField,
                        const SizedBox(height: 16),
                        phoneField,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Sponsorship type + Amount side by side
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    final typeField = DropdownButtonFormField<String>(
                      initialValue: _selectedSponsorshipType,
                      decoration: const InputDecoration(
                        labelText: "Sponsorship Type *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.workspace_premium_outlined),
                      ),
                      items: _sponsorshipTypes
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSponsorshipType = value);
                      },
                      validator: _validateSponsorshipType,
                    );
                    final amountField = TextFormField(
                      controller: _amountController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Amount (\$) *",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: _validateAmount,
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: typeField),
                          const SizedBox(width: 16),
                          Expanded(child: amountField),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        typeField,
                        const SizedBox(height: 16),
                        amountField,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Registration date picker
                InkWell(
                  onTap: _pickRegistrationDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Registration Date",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(_registrationDate)),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSubmit,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.save),
                      label: Text(_isSaving
                          ? "Saving..."
                          : (_isEditing ? "Update Record" : "Save Record")),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 48),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!_isEditing)
                      TextButton.icon(
                        onPressed: _isSaving ? null : _resetForm,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// VIEW SPONSORS (LIST, DETAILS, EDIT, DELETE)
// ============================================================

/// Callback signatures for wiring this component up to a real backend.
typedef OnLoadSponsors = Future<List<Sponsor>> Function();
typedef OnSaveSponsor = Future<void> Function(Sponsor sponsor);
typedef OnDeleteSponsor = Future<void> Function(Sponsor sponsor);

class ViewSponsorsComponent extends StatefulWidget {
  /// Called once when the widget first builds, and again whenever the
  /// user taps refresh. If not provided, a small set of sample sponsors
  /// is shown instead (useful before backend wiring is done).
  final OnLoadSponsors? onLoadSponsors;

  /// Called when an edited sponsor is saved. If not provided, the edit
  /// just updates the in-memory list.
  final OnSaveSponsor? onSaveSponsor;

  /// Called when a sponsor is deleted (after the user confirms). If not
  /// provided, the delete just removes it from the in-memory list.
  final OnDeleteSponsor? onDeleteSponsor;

  const ViewSponsorsComponent({
    super.key,
    this.onLoadSponsors,
    this.onSaveSponsor,
    this.onDeleteSponsor,
  });

  @override
  State<ViewSponsorsComponent> createState() => _ViewSponsorsComponentState();
}

class _ViewSponsorsComponentState extends State<ViewSponsorsComponent> {
  List<Sponsor> _sponsors = [];
  List<Sponsor> _filteredSponsors = [];
  bool _isLoading = true;
  String? _loadError;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSponsors();
  }

  Future<List<Sponsor>> _sampleSponsors() async {
    final now = DateTime.now();
    return [
      Sponsor(
        id: '1',
        name: 'Alice Banda',
        organization: 'Sunrise Foundation',
        email: 'alice@sunrise.org',
        phone: '+265 991 234 567',
        contactPerson: 'Alice Banda',
        sponsorshipType: 'Platinum',
        amount: 15000,
        registrationDate: now.subtract(const Duration(days: 12)),
        address: 'Area 10, Lilongwe',
        notes: 'Renews annually in July.',
        status: 'Active',
      ),
      Sponsor(
        id: '2',
        name: 'James Phiri',
        organization: 'Phiri & Sons Ltd',
        email: 'james@phirisons.com',
        phone: '+265 888 765 432',
        contactPerson: 'James Phiri',
        sponsorshipType: 'Gold',
        amount: 7500,
        registrationDate: now.subtract(const Duration(days: 40)),
        address: 'Old Town, Lilongwe',
        notes: '',
        status: 'Active',
      ),
      Sponsor(
        id: '3',
        name: 'Grace Mwale',
        organization: 'Mwale Enterprises',
        email: 'grace@mwaleent.mw',
        phone: '+265 999 555 111',
        contactPerson: 'Grace Mwale',
        sponsorshipType: 'Bronze',
        amount: 1500,
        registrationDate: now.subtract(const Duration(days: 90)),
        address: 'Kanengo, Lilongwe',
        notes: 'Prefers in-kind contributions going forward.',
        status: 'Inactive',
      ),
    ];
  }

  Future<void> _loadSponsors() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final sponsors = widget.onLoadSponsors != null
          ? await widget.onLoadSponsors!()
          : await _sampleSponsors();
      if (!mounted) return;
      setState(() {
        _sponsors = sponsors;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load sponsors: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchQuery.trim().toLowerCase();
    _filteredSponsors = query.isEmpty
        ? List.of(_sponsors)
        : _sponsors.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.organization.toLowerCase().contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.sponsorshipType.toLowerCase().contains(query);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAmount(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
    return '\$$whole.${parts[1]}';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Platinum':
        return Colors.blueGrey.shade600;
      case 'Gold':
        return Colors.amber.shade800;
      case 'Silver':
        return Colors.grey.shade600;
      case 'Bronze':
        return Colors.brown.shade400;
      default:
        return Colors.teal.shade600;
    }
  }

  Future<void> _openEditForm(Sponsor sponsor) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: SafeArea(
              child: RegisterSponsorComponent(
                existingSponsor: sponsor,
                onRegister: (updated) async {
                  if (widget.onSaveSponsor != null) {
                    await widget.onSaveSponsor!(updated);
                  }
                  final index =
                  _sponsors.indexWhere((s) => s.id == updated.id);
                  setState(() {
                    if (index >= 0) {
                      _sponsors[index] = updated;
                    } else {
                      _sponsors.add(updated);
                    }
                    _applyFilter();
                  });
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Sponsor sponsor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sponsor'),
        content: Text(
          'Are you sure you want to delete "${sponsor.name}"? '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.onDeleteSponsor != null) {
        await widget.onDeleteSponsor!(sponsor);
      }
      if (!mounted) return;
      setState(() {
        _sponsors.removeWhere((s) => s.id == sponsor.id);
        _applyFilter();
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sponsor "${sponsor.name}" deleted'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete sponsor: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showSponsorDetails(Sponsor sponsor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sponsor.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          sponsor.sponsorshipType,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _typeColor(sponsor.sponsorshipType),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sponsor.status,
                    style: TextStyle(
                      color: sponsor.status == 'Active'
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 32),
                  _DetailRow(
                    icon: Icons.business,
                    label: 'Organization',
                    value: sponsor.organization.isEmpty
                        ? '—'
                        : sponsor.organization,
                  ),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Contact Person',
                    value: sponsor.contactPerson,
                  ),
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: sponsor.email,
                  ),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: sponsor.phone,
                  ),
                  _DetailRow(
                    icon: Icons.attach_money,
                    label: 'Amount',
                    value: _formatAmount(sponsor.amount),
                  ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Registration Date',
                    value: _formatDate(sponsor.registrationDate),
                  ),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: sponsor.address.isEmpty ? '—' : sponsor.address,
                  ),
                  _DetailRow(
                    icon: Icons.info_outline,
                    label: 'Notes',
                    value: sponsor.notes.isEmpty ? '—' : sponsor.notes,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openEditForm(sponsor);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                          onPressed: () => _confirmDelete(sponsor),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "View Sponsors",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadSponsors,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, organization, email, or type',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilter();
                });
              },
            ),
            const Divider(height: 24),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadSponsors,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredSponsors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 12),
            Text(
              _sponsors.isEmpty
                  ? 'No sponsors registered yet'
                  : 'No sponsors match your search',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSponsors,
      child: ListView.separated(
        itemCount: _filteredSponsors.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final sponsor = _filteredSponsors[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
              _typeColor(sponsor.sponsorshipType).withOpacity(0.15),
              child: Text(
                sponsor.name.isNotEmpty ? sponsor.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: _typeColor(sponsor.sponsorshipType),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(sponsor.name),
            subtitle: Text(
              'Status: ${sponsor.status} • ${sponsor.sponsorshipType} • '
                  '${_formatDate(sponsor.registrationDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSponsorDetails(sponsor),
          );
        },
      ),
    );
  }
}

/// A single labeled row shown in the sponsor detail sheet.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}