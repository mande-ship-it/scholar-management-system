import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../../academics/academics_utils.dart';

class AIAssistantPage extends StatefulWidget {
  final bool isDrawer;
  final String? currentPage;
  final String? targetId;
  final VoidCallback? onBack;
  const AIAssistantPage({super.key, this.isDrawer = false, this.currentPage, this.targetId, this.onBack});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': '⭐ Strategic AI Engine Online. I have established a deep real-time link to the entire AGE Africa database including scholars, institutions, financials, and operations. How can I analyze the system for you today?'
    }
  ];
  bool _isTyping = false;

  Future<void> _sendMessage({String? customMessage}) async {
    final text = customMessage ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
      if (customMessage == null) _messageController.clear();
    });

    _scrollToBottom();

    try {
      // Send the entire conversation history to the backend for OpenAI-style context awareness
      final response = await ApiService.chatWithAI(
        _messages.map((m) => {
          'role': m['role'],
          'content': m['content']
        }).toList(),
        currentPage: widget.currentPage,
        targetId: widget.targetId,
      );
      if (response.statusCode == 200) {
        final reply = response.data['data']['reply'];
        if (mounted) {
          setState(() {
            _messages.add({'role': 'assistant', 'content': reply});
            _isTyping = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '❌ ERROR: Uplink failed. Please ensure the Groq AI Engine and SMS Backend are synchronized.'
          });
          _isTyping = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
            onPressed: widget.onBack ?? () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Intelligence Assistant",
              style: TextStyle(
                fontSize: isVerySmall ? 13 : 16, 
                fontWeight: FontWeight.w900, 
                color: const Color(0xFF4C3C32), 
                letterSpacing: -0.2
              ),
            ),
          ),
          const Icon(Icons.bolt_rounded, color: kBrandOlive, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;

    return Container(
      color: const Color(0xFFF4F7F5),
      child: Column(
        children: [
          if (!widget.isDrawer) _buildPortalHeader(isVerySmall),
          if (widget.isDrawer)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: kBrandBrown),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return _buildChatBubble(m['role'] == 'user', m['content']);
              },
            ),
          ),
          _buildSmartTools(),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 12),
              child: Row(
                children: [
                  const SizedBox(width: 12, height: 12),
                  const SizedBox(width: 12),
                  Text("AI ANALYZING DATABASE...", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1)),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildAIHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: const BoxDecoration(
        color: kBrandBrown,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: kBrandOlive, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Strategic AI Hub", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                Text("MODE: Core System Analysis", style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          if (widget.isDrawer)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    String focus = widget.currentPage?.toUpperCase() ?? 'GLOBAL';
    if (widget.targetId != null) focus = "SCHOLAR: ${widget.targetId}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: kBrandOlive.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed_rounded, size: 14, color: kBrandOlive),
          const SizedBox(width: 8),
          Text("CURRENT FOCUS: $focus",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSmartTools() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolChip("Full System Summary", Icons.analytics_rounded),
            _toolChip("Academic Performance Audit", Icons.school_rounded),
            _toolChip("Financial Flow Analysis", Icons.payments_rounded),
            _toolChip("Institutional Risk Heatmap", Icons.warning_amber_rounded),
            _toolChip("Sponsorship Strategy", Icons.handshake_rounded),
          ],
        ),
      ),
    );
  }

  Widget _toolChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: kBrandBrown),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandBrown)),
        backgroundColor: Colors.white,
        side: BorderSide(color: kBrandBrown.withOpacity(0.1)),
        onPressed: () => _sendMessage(customMessage: label),
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: widget.isDrawer ? 340 : 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUser ? kBrandOlive.withOpacity(0.3) : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isUser ? Icons.person : Icons.auto_awesome, color: isUser ? kBrandBrown.withOpacity(0.5) : kBrandOlive, size: 14),
                const SizedBox(width: 8),
                Text(isUser ? "OPERATOR" : "AI ENGINE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isUser ? kBrandBrown.withOpacity(0.4) : kBrandOlive, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: kBrandBrown, fontSize: 13.5, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter analysis query...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: kBrandBrown, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
