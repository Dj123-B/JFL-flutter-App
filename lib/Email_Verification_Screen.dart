import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:jfl_app/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
   const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;

  Future<void> _verifyEmail() async {
    if (_codeController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    // Implement your verification API call here
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thibitisha Barua Pepe')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              _isVerified 
                ? 'Barua pepe yako imethibitishwa!'
                : 'Tuma nambari ya uthibitisho kutoka kwenye barua pepe yako',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            if (!_isVerified) ...[
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Nambari ya Uthibitisho',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyEmail,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Thibitisha'),
              ),
            ] else ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('Endelea kwenye Mfumo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}