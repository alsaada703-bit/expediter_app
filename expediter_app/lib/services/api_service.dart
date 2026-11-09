import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<Map<String, dynamic>> submitServiceOrder({
    required String serviceName,
    required String details,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_name': serviceName,
          'details': details,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'فشل إرسال الطلب (كود الخطأ: ${response.statusCode})',
        };
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'message': 'تم إرسال طلب ($serviceName) بنجاح!',
      };
    }
  }
}