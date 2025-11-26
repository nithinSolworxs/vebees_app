import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'program_edit_page.dart';


class ProgramAdminPage extends StatefulWidget {
  const ProgramAdminPage({super.key});

  @override
  State<ProgramAdminPage> createState() => _ProgramAdminPageState();
}

class _ProgramAdminPageState extends State<ProgramAdminPage> {
  final supabase = Supabase.instance.client;
  late Box programBox;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initHiveAndLoad();
  }

  Future<void> initHiveAndLoad() async {
    programBox = Hive.box("programBox");
    await fetchPrograms();
    setState(() => loading = false);
  }

  Future<void> fetchPrograms() async {
    try {
      final response = await supabase
          .from("program")
          .select()
          .order("created_at", ascending: false);

      await programBox.put("list", response);
    } catch (e) {
      debugPrint("Supabase failed, using Hive cache.");
    }
  }

  // Random gradient generator for card header
  LinearGradient generateRandomGradient() {
    final random = Random();
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return LinearGradient(
      colors: [
        colors[random.nextInt(colors.length)],
        colors[random.nextInt(colors.length)],
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = programBox.get("list", defaultValue: []);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Program",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text("Add Program"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgramEditPage()),
          );
          await fetchPrograms();
          setState(() {});
        },
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(
                  child: Text("No programs added yet."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final programType = item["programType"] ?? "";
                    final programName = item["programName"] ?? "";
                    final start = item["programStartDate"] ?? "";
                    final end = item["programEndDate"] ?? "";

                    return _programCard(
                      programType: programType,
                      programName: programName,
                      dateRange: "$start → $end",
                      data: item,
                    );
                  },
                ),
    );
  }

  Widget _programCard({
    required String programType,
    required String programName,
    required String dateRange,
    required Map data,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER IMAGE (gradient placeholder)
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: generateRandomGradient(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary label (programType)
                Text(
                  programType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary header (programName)
                Text(
                  programName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                // Tertiary text (date range)
                Text(
                  dateRange,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgramEditPage(
                         program: Map<String, dynamic>.from(data),
                           ),
                        ),
                      );

                      await fetchPrograms();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
