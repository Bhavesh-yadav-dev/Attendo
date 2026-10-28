import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:attendo/config/api_config.dart';

/// Result returned from [StudentApi.addStudent].
/// Carries the success flag and the server's human-readable message.
class StudentApiResult {
  final bool success;
  final String message;

  const StudentApiResult({required this.success, required this.message});
}

class StudentApi {
  static Future<StudentApiResult> addStudent({
    required String name,
    required String rollNo,
    required File photo1,
    required File photo2,
    required File photo3,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/student/register');

      final request = http.MultipartRequest('POST', url);

      // Student details
      request.fields['name'] = name;
      request.fields['rollNo'] = rollNo;

      // Student photos — all three as the 'photos' array field
      final photos = [photo1, photo2, photo3];
      for (final photo in photos) {
        request.files.add(
          await http.MultipartFile.fromPath('photos', photo.path),
        );
      }

      // Send request — 90 s timeout to allow for slow face inference
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () =>
            throw Exception('Request timed out. Please try again.'),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      log('Status: ${streamedResponse.statusCode}');
      log('Response: $responseBody');

      // Parse the server's JSON message
      String serverMessage = 'Registration failed. Please try again.';
      try {
        final data = jsonDecode(responseBody);
        if (data['message'] != null) {
          serverMessage = data['message'].toString();
        }
      } catch (_) {
        // body was not JSON — keep the default message
      }

      final ok =
          streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201;

      return StudentApiResult(
        success: ok,
        message: ok ? 'Student registered successfully' : serverMessage,
      );
    } on SocketException {
      return const StudentApiResult(
        success: false,
        message: 'Unable to connect to server. Check your network.',
      );
    } catch (e) {
      log('API Error: $e');
      return StudentApiResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
