import 'package:flutter/material.dart';
import '../../events/events_component.dart';
import '../../academics/academics_utils.dart';

class EventsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const EventsPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return EventsComponent(onBack: onBack, showBackButton: showBackButton);
  }
}
