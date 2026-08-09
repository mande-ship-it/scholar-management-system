import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';

class LiveMeetingPage extends StatefulWidget {
  const LiveMeetingPage({super.key});

  @override
  State<LiveMeetingPage> createState() => _LiveMeetingPageState();
}

class _LiveMeetingPageState extends State<LiveMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  bool _isLoadingUsers = true;
  bool _isCreating = false;
  List<dynamic> _allUsers = [];
  final List<String> _selectedUserIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService.getAllUsers();
      if (response.statusCode == 200) {
        setState(() {
          _allUsers = response.data['data'] ?? [];
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one participant.")),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'participants': _selectedUserIds,
        'meetingDate': DateTime.now().toIso8601String(),
        'meetingTime': DateFormat('hh:mm a').format(DateTime.now()),
      };

      final response = await ApiService.createMeeting(data);

      if (response.statusCode == 201) {
        final meeting = response.data['data'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meeting created and invitations sent!"), backgroundColor: kBrandOlive),
          );
          Navigator.pushReplacementNamed(context, '/events/conversation', arguments: {
            'id': meeting['id'] ?? meeting['_id'],
            'title': meeting['title'],
            'meetingLink': meeting['meetingLink'],
            'participants': _selectedUserIds,
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? "Failed to create meeting.")),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection error. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 500;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Initiate Live Session", style: TextStyle(fontWeight: FontWeight.w900, fontSize: isSmall ? 16 : 20, letterSpacing: -0.5)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kBrandBrown,
        centerTitle: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 32, vertical: isSmall ? 12 : 24),
            child: Form(
              key: _formKey,
              child: isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFormSection(isSmall),
                      const SizedBox(height: 12),
                      Expanded(child: _buildParticipantSection(isSmall)),
                      const SizedBox(height: 16),
                      _buildSubmitButton(isSmall),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildFormSection(isSmall)),
                          const SizedBox(width: 24),
                          Expanded(flex: 4, child: SizedBox(height: 400, child: _buildParticipantSection(isSmall))),
                        ],
                      ),
                      const Spacer(),
                      _buildSubmitButton(isSmall),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isSmall) {
    return ElevatedButton.icon(
      onPressed: _isCreating ? null : _createMeeting,
      icon: _isCreating
        ? SizedBox(width: 18, height: 18, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Icon(Icons.video_call_rounded),
      label: Text(_isCreating ? "PROVISIONING..." : "INITIALIZE LIVE MEETING", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandBrown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildFormSection(bool isSmall) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MEETING DETAILS", style: TextStyle(fontSize: isSmall ? 8 : 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            SizedBox(height: isSmall ? 12 : 20),
            TextFormField(
              controller: _titleController,
              style: TextStyle(fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold),
              decoration: _inputDeco("Meeting Title", Icons.title_rounded, isSmall),
              validator: (v) => v!.isEmpty ? "Title is required" : null,
            ),
            SizedBox(height: isSmall ? 12 : 16),
            TextFormField(
              controller: _descController,
              maxLines: isSmall ? 2 : 3,
              style: TextStyle(fontSize: isSmall ? 12 : 14),
              decoration: _inputDeco("Agenda / Description", Icons.description_rounded, isSmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantSection(bool isSmall) {
    final filteredUsers = _allUsers.where((u) {
      final name = (u['full_name'] ?? u['fullName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(isSmall ? 16 : 24, isSmall ? 16 : 24, isSmall ? 16 : 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text("SELECT PARTICIPANTS", style: TextStyle(fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                  ),
                  Text("${_selectedUserIds.length} selected", style: TextStyle(fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.bold, color: kBrandOlive)),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: isSmall ? 13 : 14),
                decoration: InputDecoration(
                  hintText: "Search users...",
                  prefixIcon: Icon(Icons.search, size: isSmall ? 18 : 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoadingUsers
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                : filteredUsers.isEmpty
                  ? Center(child: Text("No users found.", style: TextStyle(color: Colors.grey, fontSize: isSmall ? 12 : 14)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final id = (user['id'] ?? user['_id']).toString();
                        final name = user['full_name'] ?? user['fullName'] ?? 'System User';
                        final role = user['role_name'] ?? user['roleId']?['name'] ?? 'Staff';
                        final isSelected = _selectedUserIds.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val!) {
                                _selectedUserIds.add(id);
                              } else {
                                _selectedUserIds.remove(id);
                              }
                            });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          secondary: CircleAvatar(
                            radius: isSmall ? 14 : 20,
                            backgroundColor: kBrandBrown.withOpacity(0.1),
                            child: Text(getInitials(name), style: TextStyle(fontSize: isSmall ? 8 : 10, fontWeight: FontWeight.bold, color: kBrandBrown)),
                          ),
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 12 : 14)),
                          subtitle: Text(role, style: TextStyle(fontSize: isSmall ? 10 : 11, color: Colors.grey)),
                          activeColor: kBrandOlive,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, bool isSmall) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: isSmall ? 11 : 14, fontWeight: isSmall ? FontWeight.bold : null),
      prefixIcon: Icon(icon, size: isSmall ? 16 : 20, color: kBrandBrown.withOpacity(0.4)),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isSmall ? 10 : 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 1.5)),
    );
  }
}
