import 'package:flutter/material.dart';
import 'themeController.dart';
import '../services/api_service.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getUserSettings();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _notificationsEnabled = data['notifications_enabled'] ?? true;
            _biometricEnabled = data['biometric_enabled'] ?? false;
            _language = data['language'] ?? "English (Malawi)";
            _currency = data['currency'] ?? "Malawian Kwacha (MWK)";
            
            // Sync theme controller if theme is stored in backend
            if (data['theme'] == 'dark') {
              themeController.value = ThemeMode.dark;
            } else if (data['theme'] == 'light') {
              themeController.value = ThemeMode.light;
            } else {
              themeController.value = ThemeMode.system;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> delta) async {
    try {
      await ApiService.updateUserSettings(delta);
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        : SingleChildScrollView(
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
                  Text("Appearance & Theme", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
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
                            onTap: () {
                              themeController.value = ThemeMode.system;
                              _updateSettings({'theme': 'system'});
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildThemeOption(
                            title: "Light Mode",
                            subtitle: "Bright and clear interface",
                            icon: Icons.light_mode_rounded,
                            isSelected: mode == ThemeMode.light,
                            onTap: () {
                              themeController.value = ThemeMode.light;
                              _updateSettings({'theme': 'light'});
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildThemeOption(
                            title: "Dark Mode",
                            subtitle: "Dark interface to reduce eye strain",
                            icon: Icons.dark_mode_rounded,
                            isSelected: mode == ThemeMode.dark,
                            onTap: () {
                              themeController.value = ThemeMode.dark;
                              _updateSettings({'theme': 'dark'});
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  Text("General Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? theme.colorScheme.primary : kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    title: "Push Notifications",
                    subtitle: "Receive alerts for program activities",
                    icon: Icons.notifications_active_outlined,
                    value: _notificationsEnabled,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      _updateSettings({'notificationsEnabled': v});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    title: "Biometric Authentication",
                    subtitle: "Secure access using Fingerprint/FaceID",
                    icon: Icons.fingerprint_rounded,
                    value: _biometricEnabled,
                    onChanged: (v) {
                      setState(() => _biometricEnabled = v);
                      _updateSettings({'biometricEnabled': v});
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile(
                    title: "Primary Language",
                    value: _language,
                    icon: Icons.translate_rounded,
                    options: ["English (Malawi)", "Chichewa", "English (UK)"],
                    onChanged: (v) {
                      setState(() => _language = v!);
                      _updateSettings({'language': v});
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownTile(
                    title: "Regional Currency",
                    value: _currency,
                    icon: Icons.monetization_on_outlined,
                    options: ["Malawian Kwacha (MWK)", "US Dollar (USD)"],
                    onChanged: (v) {
                      setState(() => _currency = v!);
                      _updateSettings({'currency': v});
                    },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? kBrandOlive.withValues(alpha: 0.1) 
            : (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kBrandOlive : theme.dividerColor, 
            width: isSelected ? 2 : 1
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kBrandOlive : (isDark ? Colors.white70 : Colors.grey)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? kBrandOlive : (isDark ? Colors.white : kBrandBrown))),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        secondary: Icon(icon, color: isDark ? Colors.white70 : kBrandBrown, size: 22),
        value: value,
        activeThumbColor: kBrandOlive,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? Colors.white70 : kBrandBrown, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandBrown, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            dropdownColor: theme.cardColor,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.cardColor,
            ),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
