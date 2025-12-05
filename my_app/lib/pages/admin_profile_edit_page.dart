import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userProfile; 
  // must contain: userId, name, typeOfUser, stream

  const AdminProfileEditPage({super.key, required this.userProfile});

  @override
  State<AdminProfileEditPage> createState() => _AdminProfileEditPageState();
}

class _AdminProfileEditPageState extends State<AdminProfileEditPage> {
  // ENUM options
  final List<String> userTypes = [
    "User",
    "Coordinator",
    "Manager",
    "Mentor",
    "Investor",
    "Partner",
    "Sponser",
    "New"
  ];

  final List<String> presetStreams = [
    "Startbee",
    "Millionminds",
    "TSC",
  ];

  String? selectedUserType;
  String? selectedStream;
  TextEditingController streamController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedUserType = widget.userProfile["typeOfUser"];
    selectedStream = widget.userProfile["stream"];

    // prefill custom stream if it's not one of the presets
    if (!presetStreams.contains(selectedStream)) {
      streamController.text = selectedStream ?? "";
    }
  }

  Future<void> saveChanges() async {
    try {
      final streamValue =
          streamController.text.isNotEmpty ? streamController.text : selectedStream;

      await supabase.from('profile').update({
        'typeOfUser': selectedUserType,
        'stream': streamValue,
      }).eq('userId', widget.userProfile["userId"]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Edit Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Display Name (Read Only)
            Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(widget.userProfile["name"] ?? ""),
            ),

            const SizedBox(height: 20),

            // Type of User Dropdown
            Text("Type of User", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedUserType,
              items: userTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedUserType = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // Stream Select + Custom Option
            Text("Stream", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: presetStreams.contains(selectedStream) ? selectedStream : null,
              hint: const Text("Select Stream"),
              items: presetStreams
                  .map((stream) => DropdownMenuItem(
                        value: stream,
                        child: Text(stream),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStream = value;
                  streamController.clear(); // user selected a preset, clear custom
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // Custom Stream Input
            Text("Or enter custom stream"),
            const SizedBox(height: 6),
            TextField(
              controller: streamController,
              decoration: InputDecoration(
                hintText: "Enter custom stream",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                selectedStream = null; // switching to custom
              },
            ),

            const Spacer(),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveChanges,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
