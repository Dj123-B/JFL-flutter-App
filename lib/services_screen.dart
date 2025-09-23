import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jfl_app/auth_service.dart';
import 'package:jfl_app/constants.dart';


// --- Data Models ---
class _Service {
  final String label;
  final IconData icon;
  final int requiredMonths;

  const _Service({
    required this.label,
    required this.icon,
    this.requiredMonths = 0,
  });
}

class _PaymentPartner {
  final String assetPath;
  final String label;

  const _PaymentPartner({
    required this.assetPath,
    required this.label,
  });
}

// --- Main Screen Widget ---
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  // --- State & Data ---
  final int _membershipDuration = 12; // In months

  final List<_Service> _services = const [
    _Service(label: 'Health Insurance', icon: Icons.local_hospital_outlined, requiredMonths: 6),
    _Service(label: 'Advice Request', icon: Icons.lightbulb_outline),
    _Service(label: 'Branding Support', icon: Icons.brush_outlined),
  ];

  final List<_PaymentPartner> _partners = const [
    _PaymentPartner(assetPath: 'assets/images/mpesa.jpeg', label: 'M-Pesa'),
    _PaymentPartner(assetPath: 'assets/images/airtel.jpeg', label: 'Airtel Money'),
    _PaymentPartner(assetPath: 'assets/images/Yas_Tanzania.svg.png', label: 'Mixx by Yas'),
    _PaymentPartner(assetPath: 'assets/images/halopesa.png', label: 'Halopesa'),
    _PaymentPartner(assetPath: 'assets/images/CRDB.webp', label: 'CRDB'),
    _PaymentPartner(assetPath: 'assets/images/NMB.jpg', label: 'NMB'),
    _PaymentPartner(assetPath: 'assets/images/NBC.webp', label: 'NBC'),
    _PaymentPartner(assetPath: 'assets/images/stanbic_bank.jpg', label: 'Stanbic'),
  ];

  // --- UI Styles ---
  final TextStyle _headlineStyle = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1A2533),
  );

  final TextStyle _subtextStyle = const TextStyle(
    fontSize: 15,
    color: Color(0xFF6C757D),
  );

  // --- Helper: SnackBar ---
  void _showSnackBar(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: success ? Colors.teal : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- Backend Request ---
  Future<void> _sendToBackend(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/advice"), // change this
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Request sent successfully!");
      } else {
        _showSnackBar("Failed: ${response.body}", success: false);
      }
    } catch (e) {
      _showSnackBar("Error: $e", success: false);
    }
  }

  // --- Popups ---
  void _showInsuranceMessage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Health Insurance"),
        content: const Text(
          "We are working hard to find the best insurance options for you.\n\n"
          "Stay tuned, and thank you for your patience!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  void _showAdviceForm() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    String adviceType = 'Business';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Advice Request"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Phone or Email")),
            DropdownButtonFormField<String>(
              value: adviceType,
              items: ['Business', 'Agriculture', 'Finance', 'Other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => adviceType = val ?? 'Business',
              decoration: const InputDecoration(labelText: "Type of Advice"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(context);
              await _sendToBackend("$baseUrl/api/advice", {
                "name": nameController.text,
                "contact": contactController.text,
                "adviceType": adviceType,
              });
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _showBrandingForm() {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final businessController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Branding Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Phone or Email")),
            TextField(controller: businessController, decoration: const InputDecoration(labelText: "Business Type")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(context);
              await _sendToBackend("$baseUrl/api/branding", {
                "name": nameController.text,
                "contact": contactController.text,
                "businessType": businessController.text,
              });
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Services', style: TextStyle(color: Color(0xFF1A2533))),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Available Services'),
              const SizedBox(height: 16),
              _buildServicesGrid(),
              const SizedBox(height: 32),
              _buildSectionHeader('Payment Partners'),
              const SizedBox(height: 8),
              Text("Get and pay your loan through our trusted partners.", style: _subtextStyle),
              const SizedBox(height: 16),
              _buildPaymentGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: _headlineStyle);

  Widget _buildServicesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final service = _services[index];
        final isEnabled = _membershipDuration >= service.requiredMonths;
        final disabledText = isEnabled ? null : 'Requires ${service.requiredMonths} months';

        return _ServiceCard(
          service: service,
          isEnabled: isEnabled,
          disabledText: disabledText,
          onTap: () {
            if (service.label == 'Health Insurance') {
              _showInsuranceMessage();
            } else if (service.label == 'Advice Request') {
              _showAdviceForm();
            } else if (service.label == 'Branding Support') {
              _showBrandingForm();
            }
          },
        );
      },
    );
  }

  Widget _buildPaymentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100.0,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _partners.length,
      itemBuilder: (context, index) => _PartnerLogo(partner: _partners[index]),
    );
  }
}

// --- Reusable Widgets ---
class _ServiceCard extends StatelessWidget {
  final _Service service;
  final bool isEnabled;
  final String? disabledText;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.service,
    required this.isEnabled,
    this.disabledText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabledText ?? '',
      child: Card(
        elevation: isEnabled ? 2 : 0,
        color: isEnabled ? Colors.white : const Color(0xFFE9ECEF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service.icon,
                  size: 32,
                  color: isEnabled ? Colors.teal : Colors.grey.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  service.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? const Color(0xFF1A2533) : Colors.grey.shade600,
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

class _PartnerLogo extends StatelessWidget {
  final _PaymentPartner partner;

  const _PartnerLogo({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 64,
          width: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Image.asset(
            partner.assetPath,
            fit: BoxFit.scaleDown,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.business_center, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          partner.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF495057)),
        ),
      ],
    );
  }
}
