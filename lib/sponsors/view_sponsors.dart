import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import 'sponsors_utils.dart';
import 'register_sponsor.dart';

class ViewSponsorsComponent extends StatefulWidget {
  final VoidCallback? onRegisterSponsor;
  final Function(Sponsor)? onSaveSponsor;
  final Function(Sponsor)? onDeleteSponsor;

  const ViewSponsorsComponent({
    super.key,
    this.onRegisterSponsor,
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
  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _loadSponsors();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSponsors() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.getAllSponsors();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        if (mounted) {
          setState(() {
            _sponsors = data.map((s) => Sponsor.fromJson(s)).toList();
            _applyFilter();
            _isLoading = false;
          });
        }
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
            s.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(symbol: 'MWK ', decimalDigits: 0);
    return formatter.format(amount);
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
            child: RegisterSponsorComponent(
              existingSponsor: sponsor,
              onRegister: (updated) async {
                if (widget.onSaveSponsor != null) {
                  await widget.onSaveSponsor!(updated);
                }
                _loadSponsors(); // Refresh from server
                if (mounted) Navigator.of(context).pop();
              },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Deletion', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text('Are you sure you want to permanently remove "${sponsor.name}"? This action cannot be reversed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteSponsor(sponsor.id);
      if (response.statusCode == 200) {
        if (!mounted) return;
        _loadSponsors();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sponsor record deleted successfully'), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting sponsor: $e'), backgroundColor: Colors.red.shade600),
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
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(40),
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
                              Text(sponsor.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text(sponsor.organization.isEmpty ? 'INDIVIDUAL BENEFACTOR' : sponsor.organization.toUpperCase(),
                                style: TextStyle(fontSize: 12, color: kBrandOlive, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ],
                          ),
                        ),
                        _statusIndicator(sponsor.status),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    _executiveDetailGrid(sponsor),
                    const SizedBox(height: 40),
                    if (sponsor.notes.isNotEmpty) ...[
                      const Text("INTERNAL NOTES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Text(sponsor.notes, style: const TextStyle(fontSize: 14, height: 1.6, color: kBrandBrown)),
                      ),
                      const SizedBox(height: 40),
                    ],
                      Row(
                        children: [
                          if (PermissionService.hasPermission('sponsors.edit'))
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _openEditForm(sponsor);
                                },
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text("MODIFY PROFILE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBrandBrown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          if (PermissionService.hasPermission('sponsors.edit') && PermissionService.hasPermission('sponsors.delete'))
                            const SizedBox(width: 16),
                          if (PermissionService.hasPermission('sponsors.delete'))
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade100),
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _confirmDelete(sponsor),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                label: const Text("REMOVE RECORD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
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

  Widget _executiveDetailGrid(Sponsor s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 600 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 40,
          runSpacing: 32,
          children: [
            _detailItem(Icons.person_pin_rounded, "PRIMARY CONTACT", s.contactPerson, width: itemWidth),
            _detailItem(Icons.email_outlined, "EMAIL ADDRESS", s.email, width: itemWidth),
            _detailItem(Icons.phone_iphone_rounded, "PHONE NUMBER", s.phone, width: itemWidth),
            _detailItem(Icons.payments_rounded, "FUNDING COMMITMENT", _formatAmount(s.amount), width: itemWidth),
            _detailItem(Icons.workspace_premium_rounded, "SPONSORSHIP TIER", s.sponsorshipType, width: itemWidth),
            _detailItem(Icons.event_available_rounded, "ENROLLED ON", DateFormat('dd MMMM yyyy').format(s.registrationDate), width: itemWidth),
            if (s.address.isNotEmpty) _detailItem(Icons.location_on_outlined, "PHYSICAL ADDRESS", s.address, width: itemWidth),
          ],
        );
      }
    );
  }

  Widget _detailItem(IconData icon, String label, String value, {required double width}) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kBrandOlive.withOpacity(0.6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator(String status) {
    final isActive = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isActive ? Colors.green.shade700 : Colors.grey.shade700, letterSpacing: 0.5)),
        ],
      ),
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(),
          _buildToolbar(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBrown.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volunteer_activism_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Strategic Partners & Sponsors", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -1.0)),
                Text("Management of philanthropic relationships and funding commitments.", 
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        if (_userRole == 'Administrator' || PermissionService.hasPermission('sponsors.create')) ...[
          ElevatedButton.icon(
            onPressed: () {
              if (widget.onRegisterSponsor != null) {
                widget.onRegisterSponsor!();
              } else {
                Navigator.pushNamed(context, '/sponsors/register');
              }
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("REGISTER SPONSOR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, color: kBrandBrown, size: 20),
            onPressed: _isLoading ? null : _loadSponsors,
            tooltip: 'Synchronize Directory',
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by partner name, entity, or email...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
              ),
              onChanged: (value) => setState(() {
                _searchQuery = value;
                _applyFilter();
              }),
            ),
          ),
          const SizedBox(width: 24),
          Text(
            "TOTAL: ${_filteredSponsors.length}",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandBrown.withOpacity(0.4), letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3));

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_loadError!, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadSponsors, child: const Text("RETRY CONNECTION")),
          ],
        ),
      );
    }

    if (_filteredSponsors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.supervised_user_circle_rounded, color: Colors.grey.shade100, size: 100),
            const SizedBox(height: 24),
            Text("DIRECTORY IS CURRENTLY EMPTY", 
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: _filteredSponsors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sponsor = _filteredSponsors[index];
        final typeColor = getSponsorshipTypeColor(sponsor.sponsorshipType);
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kBrandBrown.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                sponsor.name.isNotEmpty ? sponsor.name[0].toUpperCase() : '?',
                style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.w900, fontSize: 20),
              ),
            ),
            title: Text(sponsor.name, style: const TextStyle(fontWeight: FontWeight.w800, color: kBrandBrown, fontSize: 17)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(sponsor.sponsorshipType.toUpperCase(), 
                      style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 12),
                  const Text("•", style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(sponsor.organization.isEmpty ? 'Individual' : sponsor.organization, 
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            trailing: Container(
              constraints: const BoxConstraints(minWidth: 100),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatAmount(sponsor.amount), 
                      style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 13)),
                    const SizedBox(height: 2),
                    _statusIndicator(sponsor.status),
                  ],
                ),
              ),
            ),
            onTap: () => _showSponsorDetails(sponsor),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
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
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}
