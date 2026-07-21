import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
// Note: You might need to add socket_io_client and audioplayers to pubspec.yaml
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:audioplayers/audioplayers.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;

  // IO.Socket? _socket;
  // final _audioPlayer = AudioPlayer();

  NotificationProvider() {
    fetchNotifications();
    // _initSocket();
  }

  /*
  void _initSocket() {
    _socket = IO.io('http://localhost:5000', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to notification server');
      // In a real app, join the user's specific room
      // _socket!.emit('join', currentUserId);
    });

    _socket!.on('notification', (data) {
      _notifications.insert(0, data);
      _unreadCount++;
      _playNotificationSound();
      notifyListeners();
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      // Ensure you have a sound file in assets/sounds/notification.mp3
      // await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  */

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // You'll need to add this method to ApiService
      // final response = await ApiService.getNotifications();
      // _notifications = List<Map<String, dynamic>>.from(response.data['data']);
      // _unreadCount = _notifications.where((n) => n['is_read'] == false).length;

      // MOCK DATA for now until ApiService is updated
      await Future.delayed(const Duration(seconds: 1));
      _unreadCount = 3;
    } catch (e) {
      print('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) async {
    try {
      // await ApiService.markNotificationRead(id);
      final index = _notifications.indexWhere((n) => n['id'].toString() == id);
      if (index != -1 && !_notifications[index]['is_read']) {
        _notifications[index]['is_read'] = true;
        _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void markAllAsRead() {
    // Logic to mark all as read
    _unreadCount = 0;
    notifyListeners();
  }
}
