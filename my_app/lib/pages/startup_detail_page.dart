import 'package:flutter/material.dart';

class StartupDetailPage extends StatelessWidget {
  final Map<String, dynamic> startup;

  const StartupDetailPage({super.key, required this.startup});

  @override
  Widget build(BuildContext context) {
    // If you have startup image in future, use it.
    // For now showing a placeholder color box.
    const imageUrl = "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Startup Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        children: [
          // ------------------- IMAGE -------------------
          SizedBox(
            height: 200,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade300),
          ),

          const SizedBox(height: 16),

          // ------------------- SECTION: BASIC INFO -------------------
          _sectionTitle("Basic Information"),
          _tile("Startup ID", startup["startupld"]),
          _tile("Created At", startup["created_at"]),
          _tile("Sector", startup["sector"]),
          _tile("Stage", startup["stage"]),
          _tile("USP", startup["usp"]),

          const SizedBox(height: 20),

          // ------------------- SECTION: PROBLEM - SOLUTION -------------------
          _sectionTitle("Problem & Solution"),
          _tile("Problem", startup["problem"]),
          _tile("Solution", startup["solution"]),

          const SizedBox(height: 20),

          // ------------------- SECTION: COMPANY DETAILS -------------------
          _sectionTitle("Company Details"),
          _tile("Legal Name", startup["legalName"]),
          _tile("Address", startup["address"]),
          _tile("Website", startup["websiteLink"]),

          const SizedBox(height: 20),

          // ------------------- SECTION: FOUNDER DETAILS -------------------
          _sectionTitle("Founder Details"),
          _tile("Founder Name", startup["founderName"]),
          _tile("Founder Email", startup["founderEmail"]),
          _tile("Founder Phone", startup["founderPhone"]),
          _tile("Founder LinkedIn", startup["founderLinkedin"]),
          _tile("Founder Role", startup["founderRole"]),

          const SizedBox(height: 20),

          // ------------------- SECTION: INTERNAL -------------------
          _sectionTitle("Internal Info"),
          _tile("Startup UUID", startup["startupUuid"]),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ----------- SECTION TITLE -----------
  Widget _sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade300,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ----------- KEY → VALUE ROW -----------
  Widget _tile(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key
          SizedBox(
            width: 140,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Value
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
