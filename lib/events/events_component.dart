import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../academics/academics_utils.dart';
import 'events_utils.dart';

// ---------------------------------------------------------------------------
// PDF report generation (merged from events_report.dart)
// ---------------------------------------------------------------------------

/// Converts a Flutter [Color] to a [PdfColor], so the report always matches
/// the app's live brand colors (kBrandOlive / kBrandBrown / kBrandCream)
/// without hardcoding hex values here.
PdfColor _pdf(Color color) => PdfColor.fromInt(color.value);

/// Same color blended toward white, for tinted chip backgrounds.
PdfColor _tint(Color color, double opacity) {
  final base = _pdf(color);
  return PdfColor(
    base.red + (1 - base.red) * (1 - opacity),
    base.green + (1 - base.green) * (1 - opacity),
    base.blue + (1 - base.blue) * (1 - opacity),
  );
}

/// Builds the PDF document for a single event.
Future<pw.Document> buildEventReportPdf(OrganisationEvent event) async {
  final doc = pw.Document(
    title: '${event.title} - Event Report',
    author: 'AGE Africa',
  );

  final accent = _pdf(event.isHistory ? const Color(0xFF9E9E9E) : event.category.color);
  final brown = _pdf(kBrandBrown);
  final olive = _pdf(kBrandOlive);
  final cream = _pdf(kBrandCream);

  pw.Widget detailBlock(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500, letterSpacing: 0.8, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: cream,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AGE AFRICA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown, letterSpacing: 1.2)),
                      pw.Text('EVENT REPORT', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, letterSpacing: 1)),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(6)),
                        child: pw.Text(event.category.label.toUpperCase(),
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                      ),
                      if (event.isHistory) ...[
                        pw.SizedBox(width: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(color: PdfColors.grey300, borderRadius: pw.BorderRadius.circular(6)),
                          child: pw.Text('COMPLETED',
                              style: pw.TextStyle(color: PdfColors.grey700, fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(event.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: brown)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Details grid
            pw.Row(children: [
              detailBlock('Date', '${event.date.day}/${event.date.month}/${event.date.year}'),
              detailBlock('Time', '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}'),
            ]),
            pw.SizedBox(height: 18),
            pw.Row(children: [
              detailBlock('Location / Venue', event.location),
              detailBlock('Organized By', event.organizer ?? '-'),
            ]),

            if (event.targetedParticipants != null && event.targetedParticipants!.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              pw.Text('TARGETED PARTICIPANTS', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500, letterSpacing: 0.8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: event.targetedParticipants!
                    .map((p) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _tint(kBrandOlive, 0.12),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(p, style: pw.TextStyle(fontSize: 10, color: olive, fontWeight: pw.FontWeight.bold)),
                ))
                    .toList(),
              ),
            ],

            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: olive, letterSpacing: 0.5)),
            pw.SizedBox(height: 8),
            pw.Text(
              event.description.isEmpty ? 'No description provided.' : event.description,
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 3, color: PdfColors.grey800),
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                pw.Text('AGE Africa - Scholar Management System', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc;
}

/// Opens the native print dialog (which also offers "Save as PDF") for the
/// given event's report.
Future<void> printEventReport(OrganisationEvent event) async {
  final doc = await buildEventReportPdf(event);
  await Printing.layoutPdf(
    onLayout: (format) => doc.save(),
    name: '${event.title} - Event Report',
  );
}

/// Directly downloads / shares the event report as a PDF file.
Future<void> downloadEventReport(OrganisationEvent event) async {
  final doc = await buildEventReportPdf(event);
  final bytes = await doc.save();
  final safeName = event.title.trim().isEmpty
      ? 'event_report'
      : event.title.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  await Printing.sharePdf(bytes: bytes, filename: '$safeName-report.pdf');
}


// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

class EventsComponent extends StatefulWidget {
  const EventsComponent({super.key});

  @override
  State<EventsComponent> createState() => _EventsComponentState();
}

class _EventsComponentState extends State<EventsComponent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final List<OrganisationEvent> _allEvents = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllEvents();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        _allEvents.clear();
        _allEvents.addAll(data.map((json) => OrganisationEvent.fromJson(json)).where((e) => !e.isExpired));

        _checkAndSendNotifications();
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkAndSendNotifications() {
    final now = DateTime.now();
    for (var event in _allEvents) {
      if (event.isUpcoming) {
        final diff = event.fullDateTime.difference(now);
        // If event is in less than 24 hours, "send notification" (mock)
        if (diff.inHours > 0 && diff.inHours <= 24) {
          debugPrint('NOTIFICATION: Reminder for event "${event.title}" tomorrow at ${event.time.format(context)}');
        } else if (diff.inMinutes > 0 && diff.inMinutes < 60) {
          debugPrint('NOTIFICATION: Urgent reminder! "${event.title}" starts in ${diff.inMinutes} minutes!');
        }
      }
    }
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => const EventFormDialog(),
    ).then((value) {
      if (value == true) {
        _fetchEvents();
      }
    });
  }

  void _showEditEventDialog(OrganisationEvent event) {
    showDialog(
      context: context,
      builder: (context) => EventFormDialog(event: event),
    ).then((value) {
      if (value == true) {
        _fetchEvents();
      }
    });
  }

  void _viewEventDetails(OrganisationEvent event) {
    Future.microtask(() {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ViewEventDialog(event: event),
        );
      }
    });
  }

  Future<void> _deleteEvent(OrganisationEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the event "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteEvent(event.id);
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.redAccent),
            );
          }
          _fetchEvents();
        }
      } catch (e) {
        debugPrint('Error deleting event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete event'), backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  List<OrganisationEvent> _filtered(List<OrganisationEvent> events) {
    if (_query.isEmpty) return events;
    return events.where((e) =>
    e.title.toLowerCase().contains(_query) ||
        e.location.toLowerCase().contains(_query) ||
        (e.organizer?.toLowerCase().contains(_query) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final upcomingEvents = _filtered(_allEvents.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime)));
    final historyEvents = _filtered(_allEvents.where((e) => e.isHistory).toList()
      ..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isDark),
        _buildStatsBar(isDark),
        _buildTabBarAndSearch(isDark, upcomingEvents.length, historyEvents.length),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : TabBarView(
            controller: _tabController,
            children: [
              _buildEventList(upcomingEvents, isDark, _query.isEmpty ? "No upcoming events scheduled" : "No events match your search"),
              _buildEventList(historyEvents, isDark, _query.isEmpty ? "No past events in history" : "No events match your search"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventList(List<OrganisationEvent> events, bool isDark, String emptyMessage) {
    if (events.isEmpty) {
      return _buildEmptyState(isDark, emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildEventCard(events[index], isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.05), Colors.transparent]
              : [kBrandCream.withValues(alpha: 0.25), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kBrandBrown, kBrandBrown.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: kBrandBrown.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Events & Programs',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('Organize, manage and track institutional activities and workshops.',
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text("Create Event"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isDark) {
    final upcoming = _allEvents.where((e) => e.isUpcoming).length;
    final completed = _allEvents.where((e) => e.isHistory).length;
    final thisWeek = _allEvents
        .where((e) => e.isUpcoming && e.fullDateTime.difference(DateTime.now()).inDays <= 7)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
      child: Row(
        children: [
          _statCard('Upcoming', upcoming.toString(), Icons.upcoming_rounded, kBrandOlive, isDark),
          const SizedBox(width: 16),
          _statCard('This week', thisWeek.toString(), Icons.today_rounded, Colors.blue, isDark),
          const SizedBox(width: 16),
          _statCard('Completed', completed.toString(), Icons.task_alt_rounded, kBrandBrown, isDark),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarAndSearch(bool isDark, int upcomingCount, int historyCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: kBrandOlive,
              unselectedLabelColor: isDark ? Colors.white38 : Colors.grey.shade600,
              indicatorColor: kBrandOlive,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: [
                Tab(text: 'Upcoming Events ($upcomingCount)'),
                Tab(text: 'Event History ($historyCount)'),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white38 : Colors.grey.shade500),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => _searchController.clear(),
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBrandOlive, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_note_outlined, size: 80, color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          const SizedBox(height: 24),
          Text(message,
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEventCard(OrganisationEvent event, bool isDark) {
    final isHistory = event.isHistory;
    final color = isHistory ? Colors.grey : event.category.color;

    return _HoverCard(
      onTap: () => _viewEventDetails(event),
      isDark: isDark,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(event.category.icon, size: 12, color: color),
                              const SizedBox(width: 6),
                              Text(
                                event.category.label.toUpperCase(),
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        if (isHistory) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'COMPLETED',
                              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                        ] else if (event.fullDateTime.difference(DateTime.now()).inHours <= 24) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'STARTING SOON',
                              style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '${event.date.day}/${event.date.month}/${event.date.year}',
                                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text(event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _buildInfoChip(Icons.location_on_rounded, event.location, isDark),
                        const SizedBox(width: 16),
                        _buildInfoChip(Icons.access_time_filled_rounded, event.time.format(context), isDark),
                        if (event.organizer != null) ...[
                          const SizedBox(width: 16),
                          _buildInfoChip(Icons.person_rounded, event.organizer!, isDark),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                border: Border(left: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    color: Colors.blue.shade400,
                    onPressed: () => _viewEventDetails(event),
                    tooltip: 'View Details',
                  ),
                  if (!isHistory) ...[
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.edit_note_rounded,
                      color: kBrandOlive,
                      onPressed: () => _showEditEventDialog(event),
                      tooltip: 'Edit Event',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: Icons.delete_sweep_rounded,
                    color: Colors.red.shade400,
                    onPressed: () => _deleteEvent(event),
                    tooltip: 'Delete Event',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kBrandOlive.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed, required String tooltip}) {
    return IconButton(
      icon: Icon(icon, size: 26),
      onPressed: onPressed,
      color: color.withValues(alpha: 0.8),
      tooltip: tooltip,
      hoverColor: color.withValues(alpha: 0.1),
      splashRadius: 28,
    );
  }
}

/// Wraps an event card with a subtle lift-on-hover effect.
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;
  const _HoverCard({required this.child, required this.onTap, required this.isDark});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovering ? 0.08 : 0.03),
                blurRadius: _hovering ? 24 : 15,
                offset: Offset(0, _hovering ? 10 : 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class ViewEventDialog extends StatefulWidget {
  final OrganisationEvent event;
  const ViewEventDialog({super.key, required this.event});

  @override
  State<ViewEventDialog> createState() => _ViewEventDialogState();
}

class _ViewEventDialogState extends State<ViewEventDialog> {
  bool _isPrinting = false;
  bool _isDownloading = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await printEventReport(widget.event);
    } catch (e) {
      debugPrint('Error printing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open print dialog'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      await downloadEventReport(widget.event);
    } catch (e) {
      debugPrint('Error downloading report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate PDF'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = event.isHistory ? Colors.grey : event.category.color;

    return Dialog(
      backgroundColor: theme.cardColor,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Category Color
            Container(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 30),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(event.category.icon, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              event.category.label.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                      if (event.isHistory) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white38 : Colors.grey.shade500),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : kBrandBrown,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timing and Location Section
                    Row(
                      children: [
                        _buildDetailItem(Icons.calendar_month_rounded, "Date", '${event.date.day}/${event.date.month}/${event.date.year}', isDark),
                        const SizedBox(width: 40),
                        _buildDetailItem(Icons.schedule_rounded, "Time", event.time.format(context), isDark),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDetailItem(Icons.place_rounded, "Location / Venue", event.location, isDark),

                    if (event.organizer != null) ...[
                      const SizedBox(height: 32),
                      _buildDetailItem(Icons.person_rounded, "Organized By", event.organizer!, isDark),
                    ],

                    if (event.targetedParticipants != null && event.targetedParticipants!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text("Targeted Participants",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                            letterSpacing: 0.8,
                          )),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.targetedParticipants!
                            .map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kBrandOlive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBrandOlive.withValues(alpha: 0.2)),
                          ),
                          child: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandOlive)),
                        ))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 32),

                    Text("Description",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kBrandOlive,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 12),
                    Text(
                      event.description.isEmpty ? "No description provided." : event.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print Report'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBrandBrown,
                      side: BorderSide(color: kBrandBrown.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _handleDownload,
                    icon: _isDownloading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: kBrandOlive.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white24 : Colors.grey.shade400,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class EventFormDialog extends StatefulWidget {
  final OrganisationEvent? event;
  const EventFormDialog({super.key, this.event});

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;

  late EventCategory _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _organizerController = TextEditingController(text: widget.event?.organizer ?? '');

    _selectedCategory = widget.event?.category ?? EventCategory.workshop;
    _selectedDate = widget.event?.date ?? DateTime.now();
    _selectedTime = widget.event?.time ?? TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.event == null ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory.name,
        'location': _locationController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'time': '${_selectedTime.hour}:${_selectedTime.minute}',
        'organizer': _organizerController.text.trim(),
      };

      final bool isUpdate = widget.event != null;
      final response = isUpdate
          ? await ApiService.updateEvent(widget.event!.id, data)
          : await ApiService.createEvent(data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpdate ? 'Event updated successfully' : 'Event created successfully'),
              backgroundColor: kBrandOlive,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Error saving event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error: Failed to save event'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.event != null;

    return Dialog(
      backgroundColor: theme.cardColor,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 900),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBrandOlive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(isEdit ? Icons.edit_calendar_rounded : Icons.add_task_rounded, color: kBrandOlive, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Text(isEdit ? 'Edit Event Details' : 'Create New Event',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                      controller: _titleController,
                      label: 'Event Title',
                      icon: Icons.title_rounded,
                      isDark: isDark,
                      theme: theme,
                      validator: (v) => v!.isEmpty ? 'Event title is required' : null),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descController,
                    label: 'Description',
                    icon: Icons.notes_rounded,
                    isDark: isDark,
                    theme: theme,
                    maxLines: 4,
                    hint: 'Describe the purpose and details of the event...',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField(isDark, theme)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(
                          controller: _organizerController,
                          label: 'Organizer',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                      controller: _locationController,
                      label: 'Location / Venue',
                      icon: Icons.place_rounded,
                      isDark: isDark,
                      theme: theme,
                      validator: (v) => v!.isEmpty ? 'Location is required' : null),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.calendar_month_rounded,
                          label: 'Date',
                          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          onTap: _pickDate,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPickerTile(
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                          value: _selectedTime.format(context),
                          onTap: _pickTime,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Discard Changes', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          elevation: 8,
                          shadowColor: kBrandOlive.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                            : Text(isEdit ? 'Update Event' : 'Save Event', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(icon, size: 22, color: isDark ? Colors.white38 : kBrandBrown.withValues(alpha: 0.5)),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }

  Widget _buildDropdownField(bool isDark, ThemeData theme) {
    return DropdownButtonFormField<EventCategory>(
      initialValue: _selectedCategory,
      dropdownColor: theme.cardColor,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.category_rounded, size: 22, color: isDark ? Colors.white38 : kBrandBrown.withValues(alpha: 0.5)),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
      items: EventCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.label))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kBrandOlive.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: kBrandOlive),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}