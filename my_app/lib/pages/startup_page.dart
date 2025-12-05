import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'startup_form_page.dart';
import 'startup_detail_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final supabase = Supabase.instance.client;
  late Box startupBox;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initHiveAndLoad();
  }

  Future<void> initHiveAndLoad() async {
    startupBox = Hive.box('startupBox'); // Already opened
    await fetchStartupsFromSupabase();
    setState(() => loading = false);
  }

  Future<void> fetchStartupsFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('startup')
          .select()
          .eq('startupUuid', user.id)
          .order('created_at', ascending: false);

      await startupBox.put('list', response);
    } catch (e) {
      debugPrint("Supabase fetch failed. Using Hive cache.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final startupList = startupBox.get('list', defaultValue: []);

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
              "My Startups",
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
            MaterialPageRoute(builder: (_) => const StartupFormPage()),
          );
          await fetchStartupsFromSupabase();
          setState(() {});
        },
        label: const Text("Add Startup"),
        icon: const Icon(Icons.add),
      ),

      body: startupList.isEmpty
          ? const Center(child: Text("No startups added yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: startupList.length,
              itemBuilder: (context, index) {
                final item = startupList[index];

                return _buildStartupCard(
                  item: item,
                  colorIndex: index,
                );
              },
            ),
    );
  }

  // ------------ STARTUP CARD WITH EDIT BUTTON + TAP ------------

  Widget _buildStartupCard({
    required Map item,
    required int colorIndex,
  }) {
    final List<Color> gradientColors = [
      Colors.orange,
      Colors.purple,
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.teal,
    ];

    final color = gradientColors[colorIndex % gradientColors.length];

    final sector = item['sector'] ?? "";
    final problem = item['problem'] ?? "";
    final solution = item['solution'] ?? "";

    return GestureDetector(
      onTap: () {
        // 👉 GO TO DETAILS PAGE ON ROW CLICK
       Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => StartupDetailPage(
      startup: Map<String, dynamic>.from(item),
    ),
  ),
);

      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),

        child: Stack(
          children: [
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sector,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  problem,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  solution,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),

            // ---------- EDIT BUTTON AT BOTTOM RIGHT ----------
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  // Stop card tap from triggering
                  FocusScope.of(context).requestFocus(FocusNode());

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StartupFormPage(
                        editData: item, // pass full row data
                      ),
                    ),
                  );

                  await fetchStartupsFromSupabase();
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
