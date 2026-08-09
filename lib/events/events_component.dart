import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/permission_service.dart';
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
                color: _pdf(kBrandCream.withOpacity(0.3)),
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

            pw.SizedBox(height: 40),
            pw.Text('PROGRAM DESCRIPTION & OBJECTIVES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: olive, letterSpacing: 0.5)),
            pw.SizedBox(height: 12),
            pw.Text(
              event.description.isEmpty ? 'No detailed description provided.' : event.description,
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
  bool _isSearchExpanded = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = PermissionService.userRole == 'Administrator';
    _tabController = TabController(length: _isAdmin ? 3 : 2, vsync: this);
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
            .where((e) => !e.isExpired));
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

  void _viewEventDetails(OrganisationEvent event) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ViewEventDialog(
        event: event,
        onStatusChanged: _fetchEvents,
      ),
    );
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0F2F5), // Facebook-style background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExecutiveHeader(isMobile),
          _buildToolbar(isMobile),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive, strokeWidth: 3))
                : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(_filtered(_allEvents.where((e) => e.isUpcoming).toList()..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime))), "No upcoming events.", isMobile),
                _buildEventList(_filtered(_allEvents.where((e) => e.isHistory).toList()..sort((a, b) => b.fullDateTime.compareTo(a.fullDateTime))), "No event history.", isMobile),
                if (_isAdmin)
                  _buildEventList(_filtered(_allEvents.where((e) => e.isPending).toList()..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime))), "No events awaiting approval.", isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isMobile) {
    if (isMobile && _isSearchExpanded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search programs...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: () => setState(() {
                _isSearchExpanded = false;
                _searchController.clear();
                _query = '';
              }),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Events & Programs", 
                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/events/liveMeeting'),
            icon: const Icon(Icons.video_call_rounded, size: 18),
            label: const Text("LIVE MEETING", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _showCreateEventDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: isMobile ? Size.zero : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 18),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  const Text("CREATE EVENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 8 : 20),
      child: isMobile 
        ? Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: kBrandOlive,
                  unselectedLabelColor: Colors.grey.shade400,
                  indicatorColor: kBrandOlive,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  tabs: [
                    const Tab(text: 'UPCOMING'),
                    const Tab(text: 'HISTORY'),
                    if (_isAdmin) const Tab(text: 'PENDING'),
                  ],
                ),
              ),
            ],
          )
        : Row(
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
                  tabs: [
                    const Tab(text: 'UPCOMING PROGRAMS'),
                    const Tab(text: 'ARCHIVE & HISTORY'),
                    if (_isAdmin) const Tab(text: 'PENDING APPROVAL'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title or venue...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildEventList(List<OrganisationEvent> events, String emptyMessage, bool isMobile) {
    if (events.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildEventCard(events[index], isMobile),
    );
  }

  Widget _buildEventCard(OrganisationEvent event, bool isMobile) {
    final isHistory = event.isHistory;
    final isPending = event.isPending;
    final color = isHistory ? Colors.grey.shade400 : (isPending ? Colors.orange : event.category.color);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
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
                Container(
                  width: isMobile ? 70 : 100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('MMM').format(event.date).toUpperCase(),
                        style: TextStyle(color: color, fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text(DateFormat('dd').format(event.date),
                        style: TextStyle(color: kBrandBrown, fontSize: isMobile ? 22 : 32, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(event.category.label.toUpperCase(),
                                style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ),
                            const SizedBox(width: 8),
                            Text(event.time.format(context),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                            if (isPending) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: const Text("PENDING APPROVAL", style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(child: Text(event.location,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(
                    child: Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ViewEventDialog extends StatefulWidget {
  final OrganisationEvent event;
  final VoidCallback? onStatusChanged;
  const ViewEventDialog({super.key, required this.event, this.onStatusChanged});

  @override
  State<ViewEventDialog> createState() => _ViewEventDialogState();
}

class _ViewEventDialogState extends State<ViewEventDialog> {
  bool _isPrinting = false;
  bool _isDownloading = false;
  bool _isApproving = false;
  bool _isDeleting = false;

  Future<void> _handleApprove() async {
    setState(() => _isApproving = true);
    try {
      final res = await ApiService.approveEvent(widget.event.id);
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event approved successfully."), backgroundColor: kBrandOlive),
          );
          Navigator.pop(context);
          if (widget.onStatusChanged != null) widget.onStatusChanged!();
        }
      }
    } catch (e) {
      debugPrint('Error approving event: $e');
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event', style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text('Are you sure you want to delete "${widget.event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final res = await ApiService.deleteEvent(widget.event.id);
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event deleted."), backgroundColor: Colors.red),
          );
          Navigator.pop(context);
          if (widget.onStatusChanged != null) widget.onStatusChanged!();
        }
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPending = event.isPending;
    final isAdmin = PermissionService.userRole == 'Administrator';
    final color = event.isHistory ? Colors.grey : (isPending ? Colors.orange : event.category.color);
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 40),
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
                          Text(event.title, style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(isPending ? "AWAITING APPROVAL" : event.category.label.toUpperCase(), 
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.grey)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 20 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _executiveDetailGrid(event, isMobile),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 40),
                    const Text("PROGRAM OVERVIEW", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Text(event.description.isEmpty ? "No description provided." : event.description,
                        style: const TextStyle(fontSize: 13, height: 1.6, color: kBrandBrown)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 20 : 32),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: const Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
                child: Column(
                  children: [
                    if (isPending && isAdmin) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDeleting ? null : _handleDelete,
                              icon: _isDeleting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline_rounded),
                              label: const Text("REJECT & DELETE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isApproving ? null : _handleApprove,
                              icon: _isApproving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded),
                              label: const Text("APPROVE EVENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                              style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!isPending)
                      isMobile 
                        ? Column(
                            children: [
                              _buildActionBtn(isMobile: true, onPressed: _isDownloading ? null : () async {
                                setState(() => _isDownloading = true);
                                await downloadEventReport(event);
                                setState(() => _isDownloading = false);
                              }, isLoading: _isDownloading, icon: Icons.download_rounded, label: "DOWNLOAD PDF", isPrimary: true),
                              const SizedBox(height: 12),
                              _buildActionBtn(isMobile: true, onPressed: _isPrinting ? null : () async {
                                setState(() => _isPrinting = true);
                                await printEventReport(event);
                                setState(() => _isPrinting = false);
                              }, isLoading: _isPrinting, icon: Icons.print_rounded, label: "PRINT TRANSCRIPT", isPrimary: false),
                            ],
                          )
                        : Row(
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
                                  style: OutlinedButton.styleFrom(foregroundColor: kBrandBrown, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                                  style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                ),
                              ),
                            ],
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

  Widget _buildActionBtn({required bool isMobile, required VoidCallback? onPressed, required bool isLoading, required IconData icon, required String label, required bool isPrimary}) {
    final btnStyle = isPrimary 
      ? ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
      : OutlinedButton.styleFrom(foregroundColor: kBrandBrown, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)));

    final content = [
      if (isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      else Icon(icon, size: 18),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
    ];

    return SizedBox(width: double.infinity, child: isPrimary ? ElevatedButton(onPressed: onPressed, style: btnStyle, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: content)) : OutlinedButton(onPressed: onPressed, style: btnStyle, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: content)));
  }

  Widget _executiveDetailGrid(OrganisationEvent s, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth > 500 && !isMobile) ? (constraints.maxWidth - 40) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: isMobile ? 0 : 40,
          runSpacing: isMobile ? 24 : 32,
          children: [
            _detailItem(Icons.calendar_today_rounded, "DATE", DateFormat('EEEE, dd MMM yyyy').format(s.date), itemWidth),
            _detailItem(Icons.access_time_rounded, "TIME", s.time.format(context), itemWidth),
            _detailItem(Icons.location_on_outlined, "VENUE", s.location, itemWidth),
            _detailItem(Icons.person_pin_rounded, "ORGANIZER", s.organizer ?? 'Program Office', itemWidth),
          ],
        );
      }
    );
  }

  Widget _detailItem(IconData icon, String label, String value, double width) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kBrandOlive.withOpacity(0.6)),
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
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
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
        'time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'organizer': _organizerController.text.trim(),
        'status': widget.event?.status ?? (PermissionService.userRole == 'Administrator' ? 'Active' : 'Pending'),
      };
      final res = widget.event != null ? await ApiService.updateEvent(widget.event!.id, data) : await ApiService.createEvent(data);
      if (res.statusCode == 200 || res.statusCode == 201) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.event == null ? 'New Event' : 'Edit Event', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildField(_titleController, 'Title', Icons.title, true),
                const SizedBox(height: 16),
                _buildField(_descController, 'Description', Icons.description, false, maxLines: 3),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildField(_locationController, 'Venue', Icons.place, true),
                const SizedBox(height: 16),
                _buildField(_organizerController, 'Organizer', Icons.person, false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _pickerTile(Icons.calendar_today, "DATE", DateFormat('dd MMM').format(_selectedDate), _pickDate, isMobile)),
                    const SizedBox(width: 12),
                    Expanded(child: _pickerTile(Icons.access_time, "TIME", _selectedTime.format(context), _pickTime, isMobile)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandOlive, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE EVENT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<EventCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(_selectedCategory.icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: EventCategory.values.map((c) => DropdownMenuItem(
        value: c,
        child: Text(c.label),
      )).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategory = val);
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool req, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, 
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
      ), 
      validator: req ? (v) => v!.isEmpty ? 'Req' : null : null
    );
  }

  Widget _pickerTile(IconData icon, String label, String value, VoidCallback onTap, bool isMobile) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])));
  }
}
