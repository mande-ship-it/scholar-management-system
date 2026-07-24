import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';

class ExportExcelComponent extends StatefulWidget {
  const ExportExcelComponent({super.key});

  @override
  State<ExportExcelComponent> createState() => _ExportExcelComponentState();
}

class _ExportExcelComponentState extends State<ExportExcelComponent> {
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

  Future<void> _generateExcel() async {
    if (_selectedItems.isEmpty) return;
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isGenerating = false);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Excel Workbook generated and saved.")),
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
                child: _buildFormatArea(),
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
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.table_view_rounded, color: Colors.green, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Excel Export Portal', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
              SizedBox(height: 4),
              Text('Export raw data and structured tables for advanced spreadsheet analysis.',
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
          const Text("Select Datasets for Workbook", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 24),
          _datasetItem("Scholar Master List", "Full demographic data for all enrolled scholars.", Icons.list_alt_rounded),
          _datasetItem("Grade Matrix (All Terms)", "Complete academic records across all subjects.", Icons.grid_on_rounded),
          _datasetItem("Payment Ledger", "Detailed transaction history and disbursement logs.", Icons.account_balance_rounded),
          _datasetItem("Institution Database", "School contact info and institutional metrics.", Icons.apartment_rounded),
          _datasetItem("User Access Logs", "System engagement and administrative activities.", Icons.history_rounded),
        ],
      ),
    );
  }

  Widget _datasetItem(String title, String subtitle, IconData icon) {
    final bool isSelected = _selectedItems.contains(title);
    return InkWell(
      onTap: () => _toggleItem(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green.shade700 : kBrandBrown)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Checkbox(value: isSelected, activeColor: Colors.green, onChanged: (v) => _toggleItem(title)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatArea() {
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
          const Text("Export Options", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const SizedBox(height: 24),
          _optionItem("File Format", ".xlsx (Excel Workbook)"),
          _optionItem("Data Encoding", "UTF-8"),
          const Divider(height: 32),
          _checkboxOption("Include Calculated GPA", true),
          _checkboxOption("Apply Auto-Filtering", true),
          _checkboxOption("Add Data Validation", false),
        ],
      ),
    );
  }

  Widget _optionItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandBrown)),
        ],
      ),
    );
  }

  Widget _checkboxOption(String label, bool initial) {
    bool value = initial;
    return StatefulBuilder(
      builder: (context, setState) => CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        value: value,
        activeColor: Colors.green,
        onChanged: (v) => setState(() => value = v!),
        contentPadding: EdgeInsets.zero,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
          const SizedBox(width: 16),
          const Expanded(child: Text("Excel exports are optimized for Pivot Tables and advanced data analysis tools. Multiple sheets will be created for each selected dataset.", style: TextStyle(fontSize: 13, color: Colors.green))),
          const SizedBox(width: 24),
          SizedBox(
            width: 240,
            child: ElevatedButton.icon(
              onPressed: _selectedItems.isEmpty || _isGenerating ? null : _generateExcel,
              icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.grid_on_rounded),
              label: Text(_isGenerating ? "Exporting..." : "Generate Workbook"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
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
