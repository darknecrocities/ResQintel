import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreparednessPage extends StatefulWidget {
  const PreparednessPage({super.key});

  @override
  State<PreparednessPage> createState() => _PreparednessPageState();
}

class _PreparednessPageState extends State<PreparednessPage> {
  List<dynamic> disasterData = [];

  @override
  void initState() {
    super.initState();
    loadDisasterData();
  }

  Future<void> loadDisasterData() async {
    final String jsonString = await rootBundle.loadString(
      'lib/data/prepare.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      disasterData = jsonData;
    });
  }

  Color _getColor(String name) {
    switch (name) {
      case "blueAccent":
        return Colors.blueAccent;
      case "deepOrange":
        return Colors.deepOrange;
      case "red":
        return Colors.red;
      case "lightBlue":
        return Colors.lightBlue;
      case "brown":
        return Colors.brown;
      case "deepPurple":
        return Colors.deepPurple;
      case "cyan":
        return Colors.cyan;
      case "amber":
        return Colors.amber;
      case "orange":
        return Colors.orange;
      case "indigo":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case "wind_power":
        return Icons.wind_power;
      case "terrain":
        return Icons.terrain;
      case "local_fire_department":
        return Icons.local_fire_department;
      case "water_damage":
        return Icons.water_damage;
      case "landslide":
        return Icons.landslide;
      case "volcano":
        return Icons.volcano;
      case "tsunami":
        return Icons.waves; // Best match for tsunami
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Disaster Preparedness"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: disasterData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: disasterData.length,
              itemBuilder: (context, index) {
                final item = disasterData[index];
                return _buildDisasterCard(
                  context,
                  title: item['title'],
                  description: item['description'],
                  checklist: List<String>.from(item['checklist']),
                  extraInfo: List<String>.from(item['extraInfo']),
                  color: _getColor(item['color']),
                  icon: _getIcon(item['icon']),
                );
              },
            ),
    );
  }

  Widget _buildDisasterCard(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> checklist,
    required List<String> extraInfo,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: color, size: 30),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        children: [
          Text(
            description,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          const Text(
            "Preparation & Response Checklist:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...checklist.map(
            (item) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(item),
            ),
          ),
          const Divider(),
          const Text(
            "Additional Information:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...extraInfo.map(
            (info) => ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: Text(info),
            ),
          ),
        ],
      ),
    );
  }
}
