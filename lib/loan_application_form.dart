import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jfl_app/constants.dart';
import 'dart:ui' as ui;

class LoanApplicationForm extends StatefulWidget {
  final String? userName;
  final Function(Map<String, dynamic>)? onSubmit;

  const LoanApplicationForm({super.key, this.userName, this.onSubmit, required bool isSubmitting});

  @override
  State<LoanApplicationForm> createState() => _LoanApplicationFormState();
}

class _LoanApplicationFormState extends State<LoanApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  // Personal Info
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Employment Info
  final _employerController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _employmentDurationController = TextEditingController();
  final _otherIncomeController = TextEditingController();

  // Loan Request
  String? _loanType;
  final _requestedAmountController = TextEditingController();
  final _purposeController = TextEditingController();
  String? _repaymentPeriod;
  final _collateralController = TextEditingController();

  // Banking
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _bankPhoneController = TextEditingController();

  // Emergency Contacts
  final _contact1NameController = TextEditingController();
  final _contact1PhoneController = TextEditingController();
  final _contact1RelationshipController = TextEditingController();
  final _contact2NameController = TextEditingController();
  final _contact2PhoneController = TextEditingController();
  final _contact2RelationshipController = TextEditingController();

  // Declarations
  bool _confirmAccuracy = false;
  bool _authorizeVerification = false;
  bool _isSubmitting = false; // Track submission state

  @override
  void initState() {
    super.initState();
    if (widget.userName != null) {
      _fullNameController.text = widget.userName!;
    }
  }

  // Reusable Widgets
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      );

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isMultiLine ? 3 : 1,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Please select" : null,
      ),
    );
  }

  Widget _buildContactForm(
    String contactNumber,
    TextEditingController nameController,
    TextEditingController phoneController,
    TextEditingController relationshipController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Emergency Contact $contactNumber"),
        _buildTextField("Full Name", nameController),
        _buildTextField("Phone Number", phoneController, isNumber: true),
        _buildTextField("Relationship", relationshipController),
      ],
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SfSignaturePad(
        key: _signaturePadKey,
        strokeColor: Colors.black,
        minimumStrokeWidth: 2,
        maximumStrokeWidth: 4,
        backgroundColor: Colors.white,
      ),
    );
  }

  // Submit Application
  Future<void> _submitApplication() async {
    // Prevent multiple submissions
    if (_isSubmitting) return;
    
    if (!_formKey.currentState!.validate()) return;

    if (!_confirmAccuracy || !_authorizeVerification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept all declarations")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Capture signature
      final signatureImage = await _signaturePadKey.currentState?.toImage();
      if (signatureImage == null) {
        throw Exception("Please provide your signature before submitting.");
      }

      final byteData =
          await signatureImage.toByteData(format: ui.ImageByteFormat.png);
      final signatureBytes = byteData!.buffer.asUint8List();
      final signatureBase64 = base64Encode(signatureBytes);

      // Get token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit application")),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Prepare data
      final applicationData = {
        "personal_info": {
          "fullName": _fullNameController.text,
          "dob": _dobController.text,
          "idNumber": _idController.text,
          "phone": _phoneController.text,
          "email": _emailController.text,
          "address": _addressController.text,
        },
        "employment_income": {
          "employer": _employerController.text,
          "jobTitle": _jobTitleController.text,
          "monthlyIncome": _monthlyIncomeController.text,
          "employmentDuration": _employmentDurationController.text,
          "otherIncome": _otherIncomeController.text,
        },
        "loan_request": {
          "loanType": _loanType,
          "amount": _requestedAmountController.text,
          "purpose": _purposeController.text,
          "repaymentPeriod": _repaymentPeriod,
          "collateral": _collateralController.text,
        },
        "emergency_contacts": [
          {
            "name": _contact1NameController.text,
            "phone": _contact1PhoneController.text,
            "relationship": _contact1RelationshipController.text,
          },
          {
            "name": _contact2NameController.text,
            "phone": _contact2PhoneController.text,
            "relationship": _contact2RelationshipController.text,
          },
        ],
        "banking_details": {
          "bankName": _bankNameController.text,
          "accountNumber": _accountNumberController.text,
          "branchName": _branchNameController.text,
          "bankPhone": _bankPhoneController.text,
        },
        "declarations": {
          "accuracyConfirmed": _confirmAccuracy,
          "verificationAuthorized": _authorizeVerification,
        },
        "signature": signatureBase64,
        "status": "pending",
        "submittedAt": DateTime.now().toIso8601String(),
      };

      // API request
      final response = await http.post(
        Uri.parse('$baseUrl/api/loan-applications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(applicationData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully!")),
        );

        _formKey.currentState!.reset();
        _signaturePadKey.currentState?.clear();
        setState(() {
          _confirmAccuracy = false;
          _authorizeVerification = false;
          _loanType = null;
          _repaymentPeriod = null;
        });

        widget.onSubmit?.call(applicationData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Failed to submit application");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Application"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("👤 Personal Information"),
              _buildTextField("Full Name", _fullNameController),
              _buildTextField("Date of Birth (DD-MM-YYYY)", _dobController),
              _buildTextField("National ID / Passport Number", _idController),
              _buildTextField("Phone Number", _phoneController, isNumber: true),
              _buildTextField("Email Address", _emailController),
              _buildTextField("Residential Address", _addressController,
                  isMultiLine: true),

              _sectionTitle("💼 Employment & Income"),
              _buildTextField("Employer Name", _employerController),
              _buildTextField("Job Title", _jobTitleController),
              _buildTextField("Monthly Income (TZS)", _monthlyIncomeController,
                  isNumber: true),
              _buildTextField("Employment Duration (Years)",
                  _employmentDurationController),
              _buildTextField("Other Income Sources (optional)",
                  _otherIncomeController),

              _sectionTitle("💰 Loan Request"),
              _buildDropdown(
                "Loan Type",
                ["Personal", "School fee", "Business", "Agriculture", "Mortgage", "Other"],
                _loanType,
                (value) => setState(() => _loanType = value),
              ),
              _buildTextField("Requested Amount (TZS)",
                  _requestedAmountController, isNumber: true),
              _buildTextField("Purpose of Loan", _purposeController,
                  isMultiLine: true),
              _buildDropdown(
                "Repayment Period",
                ["3 months", "6 months", "9 months", "12 months"],
                _repaymentPeriod,
                (value) => setState(() => _repaymentPeriod = value),
              ),
              _buildTextField("Collateral Offered (if applicable)",
                  _collateralController,
                  isMultiLine: true),

              _buildContactForm("1", _contact1NameController,
                  _contact1PhoneController, _contact1RelationshipController),
              _buildContactForm("2", _contact2NameController,
                  _contact2PhoneController, _contact2RelationshipController),

              _sectionTitle("🏦 Banking Details"),
              _buildTextField("Bank Name", _bankNameController),
              _buildTextField("Account Number", _accountNumberController),
              _buildTextField("Branch Name", _branchNameController),
              _buildTextField("Bank Phone Number", _bankPhoneController,
                  isNumber: true),

              _sectionTitle("📝 Applicant Signature"),
              const Text("Please sign in the box below:",
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              _buildSignaturePad(),
              TextButton(
                onPressed: () => _signaturePadKey.currentState?.clear(),
                child: const Text("Clear Signature",
                    style: TextStyle(color: Colors.red)),
              ),

              _sectionTitle("✅ Declarations"),
              CheckboxListTile(
                title: const Text(
                    "I confirm that the information provided is accurate."),
                value: _confirmAccuracy,
                onChanged: (value) =>
                    setState(() => _confirmAccuracy = value ?? false),
              ),
              CheckboxListTile(
                title: const Text(
                    "I authorize the lender to verify my details and credit history."),
                value: _authorizeVerification,
                onChanged: (value) =>
                    setState(() => _authorizeVerification = value ?? false),
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "💵 Loan application fee: 10,000 TZS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isSubmitting ? null : _submitApplication,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit Application"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}