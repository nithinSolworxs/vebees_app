import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ticket_admin_edit_page.dart';

final supabase = Supabase.instance.client;

class AdminTicketPage extends StatefulWidget {
  const AdminTicketPage({super.key});

  @override
  State<AdminTicketPage> createState() => _AdminTicketPageState();
}

class _AdminTicketPageState extends State<AdminTicketPage> {
  List<Map<String, dynamic>> tickets = [];
  Map<String, dynamic> userNames = {}; // {userId: name}
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCached();
    _syncFromSupabase();
  }

  /// ---------------------- LOAD FROM HIVE ----------------------
  Future<void> _loadCached() async {
    final box = await Hive.openBox("admin_tickets");
    final cached = box.get("all") ?? [];

    setState(() {
      tickets = (cached as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  /// ---------------------- FETCH USER NAMES ----------------------
  Future<void> _fetchUserNames(List<String> userIds) async {
    if (userIds.isEmpty) return;

    final response = await supabase
        .from("profile")
        .select("userId, name")
        .inFilter("userId", userIds);

    for (var row in response as List) {
      userNames[row["userId"]] = row["name"];
    }
  }

  /// ---------------------- SYNC FROM SUPABASE ----------------------
  Future<void> _syncFromSupabase() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from("ticket")
          .select("*")
          .order("created_at", ascending: false);

      final fresh = (response as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Fetch user names
      final userIds =
          fresh.map((e) => e["user_id"] as String).toSet().toList();
      await _fetchUserNames(userIds);

      // Save to Hive
      final box = await Hive.openBox("admin_tickets");
      await box.put("all", fresh);

      setState(() => tickets = fresh);
    } catch (e, st) {
      debugPrint("Ticket sync error: $e\n$st");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ---------------------- GROUPING ----------------------
  Map<String, List<Map<String, dynamic>>> _groupByStatus() {
    final Map<String, List<Map<String, dynamic>>> groups = {
      "New": [],
      "Inprogress": [],
      "Closed": [],
    };

    for (var t in tickets) {
      final status = t["status"] ?? "New";
      if (!groups.containsKey(status)) groups[status] = [];
      groups[status]!.add(t);
    }

    return groups;
  }

  /// ---------------------- FORMAT DATE ----------------------
  String _formatDate(String? date) {
    if (date == null) return "-";
    return date.split("T").first;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByStatus();
    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Tickets", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _syncFromSupabase,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: groups.entries.map((entry) {
  final status = entry.key;
  final list = entry.value;

  // HIDE EMPTY SECTION
  if (list.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        status,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),

      ...list.map((t) {
        final name = userNames[t["user_id"]] ?? "Unknown User";
        final query = t["query"] ?? "-";
        final resp = t["response"] ?? "";
        final date = _formatDate(t["created_at"]);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 12),

                // EXPANDED text area
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(query),

                      if (resp.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(resp),
                      ],
                    ],
                  ),
                ),

                Column(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push( 
                          context,
                            MaterialPageRoute( 
                               builder: (_) => TicketAdminEditPage(ticketData: t), 
                                ),  );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),

      const SizedBox(height: 30),
    ],
  );
}).toList(),

              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _syncFromSupabase,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
