import 'package:flutter/material.dart';
import 'themeController.dart';

class SystemSettingsComponent extends StatelessWidget {
  const SystemSettingsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "System Settings",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Overview metrics and data visualization summaries.",
                style: TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),

              // ---- Appearance / Theme Toggle Section ----
              Text(
                "Appearance",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeController,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.indigo : Colors.orange,
                      ),
                      title: const Text("Dark Theme"),
                      subtitle: Text(isDark ? "Dark mode is on" : "Light mode is on"),
                      value: isDark,
                      onChanged: (value) {
                        ThemeControllerHelper.setDark(value);
                      },
                    ),
                  );
                },
              ),
              const Divider(height: 30),

              // ---- Existing metric cards ----
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Active Count", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 8),
                          Text("124", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pending Items", style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 8),
                          Text("12", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Chart placeholder ----
              Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Data Visual Chart Mock", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}