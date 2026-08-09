import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/socket_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
import '../academics/academics_utils.dart';

class MeetingConversationPage extends StatefulWidget {
  const MeetingConversationPage({super.key});

  @override
  State<MeetingConversationPage> createState() => _MeetingConversationPageState();
}

class _MeetingConversationPageState extends State<MeetingConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  String _meetingTitle = "Live Meeting";
  String? _meetingId;
  String? _meetingLink;
  List<String> _participants = [];

  @override
  void initState() {
    super.initState();
    SocketService.addMessageListener(_onNewMessage);
  }

  @override
  void dispose() {
    SocketService.removeMessageListener(_onNewMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewMessage(Map<String, dynamic> data) {
    if (data['meetingId'] != _meetingId) return;

    if (mounted) {
      setState(() {
        _messages.add({
          'sender': data['sender'],
          'text': data['text'],
          'time': DateTime.parse(data['time']),
          'isMe': data['sender'] == PermissionService.userName,
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _meetingId == null) {
      _meetingId = args['id'];
      _meetingTitle = args['title'] ?? "Live Meeting";
      _participants = List<String>.from(args['participants'] ?? []);
      _meetingLink = args['meetingLink'];

      if (_meetingId != null) {
        SocketService.joinMeeting(_meetingId!);
        // Send a joining system message
        SocketService.sendMessage(_meetingId!, "joined the conversation.", PermissionService.userName ?? "User");
      }
    }
  }

  Future<void> _joinGoogleMeet() async {
    if (_meetingLink == null) return;
    final Uri url = Uri.parse(_meetingLink!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open meeting link.")),
        );
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _meetingId == null) return;

    HapticFeedback.lightImpact();
    SocketService.sendMessage(
      _meetingId!,
      _messageController.text.trim(),
      PermissionService.userName ?? "User"
    );
    _messageController.clear();
  }

  void _startCall(bool isVideo) {
    if (_meetingId == null) return;

    SocketService.initiateCall(
      _meetingId!,
      _participants,
      PermissionService.userName ?? "User",
      isVideo
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Meeting Call",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _ActiveCallOverlay(
          title: _meetingTitle,
          isVideo: isVideo,
          participants: _participants.length,
          onHangUp: () => Navigator.pop(ctx),
          onJoinMeet: _joinGoogleMeet,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: isSmall ? 0 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_meetingTitle, style: TextStyle(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.bold)),
            Text("${_participants.length + 1} participants active", style: TextStyle(fontSize: isSmall ? 9 : 11, color: Colors.white70)),
          ],
        ),
        actions: [
          if (_meetingLink != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _joinGoogleMeet,
                icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                label: const Text("JOIN GOOGLE MEET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                style: TextButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.call_rounded, size: isSmall ? 20 : 24),
            onPressed: () => _startCall(false),
            tooltip: "Audio Call",
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded, size: isSmall ? 20 : 24),
            onPressed: () => _startCall(true),
            tooltip: "Video Call",
          ),
          if (!isSmall) ...[
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(isSmall ? 12 : 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isSmall);
              },
            ),
          ),
          _buildMessageInput(isSmall),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isSmall) {
    final bool isMe = msg['isMe'];
    final bool isSystem = msg['text'] == "joined the conversation.";

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
            child: Text("${msg['sender']} ${msg['text']}",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(msg['sender'], style: TextStyle(fontSize: isSmall ? 9 : 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? kBrandOlive : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Text(
              msg['text'],
              style: TextStyle(color: isMe ? Colors.white : kBrandBrown, fontSize: isSmall ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(fontSize: isSmall ? 13 : 14),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(fontSize: isSmall ? 13 : 14),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: isSmall ? 18 : 22,
            backgroundColor: kBrandOlive,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: isSmall ? 16 : 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCallOverlay extends StatefulWidget {
  final String title;
  final bool isVideo;
  final int participants;
  final VoidCallback onHangUp;
  final VoidCallback onJoinMeet;

  const _ActiveCallOverlay({
    required this.title,
    required this.isVideo,
    required this.participants,
    required this.onHangUp,
    required this.onJoinMeet,
  });

  @override
  State<_ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<_ActiveCallOverlay> {
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background / Video Placeholder
          Positioned.fill(
            child: widget.isVideo && !_isCameraOff
              ? _buildVideoSimulation(isSmall)
              : _buildAudioSimulation(isSmall),
          ),

          // Top Info
          Positioned(
            top: isSmall ? 40 : 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.isVideo ? "VIDEO CALL" : "AUDIO CALL",
                  style: TextStyle(color: Colors.white70, fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connecting ${widget.participants + 1} participants...",
                  style: TextStyle(color: kBrandOlive, fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: isSmall ? 40 : 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _callActionBtn(
                  _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  _isMuted ? Colors.white24 : Colors.white10,
                  () => setState(() => _isMuted = !_isMuted),
                  isSmall: isSmall,
                ),
                SizedBox(width: isSmall ? 12 : 20),
                if (widget.isVideo) ...[
                  _callActionBtn(
                    _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    _isCameraOff ? Colors.white24 : Colors.white10,
                    () => setState(() => _isCameraOff = !_isCameraOff),
                    isSmall: isSmall,
                  ),
                  SizedBox(width: isSmall ? 12 : 20),
                ],
                _callActionBtn(
                  Icons.call_end_rounded,
                  Colors.red.shade700,
                  widget.onHangUp,
                  size: isSmall ? 28 : 32,
                  padding: isSmall ? 18 : 24,
                  isSmall: isSmall,
                ),
                SizedBox(width: isSmall ? 12 : 20),
                _callActionBtn(
                  Icons.videocam_rounded,
                  kBrandOlive,
                  widget.onJoinMeet,
                  isSmall: isSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSimulation(bool isSmall) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.black87],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: isSmall ? 80 : 120, color: Colors.white10),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text("Broadcasting High-Definition Video...", 
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: isSmall ? 12 : 14, fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSimulation(bool isSmall) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmall ? 100 : 150,
            height: isSmall ? 100 : 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBrandOlive.withOpacity(0.2), width: isSmall ? 3 : 4),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.person_rounded, size: isSmall ? 50 : 80, color: Colors.white),
            ),
          ),
          SizedBox(height: isSmall ? 24 : 40),
          Text("Live Encrypted Audio", style: TextStyle(color: Colors.white30, letterSpacing: 1.5, fontSize: isSmall ? 10 : 12)),
        ],
      ),
    );
  }

  Widget _callActionBtn(IconData icon, Color color, VoidCallback onTap, {double size = 24, double padding = 16, bool isSmall = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: EdgeInsets.all(isSmall ? (padding * 0.75) : padding),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: isSmall ? (size * 0.8) : size),
      ),
    );
  }
}
