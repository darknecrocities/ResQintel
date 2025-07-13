import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'announcement.dart';
import 'emergency.dart';
import 'learn.dart';
import 'map.dart';
import 'models/gemini_model.dart';
import 'prepared.dart';
import 'privacy.dart';
import 'profile.dart';
import 'settings.dart';
import 't&c.dart';
import 'weather.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with TickerProviderStateMixin {
  String firstName = "User";
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserData();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        firstName = doc.data()?['firstname'] ?? "User";
      });
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PreparednessPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearnPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                child: Center(
                  child: Text(
                    "ResQintel Menu",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _drawerItem(Icons.settings, "Settings", const SettingsPage()),
              _drawerItem(
                Icons.article,
                "Terms & Conditions",
                const TermsPage(),
              ),
              _drawerItem(
                Icons.privacy_tip,
                "Privacy Policy",
                const PrivacyPolicyPage(),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.red),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: _selectedIndex == 0 ? _buildHomeContent() : Container(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Prepare'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer first
        if (title == "Assistance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeminiAssistantPage()),
          );
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.redAccent,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ResQintel App",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Welcome back, $firstName 👋",
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                "Rescue Powered Emergency App",
                style: TextStyle(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // First row: Center Alert Area + Weather
        Row(
          children: [
            Expanded(
              child: _featureCard(
                Icons.warning,
                "Center Alert Area",
                Colors.amber,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _featureCard(Icons.cloud, "Weather", Colors.lightBlue),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Second row: Assistance + Emergency Contacts
        Row(
          children: [
            Expanded(
              child: _featureCard(
                Icons.support_agent,
                "Assistance",
                Colors.blue,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _featureCard(
                Icons.phone_in_talk,
                "Emergency Contacts",
                Colors.redAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Third row: Disaster Alerts (full width)
        _featureCard(
          Icons.notifications_active,
          "Disaster Alerts",
          Colors.orange,
        ),
      ],
    );
  }

  Widget _featureCard(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (label == "Weather") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeatherPage()),
          );
        } else if (label == "Assistance") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeminiAssistantPage()),
          );
        } else if (label == "Emergency Contacts") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EmergencyContactsPage(),
            ), // linked to emergency.dart page
          );
        } else if (label == "Disaster Alerts") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DisasterAlertsPage(),
            ), // linked to announcement.dart page
          );
        }
      },
      child: Container(
        height: 120,
        margin: label == "Disaster Alerts"
            ? const EdgeInsets.symmetric(vertical: 10)
            : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.6), width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
