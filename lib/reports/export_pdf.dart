import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

class ExportPDFComponent extends StatefulWidget {
  const ExportPDFComponent({super.key});

  @override
  State<ExportPDFComponent> createState() => _ExportPDFComponentState();
}

class _ExportPDFComponentState extends State<ExportPDFComponent> {
  final List<String> _selectedItems = [];
  bool _isGenerating = false;

  void _toggleItem(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _generatePDF() async {
    if (_selectedItems.isEmpty) return;
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isGenerating = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF Report generated and saved to downloads.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSelectionArea(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildSettingsArea(),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PDF Export Portal', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Generate high-quality, print-ready PDF documents for stakeholders.',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Data Modules to Include", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 24),
          _moduleItem("Scholar Profiles & Summaries", "Personal details, status, and demographics.", Icons.people_outline),
          _moduleItem("Academic Performance Records", "Grades, GPA, and subject breakdown.", Icons.auto_graph),
          _moduleItem("Financial Support Details", "Payments made, pending fees, and donor info.", Icons.payments_outlined),
          _moduleItem("Institutional Context", "School standing and enrollment metrics.", Icons.apartment),
          _moduleItem("Attendance & Retention Stats", "Program engagement and health metrics.", Icons.event_available),
        ],
      ),
    );
  }

  Widget _moduleItem(String title, String subtitle, IconData icon) {
    final bool isSelected = _selectedItems.contains(title);
    return InkWell(
      onTap: () => _toggleItem(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kBrandOlive.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kBrandOlive : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? kBrandOlive : kBrandBrown)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Checkbox(value: isSelected, activeColor: kBrandOlive, onChanged: (v) => _toggleItem(title)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Document Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 24),
          _settingToggle("Include Brand Assets", true),
          _settingToggle("Add Digital Signature", false),
          _settingToggle("High-Resolution Charts", true),
          _settingToggle("Landscape Orientation", false),
        ],
      ),
    );
  }

  Widget _settingToggle(String label, bool initial) {
    bool value = initial;
    return StatefulBuilder(
      builder: (context, setState) => SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        value: value,
        activeThumbColor: kBrandOlive,
        onChanged: (v) => setState(() => value = v),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBrandBrown.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: kBrandBrown, size: 20),
          const SizedBox(width: 16),
          const Expanded(child: Text("Selected modules will be compiled into a single PDF document. Generation may take a few moments.", style: TextStyle(fontSize: 13, color: kBrandBrown))),
          const SizedBox(width: 24),
          SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: _selectedItems.isEmpty || _isGenerating ? null : _generatePDF,
              icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download_rounded),
              label: Text(_isGenerating ? "Processing..." : "Compile & Export PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
