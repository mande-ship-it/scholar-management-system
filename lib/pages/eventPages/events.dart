import 'package:flutter/material.dart';
import '../../events/events_component.dart';
import '../../academics/academics_utils.dart';

class EventsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const EventsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return EventsComponent(onBack: onBack);
  }
}
