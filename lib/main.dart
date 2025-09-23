import 'package:flutter/material.dart';
import 'package:jfl_app/UsersScreen.dart';
import 'package:provider/provider.dart';
import 'package:jfl_app/intro_screen.dart';
import 'package:jfl_app/login_screen.dart';
import 'package:jfl_app/registration_screen.dart';
import 'package:jfl_app/home_screen.dart' as home;
import 'package:jfl_app/my_account_screen.dart';
import 'package:jfl_app/subscription_screen.dart' as subscription;
import 'package:jfl_app/services_screen.dart';
import 'package:jfl_app/ForgotPasswordScreen.dart';



void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const JFLApp(),
    ),
  );
}

class UserProvider extends ChangeNotifier {
  String _userName = '';

  String get userName => _userName;

  set userName(String value) {
    _userName = value;
    notifyListeners();
    
  }

  // Your existing fields and methods
}

class JFLApp extends StatelessWidget {
  const JFLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JFL App',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 201, 208, 20),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.black, fontSize: 24),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      initialRoute: '/intro',
      routes: {
        '/intro': (context) => const IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const MainScreen(),
        '/users': (context) => const UsersScreen(),
         '/active-loans': (context) => const ActiveLoansScreen(),
         '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _buildPages(BuildContext context) {
    return [
      home.HomeScreen(userName: Provider.of<UserProvider>(context, listen: false).userName),
      subscription.SubscriptionScreen(),
      ServicesScreen(),
      MyAccountScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(context);
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color.fromARGB(255, 223, 223, 217),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
        iconSize: 28,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions_outlined),
            activeIcon: Icon(Icons.subscriptions),
            label: "Subscriptions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            activeIcon: Icon(Icons.build),
            label: "Services",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: "Account",
          ),
        ],
      ),
    );
  }
}



