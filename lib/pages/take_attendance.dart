import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:attendo/config/api_config.dart';

class TakeAttendance extends StatefulWidget {
  const TakeAttendance({super.key});

  @override
  State<TakeAttendance> createState() => _TakeAttendanceState();
}

class _TakeAttendanceState extends State<TakeAttendance> {
  File? capturedImage;
  bool _loading = false;

  final ImagePicker picker = ImagePicker();

  // Open camera
  Future<void> openCamera() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        capturedImage = File(image.path);
      });
    }
  }

  // Retake photo
  void retakePhoto() {
    setState(() {
      capturedImage = null;
    });
    openCamera();
  }

  // Submit photo
  Future<void> submitPhoto() async {
    if (capturedImage == null || _loading) return;

    setState(() => _loading = true);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/attendance/take');

      var request = http.MultipartRequest('POST', uri);

      // Read bytes to avoid Android cache PathNotFoundException
      final imageBytes = await capturedImage!.readAsBytes();
      final fileName = capturedImage!.path.split(Platform.pathSeparator).last;

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: fileName.isNotEmpty ? fileName : 'photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      log('Sending attendance photo...');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () =>
            throw Exception('Request timed out. Please try again.'),
      );
      final response = await http.Response.fromStream(streamedResponse);

      log('Status Code: ${response.statusCode}');
      log('Response: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        log('Attendance result: ${response.body}');
      } else {
        String errorMsg = 'Attendance failed (${response.statusCode})';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) errorMsg = data['message'].toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      log('API Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Photo')),
      body: Center(
        child: capturedImage == null
            ? ElevatedButton(
                onPressed: openCamera,
                child: const Text('Take Photo'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Photo Preview
                  Image.file(
                    capturedImage!,
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 30),

                  // Buttons row
                  // Submit button
                  if (_loading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: submitPhoto,
                      child: const Text('Submit'),
                    ),
                ],
              ),
      ),
    );
  }
}
