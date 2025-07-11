import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  List<dynamic> hazardData = [];

  @override
  void initState() {
    super.initState();
    loadHazardData();
  }

  Future<void> loadHazardData() async {
    final String response = await rootBundle.loadString(
      'lib/assets/disaster_data.json',
    );
    final data = json.decode(response);
    setState(() {
      hazardData = data;
    });
  }

  IconData getIconFromString(String iconName) {
    switch (iconName) {
      case 'cloud':
        return Icons.cloud;
      case 'public':
        return Icons.public;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'terrain':
        return Icons.terrain;
      case 'water':
        return Icons.water;
      case 'landscape':
        return Icons.landscape;
      case 'waves':
        return Icons.waves;
      case 'tsunami':
        return Icons.waves_outlined;
      case 'science':
        return Icons.science;
      case 'construction':
        return Icons.construction;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('🌍 Learn to Stay Safe'),
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Georgia',
        ),
      ),
      body: hazardData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hazardData.length,
              itemBuilder: (context, index) {
                final hazard = hazardData[index];
                return Column(
                  children: [
                    HazardCard(
                      icon: getIconFromString(hazard['icon']),
                      title: hazard['title'],
                      description: hazard['description'],
                      preparation: hazard['preparation'],
                      during: hazard['during'],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }
}

class HazardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String preparation;
  final String during;

  const HazardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.preparation,
    required this.during,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      elevation: 6,
      shadowColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle("📝 Description"),
                sectionText(description),
                const SizedBox(height: 10),
                sectionTitle("🛡️ How to Prepare"),
                sectionText(preparation),
                const SizedBox(height: 10),
                sectionTitle("🚨 What to Do During"),
                sectionText(during),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.redAccent,
        fontFamily: 'Ubuntu',
      ),
    );
  }

  Widget sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        fontFamily: 'OpenSans',
        color: Colors.black87,
      ),
    );
  }
}
