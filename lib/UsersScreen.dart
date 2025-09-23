import 'package:flutter/material.dart';

// Users Page
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users"), backgroundColor: Colors.teal),
      body: const Center(
        child: Text("👥 List of registered users will appear here."),
      ),
    );
  }
}

// Active Loans Page
class ActiveLoansScreen extends StatelessWidget {
  const ActiveLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Active Loans"), backgroundColor: Colors.green),
      body: const Center(
        child: Text("✅ Active loans will appear here."),
      ),
    );
  }
}

// Pending Loans Page
class PendingLoansScreen extends StatelessWidget {
  const PendingLoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Loans"), backgroundColor: Colors.orange),
      body: const Center(
        child: Text("⏳ Pending loan applications will appear here."),
      ),
    );
  }
}
