import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jfl_app/loan_application_form.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:jfl_app/constants.dart';
import 'package:jfl_app/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loan_repayment_page.dart';


class HomeScreen extends StatefulWidget {
   const HomeScreen({super.key, required String userName});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _notificationCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  String _firstName = '';
  String _publicKey = '';
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _loanData = {
    'totalAmount': 0,
    'activeLoan': 0,
    'pendingLoan': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {  
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchUserData();
    await _fetchUserName();
    await _fetchNotifications();
    await _fetchLoanData();
    await _fetchPublicKey();
    setState(() => _isLoading = false);
  }

 Future<void> _fetchUserData() async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/user-profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() => _userData = data);

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(data));

      // Also save name separately for quick access
      if (data['name'] != null) {
        await prefs.setString('name', data['name']);
      }
    }
  } catch (e) {
    print('Error fetching user data: $e');

    // Fallback to stored data if API fails
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('userData');
    if (storedData != null) {
      final decoded = jsonDecode(storedData);
      setState(() => _userData = decoded);

      // Also restore name if available
      if (decoded['name'] != null) {
        await prefs.setString('name', decoded['name']);
      }
    }
  }
}

Future<void> _fetchUserName() async {
  final name = await AuthService.getUserName(); // gets plain string
  setState(() {
    _firstName = (name != null && name.isNotEmpty) 
        ? name.split(' ').first  // only first word
        : "User";                // fallback
  });
}


  Future<void> _fetchNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications']);
          _notificationCount = _notifications.where((n) => !n['read']).length;
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      // Fallback to empty notifications
      setState(() {
        _notifications = [];
        _notificationCount = 0;
      });
    }
  }

  Future<void> _fetchLoanData() async {
  try {
    final token = await AuthService.getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('$baseUrl/api/loan-status/user'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _loanData = {
            'totalAmount': data['data']['totalAmount'] ?? 0,
            'activeLoan': data['data']['activeLoan'] ?? 0,
            'pendingLoan': data['data']['pendingLoan'] ?? 0,
          };
        });
      }
    } else if (response.statusCode == 401) {
      // Token expired, redirect to login
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load loan data')),
      );
    }
  } on http.ClientException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Network error. Please check your connection')),
    );
  } on TimeoutException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request timeout. Please try again')),
    );
  } catch (e) {
    print('Error fetching loan data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An unexpected error occurred')),
    );
  }
}

  Future<void> _fetchPublicKey() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/flutterwave-public-key'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() => _publicKey = jsonDecode(response.body)['publicKey']);
      }
    } catch (e) {
      print('Error fetching public key: $e');
    }
  }

  Future<void> _processPayment(String plan, String amount, String email, String phone) async {
    if (_publicKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment system not ready. Please try again later.')),
      );
      return;
    }
    
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/process-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Username': _userData['fullName'] ?? _userData['name'] ?? 'User',
          'amount': amount,
          'email': email,
          'phone': phone,
          'plan': plan
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['paymentLink'] != null) {
          await launchUrl(Uri.parse(data['paymentLink']));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiation failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing payment: ${e.toString()}')),
      );
    }
  }

  void _markNotificationAsRead(String notificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      await http.patch(
        Uri.parse('$baseUrl/api/auth/notifications/$notificationId/mark-read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      // Refresh notifications
      await _fetchNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildLoanStatus(),
                      const SizedBox(height: 15),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                      _buildLoanCalculator(),
                      const SizedBox(height: 20),
                      _buildSubscriptionPlans(),
                      const SizedBox(height: 20), 
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
  
    final accountType = _userData['accountType'] ?? 'Standard';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Hello, ${_firstName.isNotEmpty ? _firstName : 'User'}',
                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
            Text('$accountType Account', 
                 style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, size: 30), 
              onPressed: _showNotifications
            ),
            if (_notificationCount > 0)
              Positioned(
                right: 8, 
                top: 8, 
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$_notificationCount', 
                             style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoanStatus() {
    // Format currency with commas
    String formatCurrency(int amount) {
      if (amount == 0) return '0 TZS';
      return '${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} TZS';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 161, 148, 199),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Loan Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusCard(
                title: "Total Amount",
                value: formatCurrency(_loanData['totalAmount'] ?? 0),
                icon: Icons.account_balance_wallet,
              ),
              _statusCard(
                title: "Active Loan",
                value: formatCurrency(_loanData['activeLoan'] ?? 0),
                icon: Icons.check_circle,
              ),
              _statusCard(
                title: "Pending Loan",
                value: formatCurrency(_loanData['pendingLoan'] ?? 0),
                icon: Icons.hourglass_empty,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.teal),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _buildActionButton(icon: Icons.credit_score, label: 'Apply Loan', onTap: _showLoanApplication),
            _buildActionButton(icon: Icons.payment, label: 'Repay Loan', onTap: () => _showRepaymentOptions(context)),
            _buildActionButton(icon: Icons.history, label: 'Loan History', onTap: _showLoanHistory),
            _buildActionButton(icon: Icons.support_agent, label: 'Contact Support', onTap: _contactSupport),
          ],
        ),
      ],
    );
  }


  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.teal), 
              const SizedBox(height: 8), 
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoanCalculator() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Loan Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Loan Amount (TZS)', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (months)', 
                border: OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 10),
            const Text('Interest Rate: 5% fixed', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _calculateLoan(
                amountController.text, 
                durationController.text
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, 
                minimumSize: const Size(double.infinity, 50), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              child: const Text('Calculate Repayment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subscription Plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Upgrade your plan for better loan terms', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Gold Plan'),
            subtitle: const Text('100,000 TZS/month - Better loan terms'),
            trailing: ElevatedButton(
              onPressed: () => _showSubscriptionDialog(),
              child: const Text('Upgrade'),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => NotificationSheet(
        notifications: _notifications,
        onNotificationTap: (notificationId) {
          _markNotificationAsRead(notificationId);
          Navigator.pop(context);
        },
      ),
    );
  }

 void _showLoanApplication() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
      builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: LoanApplicationForm(
          isSubmitting: false,
          userName: _userData['fullName'] ?? '',
          onSubmit: (formData) async {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loan application submitted successfully'),
              ),
            );
            await _fetchLoanData();
          },
        ),
      );
    },
  );
}



 void _showRepaymentOptions(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => LoanRepaymentPage(
        userName: _userData['name'] ?? 'User',
        onPaymentSuccess: () => _fetchLoanData(), // refresh loans after payment
      ),
    ),
  );
}

  void _showLoanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanHistoryScreen(
          userName: _userData['name'] ?? '',
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final phone = _userData['phone'] ?? '255123456789';
    final whatsappUrl = "https://wa.me/$phone";
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _calculateLoan(String amountStr, String durationStr) {
    if (amountStr.isEmpty || durationStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both amount and duration')),
      );
      return;
    }

    final amount = int.tryParse(amountStr) ?? 0;
    final duration = int.tryParse(durationStr) ?? 0;
    
    if (amount <= 0 || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and duration')),
      );
      return;
    }

    final interestRate = 0.05; // 5% interest
    final totalInterest = amount * interestRate * (duration / 12);
    final totalRepayment = amount + totalInterest;
    final monthlyPayment = totalRepayment / duration;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Loan Calculation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Loan Amount: ${amount.toStringAsFixed(0)} TZS'), 
            Text('Duration: $duration months'), 
            Text('Interest Rate: 5%'), 
            const Divider(), 
            Text('Monthly Payment: ${monthlyPayment.toStringAsFixed(0)} TZS', 
                 style: const TextStyle(fontWeight: FontWeight.bold)), 
            Text('Total Repayment: ${totalRepayment.toStringAsFixed(0)} TZS')
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('OK')
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Gold Plan'),
        content: const Text('Proceed to pay 100,000 TZS for better loan terms.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final email = _userData['email'] ?? 'user@example.com';
              final phone = _userData['phone'] ?? '255123456789';
              _processPayment('Gold', '100000', email, phone);
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

class NotificationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onNotificationTap;
  
  const NotificationSheet({
    super.key, 
    required this.notifications,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Card(
                          color: notification['read'] ? Colors.white : Colors.teal[50],
                          child: ListTile(
                            title: Text(notification['title'] ?? 'Notification'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(notification['message'] ?? ''), 
                                Text(notification['time'] ?? '', 
                                     style: const TextStyle(color: Colors.grey, fontSize: 12))
                              ]
                            ),
                            trailing: notification['read'] 
                                ? null 
                                : const Icon(Icons.circle, color: Colors.teal, size: 10),
                            onTap: () => onNotificationTap(notification['id'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

 
class LoanHistoryScreen extends StatefulWidget {
  final String userName;
  const LoanHistoryScreen({super.key, required this.userName});

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _loanHistory;

  @override
  void initState() {
    super.initState();
    _loanHistory = _fetchLoanHistory();
  }

   
Future<List<Map<String, dynamic>>> _fetchLoanHistory() async {
  try {
    final token = await AuthService.getToken();
    final userId = await AuthService.getUserId(); // ✅ cleaner, always available

    if (token == null || userId == null) return [];

    final url = Uri.parse('$baseUrl/api/history/$userId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['history']); // ✅ must match backend response
    } else {
      throw Exception('Failed to load loan history: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error fetching loan history: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userName} Loan History')),
      body: FutureBuilder(
        future: _loanHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final loans = snapshot.data ?? [];
          return loans.isEmpty
              ? const Center(child: Text('No loan history found'))
              : ListView.builder(
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(loan['type'] ?? 'Loan'),
                        subtitle: Text(loan['date'] ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(loan['amount'] ?? '0 TZS', 
                                 style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(loan['status'] ?? 'Unknown', 
                                 style: TextStyle(color: (loan['status'] == 'Paid') 
                                     ? Colors.green 
                                     : Colors.orange)),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}