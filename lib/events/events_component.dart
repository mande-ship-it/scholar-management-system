import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'events_utils.dart';

// ---------------------------------------------------------------------------
// PDF report generation
// ---------------------------------------------------------------------------

PdfColor _pdf(Color color) => PdfColor.fromInt(color.value);

PdfColor _tint(Color color, double opacity) {
  final base = _pdf(color);
  return PdfColor(
    base.red + (1 - base.red) * (1 - opacity),
    base.green + (1 - base.green) * (1 - opacity),
    base.blue + (1 - base.blue) * (1 - opacity),
  );
}

Future<pw.Document> buildEventReportPdf(OrganisationEvent event) async {
  final doc = pw.Document(
    title: '${event.title} - Event Report',
    author: 'AGE Africa',
  );

  final accent = _pdf(event.isHistory ? const Color(0xFF9E9E9E) : event.category.color);
  final brown = _pdf(kBrandBrown);
  final olive = _pdf(kBrandOlive);
  final cream = _pdf(kBrandCream);

  // Load logo from assets
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
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, letterSpacing: 1, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brown)),
        ],
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(50),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Professional Header
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
                    pw.Text('OFFICIAL EVENT REPORT', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, letterSpacing: 1.5, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Ref: EVT-${event.id.padLeft(4, '0')}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(event.category.label.toUpperCase(),
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: olive, thickness: 2),
            pw.SizedBox(height: 20),

            // Event Title
            pw.Text(event.title, style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: brown)),
            pw.SizedBox(height: 30),

            // Details Grid
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
              pw.Text('TARGETED PARTICIPANTS', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, letterSpacing: 1, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.targetedParticipants!
                    .map((p) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
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
              style: pw.TextStyle(fontSize: 11, lineSpacing: 5, color: PdfColors.grey900),
              textAlign: pw.TextAlign.justify,
            ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by AGE Africa Management System on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
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
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to permanently delete "${event.title}"?'),
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildStatsBar(),
          _buildTabBarAndSearch(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
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

  Widget _buildEventList(List<OrganisationEvent> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandOlive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: kBrandOlive, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Events & Programs',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const SizedBox(height: 4),
                Text('Manage workshops, mentorship sessions and institutional activities.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text("New Event"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              elevation: 0,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
      child: Row(
        children: [
          _statItem('Scheduled', upcoming.toString(), kBrandOlive),
          const SizedBox(width: 32),
          _statItem('Completed', completed.toString(), kBrandBrown),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTabBarAndSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Upcoming Programs'),
                Tab(text: 'Archive & History'),
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
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(OrganisationEvent event) {
    final isHistory = event.isHistory;
    final color = isHistory ? Colors.grey.shade400 : event.category.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _viewEventDetails(event),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(event.category.icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(event.date).toUpperCase(),
                              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            const SizedBox(width: 12),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Text(
                              event.time.format(context),
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(event.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Text(event.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 24),
                            Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Text(event.organizer ?? 'Admin', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      _cardActionButton(Icons.visibility_outlined, Colors.blue, () => _viewEventDetails(event)),
                      const SizedBox(width: 8),
                      if (!isHistory) ...[
                        _cardActionButton(Icons.edit_note_rounded, kBrandOlive, () => _showEditEventDialog(event)),
                        const SizedBox(width: 8),
                      ],
                      _cardActionButton(Icons.delete_outline_rounded, Colors.redAccent, () => _deleteEvent(event)),
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

  Widget _cardActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        hoverColor: color.withValues(alpha: 0.1),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image/Color Area
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(event.category.label.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 32),
                    
                    // Key Details
                    _detailItem(Icons.calendar_today_rounded, "Date & Schedule", DateFormat('EEEE, dd MMMM yyyy').format(event.date)),
                    const SizedBox(height: 20),
                    _detailItem(Icons.access_time_rounded, "Session Time", event.time.format(context)),
                    const SizedBox(height: 20),
                    _detailItem(Icons.location_on_rounded, "Location / Venue", event.location),
                    const SizedBox(height: 20),
                    _detailItem(Icons.person_pin_rounded, "Organized By", event.organizer ?? 'Program Office'),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),

                    const Text("Program Description", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandOlive, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      event.description.isEmpty ? "No description provided." : event.description,
                      style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
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
                        label: const Text("Print Report"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kBrandBrown,
                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                        label: const Text("Download PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandOlive,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
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

  Widget _detailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: kBrandOlive),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
          ],
        ),
      ],
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
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? 'Edit Event' : 'Create New Event', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 32),
                  _buildTextField(_titleController, 'Event Title', Icons.title_rounded, validator: (v) => v!.isEmpty ? 'Title is required' : null),
                  const SizedBox(height: 20),
                  _buildTextField(_descController, 'Description', Icons.notes_rounded, maxLines: 3),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTextField(_organizerController, 'Organizer', Icons.person_outline_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(_locationController, 'Location / Venue', Icons.place_rounded, validator: (v) => v!.isEmpty ? 'Location is required' : null),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _pickerTile(Icons.calendar_today_rounded, "Date", DateFormat('dd/MM/yyyy').format(_selectedDate), _pickDate)),
                      const SizedBox(width: 16),
                      Expanded(child: _pickerTile(Icons.schedule_rounded, "Time", _selectedTime.format(context), _pickTime)),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 16),
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
                            : Text(isEdit ? 'Update Details' : 'Register Event', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: kBrandOlive),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<EventCategory>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_rounded, size: 20, color: kBrandOlive),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: EventCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.label))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _pickerTile(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kBrandOlive),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
