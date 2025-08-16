// services/teacher_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/teacher_model.dart';
import '../constants.dart';

class TeacherService {
  /// Fetches the NFC teacher data by ID.
  Future<TeacherResponse> fetchTeacherData(String id) async {
    print("111111111111111111111111111");
    print('$baseUrl/nfc/teacher-data/$id');
    // Make sure baseUrl doesn’t already end with a slash
    final url = Uri.parse('$baseUrl/nfc/teacher-data/$id');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
      },
    );
    print("lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
    print(response.statusCode);
    switch (response.statusCode) {

      case 200:
        final Map<String, dynamic> body = json.decode(response.body);

        print(TeacherResponse.fromJson(body));
        return TeacherResponse.fromJson(body);
      case 400:
        final Map<String, dynamic> body = json.decode(response.body);
        final msg = body['message'] as String? ?? 'Bad request';
        throw msg;
      case 404:
        throw Exception('Teacher data not found (404) for ID $id');
      default:
        throw Exception(
          'Failed to load teacher info: HTTP ${response.statusCode}',
        );
    }
  }
}
