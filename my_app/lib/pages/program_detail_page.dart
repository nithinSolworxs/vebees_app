import 'package:flutter/material.dart';

class ProgramDetailPage extends StatelessWidget {
  final Map<String, dynamic> program;

  const ProgramDetailPage({super.key, required this.program});

  @override
  Widget build(BuildContext context) {
    final imageUrl = program['programImage'] ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Program Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: ListView(
        children: [
          // ---------------- IMAGE ----------------
          SizedBox(
            height: 220,
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200),
          ),

          const SizedBox(height: 16),

          // ---------------- SECTION 1 ----------------
          _sectionTitle("Basic Details"),
          _tile("Program ID", program["programId"]),
          _tile("Program Name", program["programName"]),
          _tile("Program Type", program["programType"]),
          _tile("Status", program["programStatus"]),
          _tile("Mode", program["programMode"]),
          _tile("Eligibility", program["programEligibility"]),
          _tile("Description", program["programDescrip"]),

          const SizedBox(height: 20),

          // ---------------- SECTION 2 ----------------
          _sectionTitle("Schedule"),
          _tile("Start Date", program["programStartDate"]),
          _tile("End Date", program["programEndDate"]),
          _tile("Number of Days", program["programNumDays"]),

          const SizedBox(height: 20),

          // ---------------- SECTION 3 ----------------
          _sectionTitle("Pricing & Offers"),
          _tile("Price", program["programPrice"]),
          _tile("Discount", program["programDiscount"]),

          const SizedBox(height: 20),

          // ---------------- SECTION 4 ----------------
          _sectionTitle("Ownership & Partners"),
          _tile("Owner", program["programOwner"]),
          _tile("Partner", program["programPartner"]),

          const SizedBox(height: 20),

          // ---------------- SECTION 5 ----------------
          _sectionTitle("Additional Info"),
          _tile("Meet Link", program["programMeetLink"]),
          _tile("Created At", program["created_at"]),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // -------- Section Title Widget --------
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

  // -------- Key → Value Row --------
  Widget _tile(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();

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
            width: 130,
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
