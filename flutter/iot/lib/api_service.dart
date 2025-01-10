import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://rena-iot.vercel.app/data';

  Future<List<dynamic>> fetchData() async {
    try {
      print('Fetching data from $baseUrl...');
      final response = await http.get(Uri.parse(baseUrl));
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception(
            'Failed to fetch data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      rethrow;
    }
  }

  Future<String> addData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body)['_id'];
      } else {
        throw Exception(
            'Failed to add data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
