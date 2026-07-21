import 'package:flutter/material.dart';
import '../../events/eventsComponent.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EventsComponent(),
    );
  }
}
