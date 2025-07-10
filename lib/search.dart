import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search"), backgroundColor: Colors.red),
      body: const Center(
        child: Text("Search Page", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
