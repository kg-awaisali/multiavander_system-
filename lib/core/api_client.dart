import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiClient {
  // Public getter for baseUrl (needed for multipart uploads)
  static String get baseUrl => AppConstants.baseUrl;

  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await getHeaders();
    return await http.get(Uri.parse('${AppConstants.baseUrl}$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return await http.delete(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: headers,
    );
  }

  static Future<http.StreamedResponse> postMultipart(
    String endpoint, 
    Map<String, String> fields, 
    List<http.MultipartFile> files
  ) async {
    final headers = await getHeaders();
    // Headers for multipart MUST NOT contain Content-Type application/json or it might fail
    headers.remove('Content-Type');
    
    final request = http.MultipartRequest('POST', Uri.parse('${AppConstants.baseUrl}$endpoint'))
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.addAll(files);

    return await request.send();
  }
}
