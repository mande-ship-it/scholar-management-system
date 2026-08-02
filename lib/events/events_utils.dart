import 'package:flutter/material.dart';

enum EventCategory { workshop, seminar, mentorship, outreach, celebration, meeting, training, other }

extension EventCategoryExtension on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.workshop: return 'Workshop';
      case EventCategory.seminar: return 'Seminar';
      case EventCategory.mentorship: return 'Mentorship Session';
      case EventCategory.outreach: return 'Outreach Program';
      case EventCategory.celebration: return 'Celebration/Award';
      case EventCategory.meeting: return 'Meeting';
      case EventCategory.training: return 'Training';
      case EventCategory.other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.workshop: return Icons.handyman_rounded;
      case EventCategory.seminar: return Icons.school_rounded;
      case EventCategory.mentorship: return Icons.psychology_rounded;
      case EventCategory.outreach: return Icons.campaign_rounded;
      case EventCategory.celebration: return Icons.celebration_rounded;
      case EventCategory.meeting: return Icons.groups_rounded;
      case EventCategory.training: return Icons.model_training_rounded;
      case EventCategory.other: return Icons.event_note_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.workshop: return Colors.orange;
      case EventCategory.seminar: return Colors.blue;
      case EventCategory.mentorship: return Colors.purple;
      case EventCategory.outreach: return Colors.green;
      case EventCategory.celebration: return Colors.pink;
      case EventCategory.meeting: return Colors.teal;
      case EventCategory.training: return Colors.indigo;
      case EventCategory.other: return Colors.grey;
    }
  }
}

class OrganisationEvent {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime date;
  final TimeOfDay time;
  final String location;
  final String? organizer;
  final List<String>? targetedParticipants;
  final List<String>? internalParticipants; // List of User IDs
  final List<Map<String, String>>? externalParticipants; // List of {name, email}
  final String status; // 'Active' or 'History'

  OrganisationEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    this.organizer,
    this.targetedParticipants,
    this.internalParticipants,
    this.externalParticipants,
    this.status = 'Active',
  });

  DateTime get fullDateTime {
    try {
      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      return date; // Fallback to date only if time parsing fails
    }
  }

  /// An event is upcoming if it's Active (Approved) AND its date/time hasn't passed yet.
  bool get isUpcoming => status == 'Active' && fullDateTime.isAfter(DateTime.now());

  /// An event is history if it's explicitly marked as 'History' OR it's 'Active' but its time has passed.
  bool get isHistory => status == 'History' || (status == 'Active' && fullDateTime.isBefore(DateTime.now()));

  /// Auto-delete check for UI: hide from list if it occurred more than 2 days ago
  bool get isExpired => status == 'History' && DateTime.now().difference(fullDateTime).inDays >= 2;

  factory OrganisationEvent.fromJson(Map<String, dynamic> json) {
    // Parse time string "HH:mm:ss" or "HH:mm"
    final timeStr = (json['eventTime'] ?? json['time'] ?? '08:00').toString();
    final timeParts = timeStr.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return OrganisationEvent(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      category: EventCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EventCategory.other,
      ),
      date: json['eventDate'] != null ? DateTime.parse(json['eventDate']) : 
            (json['date'] != null ? DateTime.parse(json['date']) : DateTime.now()),
      time: timeOfDay,
      location: json['location'] ?? 'No location',
      organizer: json['organizer'],
      targetedParticipants: json['targetedParticipants'] != null ? List<String>.from(json['targetedParticipants']) : null,
      internalParticipants: json['internalParticipants'] != null ? List<String>.from(json['internalParticipants']) : null,
      externalParticipants: json['externalParticipants'] != null 
          ? (json['externalParticipants'] as List).map((e) => Map<String, String>.from(e)).toList() 
          : null,
      status: json['status'] ?? 'Active',
    );
  }
}

final List<OrganisationEvent> kEvents = [];
