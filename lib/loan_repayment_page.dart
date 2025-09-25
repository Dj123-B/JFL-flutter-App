import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jfl_app/auth_service.dart';
import 'package:jfl_app/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart'; // Assumes you have a service to get the auth token
import '../config.dart'; // Assumes you have a config file for baseUrl

class LoanRepaymentPage extends StatefulWidget {
  final VoidCallback onPaymentSuccess;

  const LoanRepaymentPage({
    super.key,
    required this.onPaymentSuccess, required userName,
  });

  @override
  State<LoanRepaymentPage> createState() => _LoanRepaymentPageState();
}

class _LoanRepaymentPageState extends State<LoanRepaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String _paymentType = "mobile";
  String? _selectedProvider;
  // ignore: unused_field
  String _phoneOrAccount = "";
  String _amount = "";
  bool _isProcessing = false;

  final List<String> mobileProviders = [
    "M-Pesa",
    "Airtel Money",
    "Mixx by Yas",
    "HaloPesa",
  ];

  /// Initiates the payment process by sending data to the backend.
  /// The backend handles the Flutterwave API integration and returns a payment link.
  Future<void> _processPayment() async {
    // Validate form fields before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save(); // Save the form field values

    setState(() => _isProcessing = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception("User is not authenticated. Please log in again.");
      }

      // 1. Send request to our backend, not Flutterwave directly.
      final response = await http.post(
        Uri.parse('$baseUrl/api/repay-loan'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "amount": _amount,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['paymentLink'] != null) {
        // 2. Launch the payment URL received from the backend.
        final Uri paymentUrl = Uri.parse(data['paymentLink']);
        if (!await launchUrl(paymentUrl, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $paymentUrl');
        }

        // Optional: Pop the page and show a success message on the previous screen.
        widget.onPaymentSuccess();
        if (mounted) Navigator.pop(context);

      } else {
        // Handle server-side errors
        throw Exception(data['message'] ?? "Failed to initiate payment.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Repayment"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting removed as requested
              const Text(
                "Choose your preferred payment method:",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Mobile Money"),
                      value: "mobile",
                      groupValue: _paymentType,
                      onChanged: (value) => setState(() => _paymentType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Bank Transfer"),
                      value: "bank",
                      groupValue: _paymentType,
                      onChanged: (value) => setState(() => _paymentType = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_paymentType == "mobile") ...[
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  items: mobileProviders.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  decoration: const InputDecoration(
                    labelText: "Select Mobile Provider",
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text("Choose provider"),
                  validator: (value) => value == null ? 'Please select a provider' : null,
                  onChanged: (value) => setState(() => _selectedProvider = value),
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                decoration: InputDecoration(
                  labelText: _paymentType == "mobile" ? "Phone Number" : "Bank Account Number",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
                onSaved: (val) => _phoneOrAccount = val!.trim(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Amount (TZS)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onSaved: (val) => _amount = val!.trim(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.payment),
                  label: Text(_isProcessing ? "Processing..." : "Pay Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}