import 'dart:convert';

import 'package:attendo/config/api_config.dart';
import 'package:attendo/pages/add_connection.dart';
import 'package:attendo/pages/registar_student.dart';
import 'package:attendo/pages/take_attendance.dart';
import 'package:attendo/pages/view_attendance.dart';
import 'package:attendo/widgets/action_card.dart';
import 'package:attendo/widgets/app_color.dart';
import 'package:attendo/widgets/statchip.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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
      backgroundColor: AppColor.bg,

      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColor.bg,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColor.accent, AppColor.accentLight],
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
                color: AppColor.textPrimary,
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
            icon: const Icon(Icons.refresh_rounded, color: AppColor.accentLight),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColor.surface,
              child: const Icon(
                Icons.person_rounded,
                color: AppColor.accentLight,
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
                  color: AppColor.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Manage your classroom attendance",
                style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
              ),

              const SizedBox(height: 28),

              // ── Today's summary card ───────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4C1D95), AppColor.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColor.accentGlow,
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
                              StatChip(
                                label: "Present",
                                value: "$presentCount",
                                color: AppColor.green,
                              ),
                              const SizedBox(width: 12),
                              StatChip(
                                label: "Absent",
                                value: "$absentCount",
                                color: AppColor.red,
                              ),
                              const SizedBox(width: 12),
                              StatChip(
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
                  color: AppColor.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 16),

              // ── Action cards ───────────────────────────
              ActionCard(
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

              ActionCard(
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

              ActionCard(
                icon: Icons.bar_chart_rounded,
                title: "View Attendance",
                subtitle: "Check attendance records and history",
                iconBg: const Color(0xFF0A2B1F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAttendance()),
                ),
              ),

              const SizedBox(height: 14),

              ActionCard(
                icon: Icons.settings,
                title: "Add Connection",
                subtitle: "Establish a connection to the backend server",
                iconBg: const Color(0xFF3B0A1F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddConnection()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





