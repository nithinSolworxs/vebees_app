import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class TicketAdminEditPage extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const TicketAdminEditPage({super.key, required this.ticketData});

  @override
  State<TicketAdminEditPage> createState() => _TicketAdminEditPageState();
}

class _TicketAdminEditPageState extends State<TicketAdminEditPage> {
  late TextEditingController _responseController;
  late String _status;

  @override
  void initState() {
    super.initState();

    _responseController =
        TextEditingController(text: widget.ticketData["response"] ?? "");

    _status = widget.ticketData["status"] ?? "New";
  }

  /// --------------------------- SAVE TO SUPABASE ---------------------------
  Future<void> _saveTicket() async {
  try {
    final int id = widget.ticketData["id"];  // <-- FIXED (int)

    await supabase.from("ticket").update({
      "response": _responseController.text.trim(),
      "status": _status,
    }).eq("id", id);  // <-- now matches integer type

    await _updateLocalHive(id);

    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    debugPrint("Save error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error saving ticket")),
    );
  }
}


  /// --------------------------- UPDATE HIVE CACHE ---------------------------
Future<void> _updateLocalHive(int id) async {   // <-- FIXED

    final box = await Hive.openBox("admin_tickets");
    final list = box.get("all", defaultValue: []) as List;

    final updated = list.map((item) {
      final map = Map<String, dynamic>.from(item);
      if (map["id"] == id) {
        map["response"] = _responseController.text.trim();
        map["status"] = _status;
      }
      return map;
    }).toList();

    await box.put("all", updated);
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.ticketData["query"] ?? "-";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Ticket"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// --------------------------- QUERY (READ ONLY) ---------------------------
            const Text(
              "Query",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade200,
              ),
              child: Text(
                query,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            /// --------------------------- RESPONSE INPUT ---------------------------
            const Text(
              "Response",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: _responseController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Enter response here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// --------------------------- STATUS DROPDOWN ---------------------------
            const Text(
              "Status",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: "New", child: Text("New")),
                DropdownMenuItem(value: "Inprogress", child: Text("Inprogress")),
                DropdownMenuItem(value: "Closed", child: Text("Closed")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _status = val);
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// --------------------------- SAVE BUTTON ---------------------------
            ElevatedButton(
              onPressed: _saveTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
