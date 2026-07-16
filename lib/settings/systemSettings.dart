import 'package:flutter/material.dart';
import 'themeController.dart';

// ============================================================
// Shared Brand Color Palette
// ============================================================
const Color kBrandBrown = Color(0xFF4C3C32);
const Color kBrandCream = Color(0xFFFAF2DB);
const Color kBrandOlive = Color(0xFF9AB334);
const Color kBrandOrange = Color(0xFFE05B1C);

class SystemSettingsComponent extends StatefulWidget {
  const SystemSettingsComponent({super.key});

  @override
  State<SystemSettingsComponent> createState() => _SystemSettingsComponentState();
}

class _SystemSettingsComponentState extends State<SystemSettingsComponent> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _language = "English (Malawi)";
  String _currency = "Malawian Kwacha (MWK)";

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Gradient Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kBrandBrown, kBrandOlive]),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Configure application preferences and appearance.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Appearance & Theme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeController,
                    builder: (context, mode, _) {
                      return Column(
                        children: [
                          _buildThemeOption(
                            title: "System Default",
                            subtitle: "Matches your device's system theme",
                            icon: Icons.brightness_auto_rounded,
                            isSelected: mode == ThemeMode.system,
                            onTap: () => themeController.value = ThemeMode.system,
                          ),
                          const SizedBox(height: 12),
                          _buildThemeOption(
                            title: "Light Mode",
                            subtitle: "Bright and clear interface",
                            icon: Icons.light_mode_rounded,
                            isSelected: mode == ThemeMode.light,
                            onTap: () => themeController.value = ThemeMode.light,
                          ),
                          const SizedBox(height: 12),
                          _buildThemeOption(
                            title: "Dark Mode",
                            subtitle: "Dark interface to reduce eye strain",
                            icon: Icons.dark_mode_rounded,
                            isSelected: mode == ThemeMode.dark,
                            onTap: () => themeController.value = ThemeMode.dark,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text("General Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    title: "Push Notifications",
                    subtitle: "Receive alerts for program activities",
                    icon: Icons.notifications_active_outlined,
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    title: "Biometric Authentication",
                    subtitle: "Secure access using Fingerprint/FaceID",
                    icon: Icons.fingerprint_rounded,
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile(
                    title: "Primary Language",
                    value: _language,
                    icon: Icons.translate_rounded,
                    options: ["English (Malawi)", "Chichewa", "English (UK)"],
                    onChanged: (v) => setState(() => _language = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownTile(
                    title: "Regional Currency",
                    value: _currency,
                    icon: Icons.monetization_on_outlined,
                    options: ["Malawian Kwacha (MWK)", "US Dollar (USD)"],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "App Version: 2.1.0-build.88\nAGE Africa © 2026",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kBrandOlive.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kBrandOlive : Colors.grey.shade200, width: isSelected ? 2 : 1),
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
            if (isSelected) const Icon(Icons.check_circle_rounded, color: kBrandOlive),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        secondary: Icon(icon, color: kBrandBrown, size: 22),
        value: value,
        activeColor: kBrandOlive.withValues(alpha: 0.8),
        activeTrackColor: kBrandOlive.withValues(alpha: 0.3),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kBrandBrown, size: 20),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
