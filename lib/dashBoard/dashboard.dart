import 'package:flutter/material.dart';
import 'statistics.dart';
import 'virtualisation_predictions.dart';
import 'cyber_virtualisation.dart';

// Canonical Dashboard Colors
const Color kDashBrown = Color(0xFF4C3C32);
const Color kDashOlive = Color(0xFF9AB334);
const Color kDashOrange = Color(0xFFE05B1C);

class DashboardComponent extends StatefulWidget {
  const DashboardComponent({super.key});

  @override
  State<DashboardComponent> createState() => _DashboardComponentState();
}

class _DashboardComponentState extends State<DashboardComponent> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Neural Network Virtualisation
                  const CyberVirtualisationComponent(),
                  const SizedBox(height: 32),

                  // 2. Predictive Intelligence Layer
                  const VirtualisationPredictionsComponent(),
                  const SizedBox(height: 32),

                  // 3. Core Metrics
                  const Text(
                    "System Performance Analytics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kDashBrown, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  const StatisticsComponent(),
                  const SizedBox(height: 60),
                  _buildFooterBranding(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: kDashOlive.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "DASHBOARD",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: kDashOlive,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "System Live Command Center",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kDashBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildQuickStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildQuickStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusItem("Uptime", "99.9%", Icons.bolt_rounded, Colors.amber),
          const SizedBox(width: 20),
          _statusItem("Region", "MWI", Icons.public_rounded, kDashOlive),
          const SizedBox(width: 20),
          _statusItem("Load", "Low", Icons.speed_rounded, kDashOrange),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDashBrown)),
      ],
    );
  }

  Widget _buildFooterBranding() {
    return Center(
      child: Column(
        children: [
          Opacity(
            opacity: 0.1,
            child: Image.asset('assets/images/age-logo.png', height: 60),
          ),
          const SizedBox(height: 16),
          Text(
            "AGE AFRICA SCHOLAR MANAGEMENT PLATFORM • V1.2.0",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
