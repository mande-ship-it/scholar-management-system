import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static final List<Function(Map<String, dynamic>)> _messageListeners = [];
  static final List<Function(Map<String, dynamic>)> _callListeners = [];

  static void init(String userId) {
    if (_socket != null) return;

    final String url = ApiService.baseUrl;

    _socket = IO.io(url, IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .setExtraHeaders({'userId': userId})
      .enableAutoConnect()
      .enableReconnection()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Socket Connected');
      _socket!.emit('join', userId);
    });

    _socket!.on('new_meeting_message', (data) {
      for (var listener in _messageListeners) {
        listener(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('incoming_call', (data) {
      for (var listener in _callListeners) {
        listener(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Socket Disconnected'));
  }

  static void joinMeeting(String meetingId) {
    _socket?.emit('join_meeting', meetingId);
  }

  static void sendMessage(String meetingId, String text, String senderName) {
    _socket?.emit('meeting_message', {
      'meetingId': meetingId,
      'text': text,
      'sender': senderName,
      'time': DateTime.now().toIso8601String(),
    });
  }

  static void initiateCall(String meetingId, List<String> participants, String callerName, bool isVideo) {
    _socket?.emit('initiate_call', {
      'meetingId': meetingId,
      'participants': participants,
      'callerName': callerName,
      'isVideo': isVideo,
    });
  }

  static void addMessageListener(Function(Map<String, dynamic>) listener) {
    _messageListeners.add(listener);
  }

  static void removeMessageListener(Function(Map<String, dynamic>) listener) {
    _messageListeners.remove(listener);
  }

  static void addCallListener(Function(Map<String, dynamic>) listener) {
    _callListeners.add(listener);
  }

  static void removeCallListener(Function(Map<String, dynamic>) listener) {
    _callListeners.remove(listener);
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
