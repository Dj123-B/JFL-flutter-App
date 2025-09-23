import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// TODO: Replace with your actual constants file or define baseUrl here.
const String baseUrl = "https://your-backend-url.com";

// TODO: Inject your real Flutterwave public key (TEST or LIVE as appropriate).
const String flutterwavePublicKey = "FLWPUBK_TEST-xxxxxxxxxxxxxxxxxxxxx";

// TODO: Provide your actual logged-in user id from your auth state.
String get loggedInUserId => "USER_ID"; // Replace with provider/bloc state

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phoneOrEmail = '';
  String _paymentMethod = 'phone'; // 'phone' or 'card'

  void _showPaymentDialog({
    required String planId,
    required String planName,
    required String amount,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("$planName Plan"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
                onChanged: (value) => _name = value,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone or Email'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Enter a valid contact'
                    : null,
                onChanged: (value) => _phoneOrEmail = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'phone', child: Text('Mobile Money')),
                  DropdownMenuItem(value: 'card', child: Text('Card Payment')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Pay Now'),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                if (_paymentMethod == 'card') {
                  await _makeCardPayment(
                    planId: planId,
                    planName: planName,
                    amount: amount,
                  );
                } else {
                  await _makePhonePayment(
                    planId: planId,
                    planName: planName,
                    amount: amount,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _makePhonePayment({
    required String planId,
    required String planName,
    required String amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/subscriptions/upgrade"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": loggedInUserId,
          "planId": planId,
          "paymentMethod": "phone",
          "name": _name,
          "contact": _phoneOrEmail,
          "amount": amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = UpgradeResponse.fromJson(jsonDecode(response.body));
        final url = Uri.parse(data.paymentUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _toast("Could not launch payment page");
        }
      } else {
        _toast("Payment init failed: ${response.body}");
      }
    } catch (e) {
      _toast("Error: ${e.toString()}");
    }
  }

   Future<void> _makeCardPayment({
  required String planId,
  required String planName,
  required String amount,
}) async {
  final txRef =
      "JFL-${planId.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}";

  final flutterwave = Flutterwave(
    publicKey: flutterwavePublicKey,
    currency: "TZS",
    redirectUrl: "$baseUrl/payment/redirect",
    txRef: txRef,
    amount: amount,
    customer: Customer(
      name: _name.isEmpty ? "Customer" : _name,
      phoneNumber: _isEmail(_phoneOrEmail) ? "" : _phoneOrEmail,
      email: _isEmail(_phoneOrEmail) ? _phoneOrEmail : "noemail@example.com",
    ),
    paymentOptions: "card",
    customization: Customization(title: "$planName Subscription"),
    isTestMode: true, // change to false in production
  );

  try {
    final ChargeResponse response = await flutterwave.charge(context);

    if (response.success == true) {
      _toast("Payment successful!");
      await _notifyBackendOfCardSuccess(
        planId: planId,
        planName: planName,
        amount: amount,
        txRef: txRef,
        flwRef: response.transactionId ?? response.txRef ?? "",
      );
    } else {
      _toast("Payment failed: ${response.status}");
    }
  } catch (e) {
    _toast("Error: ${e.toString()}");
  }
}


  Future<void> _notifyBackendOfCardSuccess({
    required String planId,
    required String planName,
    required String amount,
    required String txRef,
    required String flwRef,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/subscriptions/upgrade/card/confirm"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": loggedInUserId,
          "planId": planId,
          "txRef": txRef,
          "flwRef": flwRef,
          "amount": amount,
          "name": _name,
          "contact": _phoneOrEmail,
        }),
      );

      if (res.statusCode == 200) {
        _toast("Subscription activated");
      } else {
        _toast("Backend confirm failed: ${res.body}");
      }
    } catch (e) {
      _toast("Notify error: ${e.toString()}");
    }
  }

  bool _isEmail(String input) => input.contains("@");

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 25),
              _buildSubscriptionCard(
                planId: 'silver',
                title: 'Silver',
                amount: '50000',
                description: 'Basic access to loans and support',
                gradient: const LinearGradient(
                  colors: [Color(0xFFC0C0C0), Colors.grey],
                ),
                icon: Icons.star_border,
                message:
                    'This is a basic payment which will lead you to get a loan after 3 months. You need to pay every month.',
              ),
              const SizedBox(height: 20),
              _buildSubscriptionCard(
                planId: 'gold',
                title: 'Gold',
                amount: '100000',
                description: 'Priority support + higher credit limit',
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orangeAccent],
                ),
                icon: Icons.star_half,
                message:
                    'This plan will lead you to get loans after two months and other premium services.',
              ),
              const SizedBox(height: 20),
              _buildSubscriptionCard(
                planId: 'tanzanite',
                title: 'Tanzanite',
                amount: '150000',
                description: 'Exclusive offers + faster approvals',
                gradient: const LinearGradient(
                  colors: [Colors.blueGrey, Colors.indigo],
                ),
                icon: Icons.star,
                message:
                    'Faster approvals and exclusive offers. Loans accessible after one month.',
              ),
              const SizedBox(height: 20),
              _buildSubscriptionCard(
                planId: 'diamond',
                title: 'Diamond',
                amount: '300000',
                description: 'VIP benefits + maximum credit',
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                ),
                icon: Icons.diamond,
                message:
                    'VIP access and maximum credit. Loans accessible within 2 weeks.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required String planId,
    required String title,
    required String amount,
    required String description,
    required LinearGradient gradient,
    required IconData icon,
    required String message,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
           backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$amount TZS",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(description, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showPaymentDialog(
            planId: planId,
            planName: title,
            amount: amount,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Subscribe'),
        ),
      ),
    );
  }
}

class UpgradeResponse {
  final String paymentUrl;

  UpgradeResponse({required this.paymentUrl});

  factory UpgradeResponse.fromJson(Map<String, dynamic> json) {
    return UpgradeResponse(paymentUrl: json['paymentUrl'] as String);
  }
}
