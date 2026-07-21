import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../academics/academicsUtils.dart';
import 'eventsUtils.dart';

class EventsComponent extends StatefulWidget {
  const EventsComponent({super.key});

  @override
  State<EventsComponent> createState() => _EventsComponentState();
}

class _EventsComponentState extends State<EventsComponent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  final List<OrganisationEvent> _allEvents = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final upcomingEvents = _allEvents.where((e) => e.isUpcoming).toList();
    final historyEvents = _allEvents.where((e) => e.isHistory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isDark),
        TabBar(
          controller: _tabController,
          labelColor: kBrandOlive,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.grey.shade600,
          indicatorColor: kBrandOlive,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Upcoming Events'),
            Tab(text: 'Event History'),
          ],
        ),
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList(upcomingEvents, isDark, "No upcoming events scheduled"),
                    _buildEventList(historyEvents, isDark, "No past events in history"),
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
      padding: const EdgeInsets.all(24),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildEventCard(events[index], isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.white.withValues(alpha: 0.05), Colors.transparent]
            : [kBrandCream.withValues(alpha: 0.2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBrown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available_rounded, color: kBrandBrown, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Events & Programs', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.5)),
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
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400, 
              fontSize: 18, 
              fontWeight: FontWeight.w500
            )
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(OrganisationEvent event, bool isDark) {
    final isHistory = event.isHistory;
    final color = isHistory ? Colors.grey : event.category.color;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: color,
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
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey.shade600, 
                            fontSize: 14, 
                            height: 1.4
                          )
                        ),
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
                      if (!isHistory)
                        _buildActionButton(
                          icon: Icons.edit_note_rounded,
                          color: kBrandOlive,
                          onPressed: () => _showEditEventDialog(event),
                          tooltip: 'Edit Event',
                        ),
                      const SizedBox(height: 12),
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
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade500, 
            fontSize: 13,
            fontWeight: FontWeight.w500
          )
        ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                    validator: (v) => v!.isEmpty ? 'Event title is required' : null
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descController, 
                    label: 'Description', 
                    icon: Icons.notes_rounded, 
                    isDark: isDark, 
                    theme: theme,
                    maxLines: 4,
                    hint: 'Describe the purpose and details of the event...'
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
                    validator: (v) => v!.isEmpty ? 'Location is required' : null
                  ),
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
                        child: Text('Discard Changes', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontWeight: FontWeight.bold))
                      ),
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
    String? Function(String?)? validator
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kBrandOlive, width: 2)),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kBrandOlive, width: 2)),
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
