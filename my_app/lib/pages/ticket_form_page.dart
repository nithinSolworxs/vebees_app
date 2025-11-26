import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class TicketFormPage extends StatefulWidget {
  const TicketFormPage({super.key});

  @override
  State<TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends State<TicketFormPage> {
  final supabase = Supabase.instance.client;
  final queryController = TextEditingController();
  bool loading = false;

  Future<void> createTicket() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final queryText = queryController.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your query")),
      );
      return;
    }

    setState(() => loading = true);

    final payload = {
      'user_id': user.id,
      'query': queryText,
      'status': 'New',
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      // Insert into Supabase
      await supabase.from('ticket').insert(payload);

      // Save offline copy
      final box = await Hive.openBox('ticketsBox');
      List existing = box.get('list', defaultValue: []);
      existing.insert(0, payload);
      await box.put('list', existing);

      Navigator.pop(context); // return to list page
    } catch (e) {
      debugPrint("Error creating ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create ticket")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Ticket"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: queryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe your issue...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : createTicket,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text(
                      "Submit Ticket",
                      style: TextStyle(fontSize: 18),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
