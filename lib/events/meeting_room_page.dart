import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/socket_service.dart';
import '../academics/academics_utils.dart';

class MeetingRoomPage extends StatefulWidget {
  const MeetingRoomPage({super.key});

  @override
  State<MeetingRoomPage> createState() => _MeetingRoomPageState();
}

class _MeetingRoomPageState extends State<MeetingRoomPage> {
  bool _isLoading = true;
  dynamic _meeting;

  @override
  void initState() {
    super.initState();
    SocketService.addCallListener(_onIncomingCall);
  }

  @override
  void dispose() {
    SocketService.removeCallListener(_onIncomingCall);
    super.dispose();
  }

  void _onIncomingCall(Map<String, dynamic> data) {
    if (_meeting == null || data['meetingId'] != (_meeting['id'] ?? _meeting['_id'])) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${data['callerName']} has started the call!"),
          backgroundColor: kBrandOlive,
          action: SnackBarAction(label: "JOIN", textColor: Colors.white, onPressed: _joinMeet),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    String? id;

    if (args != null && args['id'] != null) {
      id = args['id'].toString();
    } else if (Uri.base.queryParameters.containsKey('id')) {
      id = Uri.base.queryParameters['id'];
    }

    if (id != null) {
      _fetchMeeting(id);
    }
  }

  Future<void> _fetchMeeting(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getMeetingById(id);
      if (response.statusCode == 200) {
        setState(() {
          _meeting = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meeting: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinMeet() async {
    if (_meeting?['meetingLink'] == null) return;
    final Uri url = Uri.parse(_meeting['meetingLink']);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open meeting link.")),
        );
      }
    }
  }

  Widget _buildPortalHeader(bool isVerySmall) {
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
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Meeting Lobby",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          Icon(Icons.video_camera_front_rounded, color: kBrandOlive, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kBrandOlive)));
    }

    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    if (_meeting == null) {
      return Scaffold(
        body: Column(
          children: [
            _buildPortalHeader(isVerySmall),
            const Expanded(child: Center(child: Text("Meeting not found."))),
          ],
        ),
      );
    }

    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPortalHeader(isVerySmall),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmall ? 20 : 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kBrandOlive.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.video_camera_front_rounded, size: 64, color: kBrandOlive),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _meeting['title'] ?? 'Live Meeting',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _meeting['description'] ?? 'No description provided.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                      ),
                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 24),
                      _infoRow(Icons.calendar_today_rounded, "Scheduled Date",
                        _meeting['meetingDate'] != null ? DateTime.parse(_meeting['meetingDate']).toLocal().toString().split(' ')[0] : 'N/A'),
                      const SizedBox(height: 16),
                      _infoRow(Icons.access_time_rounded, "Scheduled Time", _meeting['meetingTime'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _infoRow(Icons.person_rounded, "Organizer", _meeting['organizer']?['fullName'] ?? 'System'),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _joinMeet,
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text("LAUNCH VIDEO CONFERENCE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrandOlive,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/events/conversation', arguments: {
                              'id': _meeting['id'] ?? _meeting['_id'],
                              'title': _meeting['title'],
                              'participants': (_meeting['participants'] as List).map((p) => p['_id'].toString()).toList(),
                              'meetingLink': _meeting['meetingLink'],
                            });
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text("OPEN MEETING CHAT", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBrandBrown,
                            side: const BorderSide(color: kBrandBrown, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kBrandBrown.withOpacity(0.5)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }
}
