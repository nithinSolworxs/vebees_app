import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'startup_detail_page.dart';

class AdminStartupPage extends StatefulWidget {
  const AdminStartupPage({super.key});

  @override
  State<AdminStartupPage> createState() => _AdminStartupPageState();
}

class _AdminStartupPageState extends State<AdminStartupPage> {
  final supabase = Supabase.instance.client;
  late Box startupBox;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initHiveAndLoad();
  }

  Future<void> initHiveAndLoad() async {
    startupBox = Hive.box('startupBox'); // already opened in main.dart
    await fetchStartupsFromSupabase();
    setState(() => loading = false);
  }

  // FETCH ALL STARTUPS (not by user)
  Future<void> fetchStartupsFromSupabase() async {
    try {
      final response = await supabase
          .from('startup')
          .select()
          .order('created_at', ascending: false);

      await startupBox.put('admin_list', response);
    } catch (e) {
      debugPrint("Supabase fetch failed. Using Hive cache.");
    }
  }

  // ---------------- UI -------------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final startupList = startupBox.get('admin_list', defaultValue: []);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset("assets/logo.jpg", height: 32),
            const SizedBox(width: 10),
            const Text(
              "All Startups",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),

      // 🚫 NO ADD BUTTON FOR ADMIN
      floatingActionButton: null,

      body: startupList.isEmpty
          ? const Center(child: Text("No startups found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: startupList.length,
              itemBuilder: (context, index) {
                final item = startupList[index];

                final name = item['startupName'] ?? "Untitled";
                final sector = item['sector'] ?? "";
                final problem = item['problem'] ?? "";

                return _buildStartupCard(
                  name: name,
                  sector: sector,
                  problem: problem,
                  index: index,
                  data: item,
                );
              },
            ),
    );
  }

  // ---------- CARD UI -------------

  Widget _buildStartupCard({
    required String name,
    required String sector,
    required String problem,
    required int index,
    required Map data,
  }) {
    final List<Color> colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.teal,
      Colors.pink,
      Colors.redAccent,
      Colors.indigo,
    ];

    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () {
        
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StartupDetailPage(startup: Map<String, dynamic>.from(data))
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              sector,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              problem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
