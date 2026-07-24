import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';
import 'sponsors_utils.dart';
import 'register_sponsor.dart';

// ============================================================
// VIEW SPONSORS (LIST, DETAILS, EDIT, DELETE)
// ============================================================

typedef OnLoadSponsors = Future<List<Sponsor>> Function();
typedef OnSaveSponsor = Future<void> Function(Sponsor sponsor);
typedef OnDeleteSponsor = Future<void> Function(Sponsor sponsor);

class ViewSponsorsComponent extends StatefulWidget {
  final OnLoadSponsors? onLoadSponsors;
  final OnSaveSponsor? onSaveSponsor;
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

  Future<void> _loadSponsors() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.getAllSponsors();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _sponsors = data.map((s) => Sponsor(
            id: s['id'].toString(),
            name: s['name'] ?? '',
            organization: s['organization'] ?? '',
            email: s['email'] ?? '',
            phone: s['phone'] ?? '',
            contactPerson: s['contact_person'] ?? '',
            sponsorshipType: s['sponsorship_type'] ?? 'Bronze',
            amount: double.tryParse(s['amount'].toString()) ?? 0,
            registrationDate: s['registration_date'] != null ? DateTime.parse(s['registration_date']) : DateTime.now(),
            address: s['address'] ?? '',
            notes: s['notes'] ?? '',
            status: s['status'] ?? 'Active',
          )).toList();
          _applyFilter();
          _isLoading = false;
        });
      }
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
    setState(() {
      _filteredSponsors = query.isEmpty
          ? List.of(_sponsors)
          : _sponsors.where((s) {
        return s.name.toLowerCase().contains(query) ||
            s.organization.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.sponsorshipType.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatAmount(double amount) {
    final fixed = amount.toStringAsFixed(0);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
    );
    return 'MWK $whole';
  }

  Future<void> _openEditForm(Sponsor sponsor) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              controller: scrollController,
              child: RegisterSponsorComponent(
                existingSponsor: sponsor,
                onRegister: (updated) async {
                  if (widget.onSaveSponsor != null) {
                    await widget.onSaveSponsor!(updated);
                  }
                  final index = _sponsors.indexWhere((s) => s.id == updated.id);
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
        title: const Text('Delete Sponsor', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text('Are you sure you want to delete "${sponsor.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteSponsor(sponsor.id);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _sponsors.removeWhere((s) => s.id == sponsor.id);
          _applyFilter();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sponsor "${sponsor.name}" deleted'), backgroundColor: Colors.red.shade600),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete sponsor: $e'), backgroundColor: Colors.red.shade600),
      );
    }
  }

  void _showSponsorDetails(Sponsor sponsor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sponsor.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                              const SizedBox(height: 4),
                              Text(sponsor.organization, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: getSponsorshipTypeColor(sponsor.sponsorshipType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: getSponsorshipTypeColor(sponsor.sponsorshipType).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            sponsor.sponsorshipType,
                            style: TextStyle(color: getSponsorshipTypeColor(sponsor.sponsorshipType), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _DetailBadge(
                          icon: Icons.circle,
                          label: sponsor.status,
                          color: sponsor.status == 'Active' ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        _DetailBadge(
                          icon: Icons.calendar_today_rounded,
                          label: 'Since ${_formatDate(sponsor.registrationDate)}',
                          color: kBrandOlive,
                        ),
                      ],
                    ),
                    const Divider(height: 48),
                    _DetailSection(
                      title: 'Contact Information',
                      children: [
                        _DetailRow(icon: Icons.person_outline, label: 'Contact Person', value: sponsor.contactPerson),
                        _DetailRow(icon: Icons.email_outlined, label: 'Email', value: sponsor.email),
                        _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: sponsor.phone),
                        _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: sponsor.address.isEmpty ? '—' : sponsor.address),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _DetailSection(
                      title: 'Sponsorship Details',
                      children: [
                        _DetailRow(icon: Icons.payments_outlined, label: 'Commitment', value: _formatAmount(sponsor.amount)),
                        _DetailRow(icon: Icons.notes_rounded, label: 'Additional Notes', value: sponsor.notes.isEmpty ? 'No notes recorded.' : sponsor.notes),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openEditForm(sponsor);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Profile'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: kBrandBrown,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------------- Header ----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kBrandOlive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.volunteer_activism_rounded, color: kBrandOlive, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sponsors Directory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      SizedBox(height: 3),
                      Text('Manage organization partnerships and individual contributors.',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: kBrandBrown),
                  onPressed: _isLoading ? null : _loadSponsors,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Professional Statistics Section ---
                  _buildStatsSection(),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      const Text("Directory Listing", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search sponsors...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          onChanged: (value) => setState(() {
                            _searchQuery = value;
                            _applyFilter();
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_sponsors.isEmpty) return const SizedBox.shrink();

    final totalSponsors = _sponsors.length;
    final activeSponsors = _sponsors.where((s) => s.status == 'Active').length;
    final totalFunding = _sponsors.fold<double>(0, (sum, s) => sum + s.amount);
    
    // Tier distribution
    final platinum = _sponsors.where((s) => s.sponsorshipType == 'Platinum').length;
    final gold = _sponsors.where((s) => s.sponsorshipType == 'Gold').length;

    return Row(
      children: [
        _StatTile(
          label: "Active Partners",
          value: "$activeSponsors / $totalSponsors",
          icon: Icons.handshake_rounded,
          color: kBrandOlive,
          subtitle: "Total registered: $totalSponsors",
        ),
        const SizedBox(width: 16),
        _StatTile(
          label: "Total Committed",
          value: _formatAmount(totalFunding),
          icon: Icons.account_balance_wallet_rounded,
          color: kBrandBrown,
          subtitle: "Across all tiers",
        ),
        const SizedBox(width: 16),
        _StatTile(
          label: "Top Tiers",
          value: "${platinum + gold}",
          icon: Icons.workspace_premium_rounded,
          color: kBrandOrange,
          subtitle: "Platinum & Gold",
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));

    if (_loadError != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadSponsors, child: const Text('Try Again')),
          ],
        ),
      );
    }

    if (_filteredSponsors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 16),
            Text(_sponsors.isEmpty ? 'No sponsors registered yet' : 'No sponsors match your search', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredSponsors.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sponsor = _filteredSponsors[index];
          final typeColor = getSponsorshipTypeColor(sponsor.sponsorshipType);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: typeColor.withValues(alpha: 0.1),
              child: Text(
                sponsor.name.isNotEmpty ? sponsor.name[0].toUpperCase() : '?',
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(sponsor.name, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
            subtitle: Row(
              children: [
                Text(sponsor.sponsorshipType, style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 4, color: Colors.grey),
                const SizedBox(width: 8),
                Text(sponsor.organization, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatAmount(sponsor.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                Text(sponsor.status, style: TextStyle(fontSize: 11, color: sponsor.status == 'Active' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            onTap: () => _showSponsorDetails(sponsor),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.color, required this.subtitle});
  final String label, value, subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandBrown)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBrandBrown, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: kBrandBrown),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
