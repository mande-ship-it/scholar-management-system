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
  bool _isSearchExpanded = false;
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

  Future<void> _confirmDelete(Sponsor sponsor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Partner'),
        content: Text('Permanently remove "${sponsor.name}"? This action cannot be reversed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteSponsor(sponsor.id);
      if (response.statusCode == 200) {
        _loadSponsors();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner removed.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
    }
  }

  void _showSponsorDetails(Sponsor sponsor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Details",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: anim.value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * curved.value),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: kBrandOlive.withOpacity(0.1),
                                child: Text(sponsor.name[0].toUpperCase(), style: const TextStyle(color: kBrandBrown, fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sponsor.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                                    Text(sponsor.organization.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow("Sponsorship Level", sponsor.sponsorshipType, Icons.workspace_premium_outlined),
                              _infoRow("Total Funding", _formatAmount(sponsor.amount), Icons.payments_outlined),
                              _infoRow("Primary Contact", sponsor.contactPerson, Icons.person_outline_rounded),
                              _infoRow("Email Address", sponsor.email, Icons.email_outlined),
                              _infoRow("Phone Number", sponsor.phone, Icons.phone_outlined),
                              if (sponsor.notes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text("INTERNAL NOTES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                  child: Text(sponsor.notes, style: const TextStyle(fontSize: 12, height: 1.5)),
                                ),
                              ],
                              const SizedBox(height: 32),
                              if (PermissionService.hasPermission('sponsors.edit'))
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _openEditForm(sponsor);
                                    },
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    label: const Text("MODIFY PARTNER PROFILE"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kBrandOlive,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kBrandOlive.withOpacity(0.6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditForm(Sponsor sponsor) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RegisterSponsorComponent(
            existingSponsor: sponsor,
            onRegister: (updated) async {
              if (widget.onSaveSponsor != null) await widget.onSaveSponsor!(updated);
              _loadSponsors();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final filtered = _filteredSponsors;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile),
          _buildPortalToolbar(isMobile),
          Expanded(
            child: _buildPortalRegistryList(filtered, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile) {
    if (isMobile && _isSearchExpanded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(child: _portalCompactSearchField(true)),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () => setState(() {
                _isSearchExpanded = false;
                _searchQuery = '';
                _applyFilter();
              }),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Strategic Partner Registry",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ],
            ),
          ),
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF4C3C32), size: 22),
              onPressed: () => setState(() => _isSearchExpanded = true),
            ),
          const SizedBox(width: 8),
          if (_userRole == 'Administrator' || PermissionService.hasPermission('sponsors.create'))
            ElevatedButton(
              onPressed: () {
                if (widget.onRegisterSponsor != null) {
                  widget.onRegisterSponsor!();
                } else {
                  Navigator.pushNamed(context, '/sponsors/register').then((_) => _loadSponsors());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3C32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                minimumSize: isMobile ? Size.zero : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isMobile ? Icons.add_rounded : Icons.volunteer_activism_rounded, size: 18),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    const Text("REGISTER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortalToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          if (!isMobile) _portalCompactSearchField(false),
          const Spacer(),
          if (!isMobile) ...[
            _miniStat(Icons.handshake_rounded, "${_filteredSponsors.length} Strategic Partners"),
            const SizedBox(width: 12),
          ],
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Color(0xFF4C3C32), size: 20),
            onPressed: _isLoading ? null : _loadSponsors,
            tooltip: 'Refresh Directory',
          ),
        ],
      ),
    );
  }

  Widget _portalCompactSearchField(bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 320,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: isMobile ? Border.all(color: const Color(0xFFEEEEEE)) : null,
      ),
      child: TextField(
        onChanged: (val) {
          _searchQuery = val;
          _applyFilter();
        },
        autofocus: isMobile,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: isMobile ? "Search partners..." : "Search name, organization...",
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF4C3C32).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32))),
        ],
      ),
    );
  }

  Widget _buildPortalRegistryList(List<Sponsor> sponsors, bool isMobile) {
    if (sponsors.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 12 : 32),
      itemCount: sponsors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildPortalActionRow(sponsors[index], isMobile),
    );
  }

  Widget _buildPortalActionRow(Sponsor s, bool isMobile) {
    final bool isActive = s.status == 'Active';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSponsorDetails(s),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF9AB334).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF9AB334).withOpacity(0.2), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 16),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF4C3C32), letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.corporate_fare_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(s.organization.isEmpty ? 'INDIVIDUAL BENEFACTOR' : s.organization.toUpperCase(), 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.sponsorshipType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4C3C32))),
                        const SizedBox(height: 4),
                        Text(_formatAmount(s.amount), style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Color(0xFF9AB334).withOpacity(0.1) : Color(0xFFE05B1C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.status.toUpperCase(),
                        style: TextStyle(
                          color: isActive ? const Color(0xFF9AB334) : const Color(0xFFE05B1C), 
                          fontWeight: FontWeight.w900, 
                          fontSize: 9,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 16 : 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.volunteer_activism_rounded, color: kBrandOlive, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Strategic Partner Registry', style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: kBrandBrown, letterSpacing: -0.5)),
                Text('Management of philanthropic relationships and funding commitments.',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (_userRole == 'Administrator' || PermissionService.hasPermission('sponsors.create'))
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onRegisterSponsor != null) {
                  widget.onRegisterSponsor!();
                } else {
                  Navigator.pushNamed(context, '/sponsors/register').then((_) => _loadSponsors());
                }
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isMobile ? "ADD" : "REGISTER", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandOlive,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search partners...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilter();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.sync_rounded, color: kBrandBrown, size: 18),
                  onPressed: _isLoading ? null : _loadSponsors,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    if (_loadError != null) return Center(child: Text(_loadError!));
    if (_filteredSponsors.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 20),
      itemCount: _filteredSponsors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final s = _filteredSponsors[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showSponsorDetails(s),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: kBrandBrown.withOpacity(0.1),
                      child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: kBrandBrown, fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrandBrown)),
                          const SizedBox(height: 4),
                          Text(s.organization.isEmpty ? 'Individual Benefactor' : s.organization, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(s.sponsorshipType.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandOlive)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade400),
                              ),
                              const SizedBox(width: 8),
                              Text(_formatAmount(s.amount), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: s.status == 'Active' ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: s.status == 'Active' ? Colors.green : Colors.grey)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text("Directory is empty", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
