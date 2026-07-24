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
  });

  DateTime get fullDateTime => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

  bool get isUpcoming => fullDateTime.isAfter(DateTime.now());

  bool get isHistory => !isUpcoming;

  bool get isExpired => isHistory && DateTime.now().difference(fullDateTime).inDays > 30;

  factory OrganisationEvent.fromJson(Map<String, dynamic> json) {
    // Parse time string "HH:mm:ss" or "HH:mm"
    final timeParts = (json['time'] as String).split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return OrganisationEvent(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'] ?? '',
      category: EventCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EventCategory.other,
      ),
      date: DateTime.parse(json['date']),
      time: timeOfDay,
      location: json['location'],
      organizer: json['organizer'],
      targetedParticipants: json['targetedParticipants'] != null ? List<String>.from(json['targetedParticipants']) : null,
    );
  }
}

final List<OrganisationEvent> kEvents = [
  OrganisationEvent(
    id: 'e1',
    title: 'Scholar Mentorship Workshop',
    description: 'A session focused on career guidance and personal development for all university scholars.',
    category: EventCategory.mentorship,
    date: DateTime(2026, 8, 15),
    time: const TimeOfDay(hour: 9, minute: 0),
    location: 'BICC, Lilongwe',
    organizer: 'Academic Department',
  ),
  OrganisationEvent(
    id: 'e2',
    title: 'Annual Award Ceremony',
    description: 'Celebrating outstanding academic achievements of our scholars.',
    category: EventCategory.celebration,
    date: DateTime(2026, 12, 10),
    time: const TimeOfDay(hour: 14, minute: 30),
    location: 'Mount Soche Hotel, Blantyre',
    organizer: 'Management',
  ),
  OrganisationEvent(
    id: 'e3',
    title: 'Q2 Staff Meeting',
    description: 'Quarterly review of program performance and budget utilization.',
    category: EventCategory.meeting,
    date: DateTime(2025, 6, 15), // Past event
    time: const TimeOfDay(hour: 10, minute: 0),
    location: 'Head Office',
    organizer: 'Operations',
  ),
  OrganisationEvent(
    id: 'e4',
    title: 'Old Training Session',
    description: 'This event is older than 30 days and should be auto-deleted.',
    category: EventCategory.training,
    date: DateTime(2024, 1, 1), // Very old event
    time: const TimeOfDay(hour: 9, minute: 0),
    location: 'Virtual',
    organizer: 'HR',
  ),
];
