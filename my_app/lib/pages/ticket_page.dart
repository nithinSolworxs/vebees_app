import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'ticket_form_page.dart'; // <-- NEW IMPORT
import 'package:intl/intl.dart';

class TicketPage extends StatefulWidget {
  const TicketPage({super.key});

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  final supabase = Supabase.instance.client;
  late Box ticketsBox;
  bool loading = true;

 @override
void initState() {
  super.initState();
  ticketsBox = Hive.box('ticketsBox');
  loadData();
}

Future<void> loadData() async {
  await fetchTicketsFromSupabase();
  setState(() => loading = false);
}


  Future<void> fetchTicketsFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('ticket')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      await ticketsBox.put('list', response);
    } catch (e) {
      debugPrint('Supabase fetch failed. Using Hive cache.');
    }
  }

  @override
  Widget build(BuildContext context) {
    List ticketList = ticketsBox.get('list', defaultValue: []);

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.black),

  title: Row(
    children: [
      Image.asset(
        'assets/logo.jpg',
        height: 28,
      ),
      const SizedBox(width: 10),
      const Text(
        "My Tickets",
          style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),



      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TicketFormPage()),
          );

          // Refresh after coming back
          fetchTicketsFromSupabase();
          setState(() {});
        },
        label: const Text("Create Ticket"),
        icon: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ticketList.isEmpty
              ? const Center(
                  child: Text(
                    "No tickets raised yet",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ticketList.length,
                  itemBuilder: (context, index) {
                    final item = ticketList[index];

                    final query = item['query'] ?? '';
                    final status = item['status'] ?? 'New';
                    final dateRaw = item['created_at'] ?? '';
                    final formattedDate = dateRaw.isNotEmpty
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(DateTime.parse(dateRaw).toLocal())
                        : '';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        title: Text(
                          query,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              "Status: $status",
                              style: TextStyle(
                                color: status == "New"
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
