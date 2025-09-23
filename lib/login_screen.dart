import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jfl_app/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';
  bool _isEmailLogin = false;

  // Function to validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Prepare the body based on the login type
      final Map<String, String> requestBody;
      if (_isEmailLogin) {
        requestBody = {
          'email': username,
          'password': password,
        };
      } else {
        requestBody = {
          'phone': username,
          'password': password,
        };
      }

      // Send the login request with the corrected body
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userData', jsonEncode(data['user']));

        // Store individual fields for easy access
        if (data['user'] != null) {
          await prefs.setString('name', data['user']['name'] ?? '');
          await prefs.setString('email', data['user']['email'] ?? '');
          await prefs.setString('phone', data['user']['phone'] ?? '');
          await prefs.setString('userId', data['user']['_id'] ?? '');
        }

        if (!mounted) return;

        // Navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Handle error response
        setState(() {
          _errorMessage = data['message'] ?? 'Imeshindikana kuingia';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on http.ClientException {
      setState(() {
        _errorMessage = 'Hitilafu ya mtandao. Tafadhali angalia muunganisho wako.';
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Muda umekwisha. Tafadhali jaribu tena.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Hitilafu isiyotarajiwa. Tafadhali jaribu tena baadaye.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingia', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color.fromARGB(255, 223, 223, 217),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Toggle between phone and email login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Ingia kwa:'),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Namba ya Simu'),
                      selected: !_isEmailLogin,
                      onSelected: (selected) {
                        setState(() {
                          _isEmailLogin = !selected;
                          _usernameController.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Barua Pepe'),
                      selected: _isEmailLogin,
                      onSelected: (selected) {
                        setState(() {
                          _isEmailLogin = selected;
                          _usernameController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error message display
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 📱 Phone/Email Input
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: _isEmailLogin ? 'Barua Pepe' : 'Namba ya Simu',
                    hintText: _isEmailLogin ? 'example@email.com' : '07XXXXXXXX',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(_isEmailLogin ? Icons.email : Icons.phone),
                  ),
                  keyboardType: _isEmailLogin ? TextInputType.emailAddress : TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _isEmailLogin
                          ? 'Tafadhali ingiza barua pepe'
                          : 'Tafadhali ingiza namba ya simu';
                    }

                    if (_isEmailLogin) {
                      if (!_isValidEmail(value)) {
                        return 'Ingiza barua pepe sahihi';
                      }
                    } else {
                      // Remove non-digits for validation
                      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                      // Tanzanian phone number validation
                      if (!RegExp(r'^(0|\+255)[67]\d{8}$').hasMatch(digitsOnly)) {
                        return 'Ingiza namba sahihi ya Tanzania (07XXXXXXX)';
                      }
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔒 Password Input
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Nenosiri',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tafadhali ingiza nenosiri';
                    }
                    if (value.length < 6) {
                      return 'Nenosiri lazima liwe na herufi angalau 6';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ingia', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot Password
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text('Umesahau nenosiri?'),
                ),
                const SizedBox(height: 16),

                // Register Navigation
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.teal),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: const Text(
                    'Huna akaunti? Jisajili',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
