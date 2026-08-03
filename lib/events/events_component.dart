import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'events_utils.dart';

// ---------------------------------------------------------------------------
// PDF report generation
// ---------------------------------------------------------------------------

pdf.PdfColor _pdf(Color color) => pdf.PdfColor.fromInt(color.toARGB32());

Future<pw.Document> buildEventReportPdf(OrganisationEvent event) async {
  final doc = pw.Document(
    title: '${event.title} - Event Report',
    author: 'AGE Africa',
  );

  final accent = _pdf(event.isHistory ? const Color(0xFF9E9E9E) : event.category.color);
  final brown = _pdf(kBrandBrown);
  final olive = _pdf(kBrandOlive);
  final cream = _pdf(kBrandCream);

  pw.MemoryImage? logoImage;
  try {
    final logoData = await rootBundle.load('assets/images/age-logo.png');
    logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  } catch (e) {
    debugPrint('Error loading logo for PDF: $e');
  }

  pw.Widget detailBlock(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 8, color: pdf.PdfColors.grey500, letterSpacing: 1, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown)),
        ],
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(50),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, height: 60)
                    else
                      pw.Text('AGE AFRICA', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.SizedBox(height: 8),
                    pw.Text('Advancing Girls\' Education in Africa', style: pw.TextStyle(fontSize: 10, color: olive, fontStyle: pw.FontStyle.italic)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('OFFICIAL EVENT REPORT', style: pw.TextStyle(fontSize: 10, color: pdf.PdfColors.grey600, letterSpacing: 1.5, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Ref: EVT-${event.id.padLeft(4, '0')}', style: pw.TextStyle(fontSize: 8, color: pdf.PdfColors.grey500)),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(event.category.label.toUpperCase(),
                          style: pw.TextStyle(color: pdf.PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: olive, thickness: 2),
            pw.SizedBox(height: 20),

            pw.Text(event.title, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: brown)),
            pw.SizedBox(height: 30),

            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _pdf(kBrandCream.withValues(alpha: 0.3)),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: cream),
              ),
              child: pw.Column(
                children: [
                  pw.Row(children: [
                    detailBlock('Scheduled Date', DateFormat('EEEE, dd MMMM yyyy').format(event.date)),
                    detailBlock('Scheduled Time', '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}'),
                  ]),
                  pw.SizedBox(height: 20),
                  pw.Row(children: [
                    detailBlock('Location / Venue', event.location),
                    detailBlock('Organizing Department', event.organizer ?? 'Program Management'),
                  ]),
                ],
              ),
            ),

            if (event.targetedParticipants != null && event.targetedParticipants!.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text('TARGETED PARTICIPANTS', style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey600, letterSpacing: 1, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.targetedParticipants!
                    .map((p) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: pdf.PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: pdf.PdfColors.grey300),
                  ),
                  child: pw.Text(p, style: pw.TextStyle(fontSize: 10, color: brown, fontWeight: pw.FontWeight.bold)),
                ))
                    .toList(),
              ),
            ],

            pw.SizedBox(height: 40),
            pw.Text('PROGRAM DESCRIPTION & OBJECTIVES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: olive, letterSpacing: 0.5)),
            pw.SizedBox(height: 12),
            pw.Text(
              event.description.isEmpty ? 'No detailed description provided for this session.' : event.description,
              style: pw.TextStyle(fontSize: 11, lineSpacing: 5, color: pdf.PdfColors.grey900),
              textAlign: pw.TextAlign.justify,
            ),

            pw.Spacer(),
            pw.Divider(color: pdf.PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by AGE Africa Management System on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: pdf.PdfColors.grey500)),
                pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 8, color: pdf.PdfColors.grey500)),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc;
}

