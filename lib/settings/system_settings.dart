import 'package:flutter/material.dart';
import 'theme_controller.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import '../widgets/custom_loaders.dart';

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
    if (!mounted) return;
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
            Translator.currentLanguage = _language;
            _currency = data['currency'] ?? "Malawian Kwacha (MWK)";
            
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
      debugPrint('Error fetching system settings: $e');
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
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isLoading 
        ? const Center(child: BeautifulLoader(isOverlay: false, message: "Syncing Environment"))
        : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildExecutiveHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("VISUAL ENVIRONMENT"),
                        const SizedBox(height: 24),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeController,
                          builder: (context, mode, _) {
                            return Row(
                              children: [
                                Expanded(child: _buildThemeCard("Adaptive", "System Default", Icons.brightness_auto_rounded, mode == ThemeMode.system, () {
                                  themeController.value = ThemeMode.system;
                                  _updateSettings({'theme': 'system'});
                                })),
                                const SizedBox(width: 24),
                                Expanded(child: _buildThemeCard("Standard", "Light Mode", Icons.light_mode_rounded, mode == ThemeMode.light, () {
                                  themeController.value = ThemeMode.light;
                                  _updateSettings({'theme': 'light'});
                                })),
                                const SizedBox(width: 24),
                                Expanded(child: _buildThemeCard("Contrast", "Dark Mode", Icons.dark_mode_rounded, mode == ThemeMode.dark, () {
                                  themeController.value = ThemeMode.dark;
                                  _updateSettings({'theme': 'dark'});
                                })),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 48),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInteractionPreferences()),
                            const SizedBox(width: 40),
                            Expanded(child: _buildRegionalSettings()),
                          ],
                        ),

                        const SizedBox(height: 60),
                        Center(
                          child: Column(
                            children: [
                              Text("Scholar Management System (Core Engine)",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : kBrandBrown, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              const Text("Deployment v2.4.12 • All rights reserved • 2026",
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildExecutiveHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    bool isChichewa = _language == "Chichewa";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : kBrandBrown).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.settings_suggest_rounded, color: isDark ? Colors.white : kBrandBrown, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isChichewa ? "Makonzedwe a Kachitidwe" : "Environment Settings",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.5)),
                Text(isChichewa ? "Konshani momwe pulogalamuyi ikugwirira ntchito." : "Configure terminal behavior and interfaces.",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(String label, String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isSelected
            ? (isDark ? theme.colorScheme.primaryContainer : kBrandBrown)
            : (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
              ? (isDark ? theme.colorScheme.primary : kBrandBrown)
              : theme.dividerColor,
            width: 1.5
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: (isDark ? theme.colorScheme.primary : kBrandBrown).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)
            )
          ] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                  ? Colors.white.withValues(alpha: 0.15)
                  : (isDark ? Colors.white12 : kBrandBrown.withValues(alpha: 0.05)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white70 : kBrandBrown), size: 28),
            ),
            const SizedBox(height: 20),
            Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white70 : Colors.grey,
                letterSpacing: 1.5
              )),
            const SizedBox(height: 4),
            Text(title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.white : kBrandBrown)
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionPreferences() {
    bool isChichewa = _language == "Chichewa";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(isChichewa ? "KAGWIRIDWE NTCHITO" : "INTERACTION POLICY"),
        const SizedBox(height: 24),
        _buildPreferenceTile(
          title: isChichewa ? "Zidziwitso za Nthawi Pomwepo" : "Real-time Notifications",
          subtitle: isChichewa ? "Landirani mauthenga a nkhani zaposachedwa." : "Receive telemetry alerts and activity logs.",
          icon: Icons.notifications_active_outlined,
          trailing: Switch(
            value: _notificationsEnabled,
            activeThumbColor: kBrandOlive,
            onChanged: (v) { setState(() => _notificationsEnabled = v); _updateSettings({'notifications_enabled': v}); },
          ),
        ),
        const SizedBox(height: 16),
        _buildPreferenceTile(
          title: isChichewa ? "Chitetezo cha Thupi" : "Biometric Authorization",
          subtitle: isChichewa ? "Gwiritsani ntchito zala kapena nkhope kutsegula." : "Use hardware keys for sensitive data access.",
          icon: Icons.fingerprint_rounded,
          trailing: Switch(
            value: _biometricEnabled,
            activeThumbColor: kBrandOlive,
            onChanged: (v) { setState(() => _biometricEnabled = v); _updateSettings({'biometric_enabled': v}); },
          ),
        ),
      ],
    );
  }

  Widget _buildRegionalSettings() {
    bool isChichewa = _language == "Chichewa";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(isChichewa ? "MAYENDEDWE A CHIYANKHULO" : "LOCALIZATION STANDARDS"),
        const SizedBox(height: 24),
        _buildPreferenceTile(
          title: isChichewa ? "Chiyankhulo cha Paface" : "Interface Language",
          subtitle: isChichewa ? "Sankhani chiyankhulo chomwe mukufuna kugwiritsa ntchito." : "Primary dictionary for standard text elements.",
          icon: Icons.translate_rounded,
          trailing: DropdownButton<String>(
            value: _language,
            underline: const SizedBox(),
            items: ["English (Malawi)", "Chichewa", "English (UK)"].map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (v) {
              setState(() {
                _language = v!;
                Translator.currentLanguage = v;
              });
              _updateSettings({'language': v});
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildPreferenceTile(
          title: isChichewa ? "Ndalama za M'derali" : "Financial Currency",
          subtitle: isChichewa ? "Sankhani ndalama zomwe zikuonekera pa ma ripoti." : "Standard denominator for disbursement logs.",
          icon: Icons.payments_outlined,
          trailing: DropdownButton<String>(
            value: _currency,
            underline: const SizedBox(),
            items: ["Malawian Kwacha (MWK)", "US Dollar (USD)"].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            onChanged: (v) { setState(() => _currency = v!); _updateSettings({'currency': v}); },
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceTile({required String title, required String subtitle, required IconData icon, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(icon, color: kBrandBrown, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandOlive.withValues(alpha: 0.8), letterSpacing: 1.5));
  }
}
