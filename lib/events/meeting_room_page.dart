import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholar_management_system/services/api_service.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['id'] != null) {
      _fetchMeeting(args['id']);
    } else {
       // Check if ID is in the route name if we used a more complex router,
       // but here we just rely on arguments.
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kBrandOlive)));
    }

    if (_meeting == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Meeting Not Found")),
        body: const Center(child: Text("This meeting may have been cancelled or deleted.")),
      );
    }

    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Meeting Lobby", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: kBrandBrown,
        elevation: 0,
      ),
      body: Center(
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
                    icon: const Icon(Icons.launch_rounded),
                    label: const Text("JOIN GOOGLE MEET", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Return to Dashboard", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
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
