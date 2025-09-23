// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jfl_app/constants.dart';

class AuthService {
  /* =========================
     Helper: Get Headers with Token
  ========================= */
  static Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    if (name != null && name.isNotEmpty) {
      // Always 
      //only the first name
      return name.split(' ').first;
    }
    return null;
  }


 static Future<String?> getUserPhone() async {
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString('phone');
  return (phone != null && phone.isNotEmpty) ? phone : null;
}

  /* =========================
     REGISTER
  ========================= */
   static Future<Map<String, dynamic>> register({
  required String name,
  required String phone,
  required String email,
  required String password,
  required String confirmPassword,
}) async {
  if (password != confirmPassword) {
    return {'success': false, 'message': 'Passwords do not match'};
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        "name": name,
        "phone": phone,
        "email": email,
        "password": password,
      }),
    );

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }

    final data = jsonDecode(response.body);
    print('🔍 Register response: $data');

    final user = data['user'] ?? data['data']?['user'];
    final token = data['token'] ?? data['data']?['token'];

    if (response.statusCode == 201 && user != null && token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userData', jsonEncode(user));
      await prefs.setString('name', user['name'] ?? name);
      await prefs.setString('phone', user['phone'] ?? phone);

      return {
        'success': true,
        'message': data['message'] ?? 'Registration successful',
        'user': user,
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Registration failed',
      'statusCode': response.statusCode
    };
  } catch (e) {
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}

  /* =========================
     LOGIN
  ========================= */
  static Future<Map<String, dynamic>> login(String phone, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );

    if (response.body.isEmpty) {
      return {'success': false, 'message': 'Empty response from server'};
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['user'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('userData', jsonEncode(data['user']));
      await prefs.setString('name', data['user']['name'] ?? '');
      await prefs.setString('phone', data['user']['phone'] ?? '');

      return {'success': true, 'user': data['user']};
    } else {
      return {
        'success': false, 
        'message': data['message'] ?? 'Login failed',
        'statusCode': response.statusCode
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'An error occurred: $e'};
  }
}


  /* =========================
     LOGOUT
  ========================= */
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');
  }

  /* =========================
     Get stored token & user
  ========================= */
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('userData');
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /* =========================
     USER PROFILE
  ========================= */
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/user-profile'),
        headers: await _getHeaders(withAuth: true),
      );
      
      // Handle non-JSON responses
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to fetch profile',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

 
  /* =========================
     NOTIFICATIONS
  ========================= */
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/notifications'),
        headers: await _getHeaders(withAuth: true),
      );
      
      // Handle non-JSON responses
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'notifications': data['notifications']};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to fetch notifications',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /* =========================
     LOAN STATUS
  ========================= */
  static Future<Map<String, dynamic>> getLoanStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/loan-status'),
        headers: await _getHeaders(withAuth: true),
      );
      
      // Handle non-JSON responses
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'loan': data['loan']};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to fetch loan status',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /* =========================
     LOAN APPLICATION
  ========================= */
  static Future<Map<String, dynamic>> applyForLoan({
    required Map<String, dynamic> personalInfo,
    required Map<String, dynamic> employmentIncome,
    required Map<String, dynamic> loanRequest,
    required List<Map<String, dynamic>> emergencyContacts,
    required Map<String, dynamic> bankingDetails,
    required Map<String, dynamic> declarations,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/loan-applications'),
        headers: await _getHeaders(withAuth: true),
        body: jsonEncode({
          "personal_info": personalInfo,
          "employment_income": employmentIncome,
          "loan_request": loanRequest,
          "emergency_contacts": emergencyContacts,
          "banking_details": bankingDetails,
          "declarations": declarations,
          "signature": signature,
        }),
      );

      // Handle non-JSON responses
      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'loan': data['application'],
          'message': data['message'] ?? 'Loan application submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Loan application failed',
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /* =========================
     FLUTTERWAVE PUBLIC KEY
  ========================= */
  static Future<String?> getFlutterwavePublicKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/flutterwave-public-key'),
        headers: await _getHeaders(),
      );
      
      // Handle non-JSON responses
      if (response.body.isEmpty) {
        return null;
      }
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data['publicKey'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future getUserId() async {}
}