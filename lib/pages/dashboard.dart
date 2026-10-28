import 'dart:convert';

import 'package:attendo/config/api_config.dart';
import 'package:attendo/pages/registar_student.dart';
import 'package:attendo/pages/take_attendance.dart';
import 'package:attendo/pages/view_attendance.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ── Colour palette ──────────────────────────────────────────
const _bg = Color(0xFF0D0D1A); // deep navy-black
const _surface = Color(0xFF161628); // card surface
const _accent = Color(0xFF7C3AED); // vivid violet
const _accentLight = Color(0xFF9F67FF); // lighter violet
const _accentGlow = Color(0x337C3AED); // violet glow (20 %)
const _green = Color(0xFF10B981); // present – emerald
const _red = Color(0xFFEF4444); // absent – red
const _textPrimary = Color(0xFFF1F0FF);
const _textSecondary = Color(0xFF8B8BA0);
// ────────────────────────────────────────────────────────────

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static String get _baseUrl => ApiConfig.baseUrl;

  int presentCount = 0;
  int absentCount = 0;
  int totalCount = 0;
  bool loadingStats = true;

  @override
  void initState() {
    super.initState();
    fetchTodayStats();
  }

  String _todayDate() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> fetchTodayStats() async {
    setState(() => loadingStats = true);

    try {
      final uri = Uri.parse('$_baseUrl/api/attendance?date=${_todayDate()}');

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List list = data['attendance'] ?? [];
        setState(() {
          presentCount = list.where((s) => s['status'] == 'Present').length;
          absentCount = list.where((s) => s['status'] == 'Absent').length;
          totalCount = list.length;
        });
      }
    } catch (_) {
      // server unreachable — leave counts at 0
    } finally {
      setState(() => loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accent, _accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Attendo",
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: fetchTodayStats,
            icon: const Icon(Icons.refresh_rounded, color: _accentLight),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _surface,
              child: const Icon(
                Icons.person_rounded,
                color: _accentLight,
                size: 20,
              ),
            ),
          ),
        ],
      ),

      // ── Body ─────────────────────────────────────────────
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              const Text(
                "Teacher Dashboard",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Manage your classroom attendance",
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),

              const SizedBox(height: 28),

              // ── Today's summary card ───────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), _accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: _accentGlow,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Today's Attendance",
                          style: TextStyle(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: loadingStats
                          ? [
                              const Expanded(
                                child: Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          : [
                              _StatChip(
                                label: "Present",
                                value: "$presentCount",
                                color: _green,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: "Absent",
                                value: "$absentCount",
                                color: _red,
                              ),
                              const SizedBox(width: 12),
                              _StatChip(
                                label: "Total",
                                value: "$totalCount",
                                color: Colors.white,
                              ),
                            ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Quick actions label ────────────────────
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 16),

              // ── Action cards ───────────────────────────
              _ActionCard(
                icon: Icons.camera_alt_rounded,
                title: "Take Attendance",
                subtitle: "Mark today's student attendance",
                iconBg: const Color(0xFF1A0A3B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeAttendance()),
                ),
              ),

              const SizedBox(height: 14),

              _ActionCard(
                icon: Icons.person_add_rounded,
                title: "Register Student",
                subtitle: "Add a new student to your class",
                iconBg: const Color(0xFF0A1F3B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterStudent()),
                ),
              ),

              const SizedBox(height: 14),

              _ActionCard(
                icon: Icons.bar_chart_rounded,
                title: "View Attendance",
                subtitle: "Check attendance records and history",
                iconBg: const Color(0xFF0A2B1F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAttendance()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat chip inside the summary card ───────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action card ──────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    
    required this.subtitle,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: _accentGlow,
        highlightColor: _accentGlow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              // ignore: deprecated_member_use
              color: _accent.withOpacity(0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: _accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: _accentLight, size: 26),
              ),

              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _accentLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