Future<void> printEventReport(OrganisationEvent event) async {
  final doc = await buildEventReportPdf(event);
  await Printing.layoutPdf(
    onLayout: (format) => doc.save(),
    name: '${event.title.replaceAll(' ', '_')}_Report',
  );
}

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
        _allEvents.addAll(data
            .map((json) => OrganisationEvent.fromJson(json))
            .where((e) => e.status != 'Pending' && !e.isExpired));
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ViewEventDialog(event: event),
    );
  }

  Future<void> _deleteEvent(OrganisationEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text('Are you sure you want to permanently delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text('DELETE'),
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
              const SnackBar(content: Text('Event removed from system'), backgroundColor: kBrandBrown),
            );
          }
          _fetchEvents();
        }
      } catch (e) {
        debugPrint('Error deleting event: $e');
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(),
          _buildStatsBar(),
          _buildToolbar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(_filtered(_allEvents.where((e) => e.isUpcoming).toList()..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime))), "No upcoming events found."),
                _buildEventList(_filtered(_allEvents.where((e) => e.isHistory).toList()..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime))), "No event history recorded."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBrown.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Events & Programs", 
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -1.0)),
                Text("Manage workshops, mentorship sessions and institutional activities.", 
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text("CREATE EVENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final upcoming = _allEvents.where((e) => e.isUpcoming).length;
    final completed = _allEvents.where((e) => e.isHistory).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _summaryItem(Icons.schedule_rounded, "$upcoming Scheduled", kBrandOlive),
          const SizedBox(width: 32),
          _summaryItem(Icons.check_circle_outline_rounded, "$completed Completed", kBrandBrown),
          const Spacer(),
          Text(
            "Sync Status: Live",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kBrandBrown.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: const Color(0xFFF9FAFB),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: kBrandOlive,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: kBrandOlive,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              tabs: const [
                Tab(text: 'UPCOMING PROGRAMS'),
                Tab(text: 'ARCHIVE & HISTORY'),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title or venue...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<OrganisationEvent> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_note_rounded, size: 64, color: Colors.grey.shade200),
              ),
              const SizedBox(height: 24),
              Text(emptyMessage, 
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildEventCard(OrganisationEvent event) {
    final isHistory = event.isHistory;
    final color = isHistory ? Colors.grey.shade400 : event.category.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewEventDetails(event),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Calendar Style Date Tile
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    border: Border(right: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(event.date).toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd').format(event.date),
                        style: TextStyle(
                          color: kBrandBrown,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(event.category.icon, size: 12, color: color),
                                  const SizedBox(width: 6),
                                  Text(
                                    event.category.label.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              event.time.format(context),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: kBrandBrown,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.business_center_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                event.organizer ?? 'Program Office',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isHistory) ...[
                          _actionIcon(Icons.edit_note_rounded, kBrandOlive, () => _showEditEventDialog(event)),
                          const SizedBox(width: 8),
                        ],
                        _actionIcon(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteEvent(event)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final color = event.isHistory ? Colors.grey : event.category.color;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(event.category.label.toUpperCase(), 
                            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _executiveDetailGrid(event),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 40),
                    const Text("PROGRAM OVERVIEW & OBJECTIVES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Text(
                        event.description.isEmpty ? "No detailed description provided for this session." : event.description,
                        style: const TextStyle(fontSize: 14, height: 1.6, color: kBrandBrown),
                      ),
                    ),
                    if (event.targetedParticipants != null && event.targetedParticipants!.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      const Text("TARGETED AUDIENCE BY ROLE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.targetedParticipants!.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kBrandOlive.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBrandOlive.withValues(alpha: 0.1)),
                          ),
                          child: Text(p, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kBrandBrown)),
                        )).toList(),
                      ),
                    ],
                    if (event.externalParticipants != null && event.externalParticipants!.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      const Text("EXTERNAL GUESTS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.externalParticipants!.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kBrandOrange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBrandOrange.withValues(alpha: 0.1)),
                          ),
                          child: Text("${p['name']} (${p['email']})", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kBrandBrown)),
                        )).toList(),
                      ),
                    ],
                    if (event.internalParticipants != null && event.internalParticipants!.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      const Text("SPECIFIC INTERNAL USERS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      Text("${event.internalParticipants!.length} specific users have been invited to this session.",
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54)),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: const Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPrinting ? null : () async {
                          setState(() => _isPrinting = true);
                          await printEventReport(event);
                          setState(() => _isPrinting = false);
                        },
                        icon: _isPrinting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.print_rounded),
                        label: const Text("PRINT TRANSCRIPT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kBrandBrown,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : () async {
                          setState(() => _isDownloading = true);
                          await downloadEventReport(event);
                          setState(() => _isDownloading = false);
                        },
                        icon: _isDownloading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download_rounded),
                        label: const Text("DOWNLOAD PDF", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _executiveDetailGrid(OrganisationEvent s) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 500 ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 40,
          runSpacing: 32,
          children: [
            _detailItem(Icons.calendar_today_rounded, "SCHEDULED DATE", DateFormat('EEEE, dd MMM yyyy').format(s.date), width: itemWidth),
            _detailItem(Icons.access_time_rounded, "START TIME", s.time.format(context), width: itemWidth),
            _detailItem(Icons.location_on_outlined, "VENUE / LOCATION", s.location, width: itemWidth),
            _detailItem(Icons.person_pin_rounded, "ORGANIZED BY", s.organizer ?? 'Program Office', width: itemWidth),
          ],
        );
      }
    );
  }

  Widget _detailItem(IconData icon, String label, String value, {required double width}) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kBrandOlive.withValues(alpha: 0.6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kBrandBrown)),
              ],
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
  
  final TextEditingController _extNameController = TextEditingController();
  final TextEditingController _extEmailController = TextEditingController();

  late EventCategory _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSaving = false;
  
  // Selection States
  String _audienceType = "Users of the system"; // "Users of the system" or "Externals"
  
  final List<String> _targetedParticipants = [];
  final List<String> _availableRoles = [];
  
  final List<dynamic> _availableUsers = [];
  final List<String> _selectedInternalUserIds = [];
  final List<Map<String, String>> _externalParticipants = [];
  
  bool _isLoadingRoles = true;
  bool _isLoadingUsers = true;

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
    
    if (widget.event?.targetedParticipants != null) {
      _targetedParticipants.addAll(widget.event!.targetedParticipants!);
    } else {
      _targetedParticipants.add('All');
    }

    if (widget.event?.internalParticipants != null) {
      _selectedInternalUserIds.addAll(widget.event!.internalParticipants!);
    }
    
    if (widget.event?.externalParticipants != null && widget.event!.externalParticipants!.isNotEmpty) {
      _externalParticipants.addAll(widget.event!.externalParticipants!);
      _audienceType = "Externals";
    }
    
    _fetchRoles();
    _fetchUsers();
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await ApiService.getAllRoles();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];
        if (mounted) {
          setState(() {
            _availableRoles.clear();
            _availableRoles.add('All');
            _availableRoles.addAll(data.map((r) => r['name'].toString()).toList());
            _isLoadingRoles = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await ApiService.getAllUsers();
      if (response.statusCode == 200) {
        final dynamic rawData = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = rawData is List ? rawData : [];
        if (mounted) {
          setState(() {
            _availableUsers.clear();
            _availableUsers.addAll(data);
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    _extNameController.dispose();
    _extEmailController.dispose();
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

  void _addExternal() {
    final name = _extNameController.text.trim();
    final email = _extEmailController.text.trim();
    if (name.isNotEmpty && email.isNotEmpty) {
      if (email.contains('@')) {
        setState(() {
          _externalParticipants.add({'name': name, 'email': email});
          _extNameController.clear();
          _extEmailController.clear();
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final isInternal = _audienceType == "Users of the system";
      
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': _selectedCategory.name,
        'location': _locationController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'time': '${_selectedTime.hour}:${_selectedTime.minute}',
        'organizer': _organizerController.text.trim(),
        'targetedParticipants': isInternal ? _targetedParticipants : [],
        'internalParticipants': isInternal ? _selectedInternalUserIds : [],
        'externalParticipants': isInternal ? [] : _externalParticipants,
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
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Error saving event: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded, color: kBrandBrown, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(isEdit ? 'Modify Event Details' : 'Register New Event', 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 700;
                      
                      final leftColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(_titleController, 'Event Title / Name', Icons.title_rounded, required: true),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildDropdownField()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField(_organizerController, 'Organizer / Owner', Icons.person_outline_rounded)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(_locationController, 'Physical Location / Venue', Icons.place_rounded, required: true),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _pickerTile(Icons.calendar_today_rounded, "DATE", DateFormat('dd MMM yyyy').format(_selectedDate), _pickDate)),
                              const SizedBox(width: 16),
                              Expanded(child: _pickerTile(Icons.schedule_rounded, "TIME", _selectedTime.format(context), _pickTime)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(_descController, 'Detailed Description / Objectives', Icons.notes_rounded, maxLines: 4),
                        ],
                      );

                      final rightColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TARGET AUDIENCE SCOPE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text("System Users", style: TextStyle(fontSize: 12))),
                                  selected: _audienceType == "Users of the system",
                                  onSelected: (val) => setState(() => _audienceType = "Users of the system"),
                                  selectedColor: kBrandOlive.withValues(alpha: 0.2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text("Externals", style: TextStyle(fontSize: 12))),
                                  selected: _audienceType == "Externals",
                                  onSelected: (val) => setState(() => _audienceType = "Externals"),
                                  selectedColor: kBrandOlive.withValues(alpha: 0.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (_audienceType == "Users of the system") ...[
                            _buildParticipantSelector(),
                            const SizedBox(height: 32),
                            _buildInternalUserSelector(),
                          ] else ...[
                            _buildExternalParticipantForm(),
                          ],
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: leftColumn),
                            const SizedBox(width: 40),
                            Expanded(child: rightColumn),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftColumn,
                            const SizedBox(height: 32),
                            rightColumn,
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: const Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('DISCARD', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'SYNCHRONIZE UPDATES' : 'FINALIZE & NOTIFY', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, bool required = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: kBrandBrown.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<EventCategory>(
      isExpanded: true,
      initialValue: _selectedCategory,
      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrandBrown),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: Icon(Icons.category_rounded, size: 20, color: kBrandBrown.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
      ),
      items: EventCategory.values.map((cat) => DropdownMenuItem(
        value: cat, 
        child: Text(cat.label, overflow: TextOverflow.ellipsis)
      )).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildParticipantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TARGETED AUDIENCE BY ROLE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        if (_isLoadingRoles)
          const LinearProgressIndicator(color: kBrandOlive)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableRoles.map((role) {
              final isSelected = _targetedParticipants.contains(role);
              return FilterChip(
                label: Text(role, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: kBrandOlive.withValues(alpha: 0.2),
                checkmarkColor: kBrandOlive,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (selected) {
                  setState(() {
                    if (role == 'All') {
                      _targetedParticipants.clear();
                      _targetedParticipants.add('All');
                    } else {
                      _targetedParticipants.remove('All');
                      if (selected) {
                        _targetedParticipants.add(role);
                      } else {
                        _targetedParticipants.remove(role);
                      }
                      if (_targetedParticipants.isEmpty) _targetedParticipants.add('All');
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInternalUserSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SPECIFIC SYSTEM USERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        if (_isLoadingUsers)
          const LinearProgressIndicator(color: kBrandOlive)
        else
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              itemCount: _availableUsers.length,
              itemBuilder: (context, index) {
                final user = _availableUsers[index];
                final userId = (user['id'] ?? user['_id']).toString();
                final isSelected = _selectedInternalUserIds.contains(userId);
                
                return CheckboxListTile(
                  title: Text(user['full_name'] ?? user['fullName'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(user['role_name'] ?? 'Staff', style: const TextStyle(fontSize: 11)),
                  value: isSelected,
                  activeColor: kBrandOlive,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedInternalUserIds.add(userId);
                      } else {
                        _selectedInternalUserIds.remove(userId);
                      }
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExternalParticipantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EXTERNAL GUESTS / PARTICIPANTS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField(_extNameController, 'Name', Icons.person_outline)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField(_extEmailController, 'Email', Icons.alternate_email)),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addExternal,
              icon: const Icon(Icons.add_circle_rounded, color: kBrandOlive, size: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _externalParticipants.map((ext) => Chip(
            label: Text("${ext['name']} (${ext['email']})", style: const TextStyle(fontSize: 11)),
            onDeleted: () => setState(() => _externalParticipants.remove(ext)),
            deleteIconColor: Colors.red,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _pickerTile(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kBrandOlive.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(value, 
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrandBrown),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
