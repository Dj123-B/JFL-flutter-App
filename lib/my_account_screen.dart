import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class AuthService {
  static String? _token;
  static Map<String, dynamic>? _userData;

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUserData(Map<String, dynamic> user) async {
    _userData = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    if (_userData != null) return _userData;
    
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      _userData = jsonDecode(userDataString);
    }
    return _userData;
  }

  static Future<void> logout() async {
    _token = null;
    _userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');
  }
}

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  // User data
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';
  File? image;
  String language = 'English';
  bool acceptedTerms = false;
  bool isLoading = true;
  
  // API data
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _subscription;
  
  // Constants
  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color(0xFF00695C);
  final Color primaryLightColor = const Color(0xFF4EBAAA);
  final Color primaryDarkColor = const Color(0xFF005B4F);
  final Color dangerColor = const Color(0xFFE53935);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Try to load from cache first
    final cachedUser = await AuthService.getUserData();
    if (cachedUser != null) {
      setState(() {
        name = cachedUser['name'] ?? 'User';
        email = cachedUser['email'] ?? 'user@example.com';
        phone = cachedUser['phone'] ?? '+255712345678';
        language = (cachedUser['language'] == 'sw') ? 'Swahili' : 'English';
        _subscription = cachedUser['subscription'];
      });
    }
    
    // Then fetch from server
    await _fetchProfile();
    
    setState(() => isLoading = false);
  }

  // Fetches the user's profile from the server
  Future<void> _fetchProfile() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/user-profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _user = data['data'];
          name = _user?['name'] ?? 'N/A';
          email = _user?['email'] ?? 'N/A';
          phone = _user?['phone'] ?? 'N/A';
          language = (_user?['language'] == 'sw') ? 'Swahili' : 'English';
          _subscription = _user?['subscription'];
        });
        await AuthService.saveUserData(_user!);
      } else {
        _showErrorSnackbar('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Network error: ${e.toString()}');
    }
  }

  // Saves the profile changes to the server
  Future<void> _saveProfileToServer(String newName, String newPhone, String newEmail) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/auth/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': newName, 'phone': newPhone, 'email': newEmail}),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Profile updated successfully!');
        await _fetchProfile(); // Refresh data
      } else {
        _showErrorSnackbar('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Network error: ${e.toString()}');
    }
  }

  // Helper method to show error snackbars
  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dangerColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper method to show success snackbars
  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => image = File(pickedFile.path));
      // Here you would typically upload the image to your backend
    }
  }

  void showEditProfileDialog() {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryDarkColor,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: image != null ? FileImage(image!) : null,
                  child: image == null
                      ? Icon(Icons.camera_alt, size: 30, color: primaryColor)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.email, color: primaryColor),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.phone, color: primaryColor),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveProfileToServer(
                        nameController.text, 
                        phoneController.text, 
                        emailController.text
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void toggleLanguage() async {
    final token = await AuthService.getToken();
    if (token == null) return;
    
    final newLang = (language == 'English') ? 'sw' : 'en';
    
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/language'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'language': newLang}),
      );

      if (response.statusCode == 200) {
        setState(() => language = (newLang == 'sw') ? 'Swahili' : 'English');
        _showSuccessSnackbar('Language switched to $language');
      } else {
        _showErrorSnackbar('Failed to switch language: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Network error: ${e.toString()}');
    }
  }

  void showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change PIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryDarkColor,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: oldPinController,
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                decoration: InputDecoration(
                  labelText: 'New PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.lock, color: primaryColor),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.lock_reset, color: primaryColor),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final oldPin = oldPinController.text.trim();
                      final newPin = newPinController.text.trim();
                      final confirmPin = confirmPinController.text.trim();

                      if (oldPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                        _showErrorSnackbar('Please fill all fields');
                        return;
                      }

                      if (newPin != confirmPin) {
                        _showErrorSnackbar('New PINs do not match');
                        return;
                      }

                      final token = await AuthService.getToken();
                      if (token == null) return;

                      try {
                        final response = await http.patch(
                          Uri.parse('$baseUrl/api/users/password'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token'
                          },
                          body: jsonEncode({
                            'currentPassword': oldPin,
                            'newPassword': newPin
                          }),
                        );

                        if (response.statusCode == 200) {
                          _showSuccessSnackbar('PIN updated successfully!');
                          if (mounted) Navigator.of(context).pop();
                        } else {
                          _showErrorSnackbar('Failed to change PIN: ${response.statusCode}');
                        }
                      } catch (e) {
                        _showErrorSnackbar('Network error: ${e.toString()}');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _fetchTerms() async {
    final token = await AuthService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/terms'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['terms'] ?? 'Terms and conditions not available.';
      }
      return 'Could not load terms from server.';
    } catch (e) {
      return 'Network error: Could not load terms.';
    }
  }

  void showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryDarkColor,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: FutureBuilder<String>(
                  future: _fetchTerms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error loading terms.'));
                    } else {
                      return SingleChildScrollView(
                        child: Text(
                          snapshot.data ?? 'No terms available.',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    onChanged: (value) => setState(() => acceptedTerms = value ?? false),
                    activeColor: primaryColor,
                  ),
                  const Text('I agree to the Terms & Conditions'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (acceptedTerms) {
                    Navigator.of(context).pop();
                    _showSuccessSnackbar('Thank you for accepting our terms!');
                  } else {
                    _showErrorSnackbar('Please accept the terms to continue');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Continue', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void contactSupport() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryDarkColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'For any assistance, please contact our support team:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.email, color: primaryColor),
                title: const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('support@jfl.co.tz'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: Icon(Icons.phone, color: primaryColor),
                title: const Text('Phone', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('+255 123 456 789'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: Icon(Icons.access_time, color: primaryColor),
                title: const Text('Hours', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Mon-Fri: 8AM-6PM\nSat: 9AM-1PM'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: Text(buttonText),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) {
      return 'N/A';
    }
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: showEditProfileDialog,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  backgroundImage: image != null ? FileImage(image!) : null,
                                  child: image == null
                                      ? Icon(Icons.person, size: 40, color: primaryColor)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          if (_subscription != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Plan: ${_subscription!['planId'] ?? 'N/A'} • ${_subscription!['status'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: primaryDarkColor, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Valid until: ${_formatDate(_subscription!['endDate'])}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Settings Options
                  buildOptionCard(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: language,
                    buttonText: 'Switch',
                    onPressed: toggleLanguage,
                  ),
                  const SizedBox(height: 12),
                  buildOptionCard(
                    icon: Icons.lock,
                    title: 'Security',
                    subtitle: 'Change your PIN',
                    buttonText: 'Change',
                    onPressed: showChangePinDialog,
                  ),
                  const SizedBox(height: 12),
                  buildOptionCard(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    subtitle: 'View our terms of service',
                    buttonText: 'View',
                    onPressed: showTermsAndConditions,
                  ),
                  const SizedBox(height: 12),
                  buildOptionCard(
                    icon: Icons.support,
                    title: 'Support',
                    subtitle: 'Contact our team',
                    buttonText: 'Contact',
                    onPressed: contactSupport,
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Logout', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}