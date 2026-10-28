import 'dart:convert';

import 'package:attendo/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});

  @override
  State<ViewAttendance> createState() => _ViewAttendanceState();
}

class _ViewAttendanceState extends State<ViewAttendance> {
  DateTime? selectedDate;

  bool loading = false;

  List<dynamic> attendance = [];

  String message = '';
  bool isSuccess = false;

  final String baseUrl = ApiConfig.baseUrl;

  // --------------------------------------------------
  // Select Date
  // --------------------------------------------------

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        message = '';
      });
    }
  }

  // --------------------------------------------------
  // Format Date
  // --------------------------------------------------

  String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // --------------------------------------------------
  // Fetch Attendance
  // --------------------------------------------------

  Future<void> fetchAttendance() async {
    if (selectedDate == null) {
      setState(() {
        message = 'Please select a date.';
        isSuccess = false;
      });
      return;
    }

    setState(() {
      loading = true;
      attendance = [];
      message = '';
    });

    try {
      final String date = formatDate(selectedDate!);

      final Uri url = Uri.parse('$baseUrl/api/attendance?date=$date');

      final response = await http.get(url);

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        setState(() {
          attendance = data['attendance'] ?? [];

          message = 'Showing attendance for $date';

          isSuccess = true;
        });
      } else {
        setState(() {
          message = data['message'] ?? 'Failed to fetch attendance.';

          isSuccess = false;
        });
      }
    } catch (error) {
      setState(() {
        message = 'Unable to connect to server.';
        isSuccess = false;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // --------------------------------------------------
  // Present Count
  // --------------------------------------------------

  int get presentCount {
    return attendance.where((student) => student['status'] == 'Present').length;
  }

  // --------------------------------------------------
  // Absent Count
  // --------------------------------------------------

  int get absentCount {
    return attendance.where((student) => student['status'] == 'Absent').length;
  }

  // --------------------------------------------------
  // Summary Box
  // --------------------------------------------------

  Widget summaryBox({
    required int count,
    required String title,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Attendance Table
  // --------------------------------------------------

  Widget attendanceTable() {
    if (attendance.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No attendance records for this date.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xfff3f4f6)),

        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Roll No')),
          DataColumn(label: Text('Status')),
        ],

        rows: List.generate(attendance.length, (index) {
          final student = attendance[index];

          final String status = student['status'] ?? '';

          final bool isPresent = status == 'Present';

          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),

              DataCell(Text(student['name'] ?? '')),

              DataCell(Text(student['roll_no']?.toString() ?? '')),

              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? const Color(0xffdcfce7)
                        : const Color(0xffffe2e2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPresent
                          ? const Color(0xff15803d)
                          : const Color(0xffb91c1c),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(title: const Text('View Attendance')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),

            child: Container(
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),

                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Title
                  const Text(
                    'View Attendance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff222222),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Select a date to see who was present',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),

                  const SizedBox(height: 20),

                  // Message
                  if (message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),

                      margin: const EdgeInsets.only(bottom: 20),

                      decoration: BoxDecoration(
                        color: isSuccess
                            ? const Color(0xffdcfce7)
                            : const Color(0xffffe2e2),

                        borderRadius: BorderRadius.circular(8),

                        border: Border.all(
                          color: isSuccess
                              ? const Color(0xffbbf7d0)
                              : const Color(0xfffca5a5),
                        ),
                      ),

                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSuccess
                              ? const Color(0xff15803d)
                              : const Color(0xffb91c1c),
                        ),
                      ),
                    ),

                  // Date + Button
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: selectDate,

                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),

                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xffdddddd),
                              ),

                              borderRadius: BorderRadius.circular(8),
                            ),

                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),

                                const SizedBox(width: 10),

                                Text(
                                  selectedDate == null
                                      ? 'Select Date'
                                      : formatDate(selectedDate!),
                                  style: TextStyle(
                                    color: selectedDate == null
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        onPressed: loading ? null : fetchAttendance,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4f46e5),

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Show Attendance',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Attendance
                  if (attendance.isNotEmpty || isSuccess == true)
                    Column(
                      children: [
                        // Summary
                        Row(
                          children: [
                            summaryBox(
                              count: presentCount,
                              title: 'Present',
                              backgroundColor: const Color(0xffdcfce7),
                              textColor: const Color(0xff15803d),
                            ),

                            const SizedBox(width: 12),

                            summaryBox(
                              count: absentCount,
                              title: 'Absent',
                              backgroundColor: const Color(0xffffe2e2),
                              textColor: const Color(0xffb91c1c),
                            ),

                            const SizedBox(width: 12),

                            summaryBox(
                              count: attendance.length,
                              title: 'Total',
                              backgroundColor: const Color(0xffe0e7ff),
                              textColor: const Color(0xff4338ca),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Table
                        attendanceTable(),
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
}
