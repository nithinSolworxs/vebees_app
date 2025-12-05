import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'program_edit_page.dart';
import 'program_detail_page.dart';
import 'program_calendar_page.dart';

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
      debugPrint("Supabase failed, loading from Hive cache.");
    }
  }

  // random gradient for items without images
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
    final List items = programBox.get("list", defaultValue: []);
    final programList =
    items.map((e) => Map<String, dynamic>.from(e)).toList();


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset(
              "assets/logo.jpg",
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              "Programs",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Stack(
  children: [
    // Calendar FAB (Top Button)
    Positioned(
      bottom: 90,
      right: 16,
      child: FloatingActionButton(
        heroTag: "calendarBtn",
        backgroundColor: Colors.blue,
        child: const Icon(Icons.calendar_month),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramCalendarPage(programs: programList),
            ),
          );
        },
      ),
    ),

    // Add Program FAB (Bottom Button)
    Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        heroTag: "addProgramBtn",
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text("Add Program"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProgramEditPage(),
            ),
          );
          await fetchPrograms();
          setState(() {});
        },
      ),
    ),
  ],
),


      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text("No programs added yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    final programType = item["programType"] ?? "";
                    final programName = item["programName"] ?? "";
                    final start = item["programStartDate"] ?? "";
                    final end = item["programEndDate"] ?? "";

                    // FIX: Build full Supabase image URL
                    final rawImage = item["programImage"];
                    final imageUrl = (rawImage != null &&
                            rawImage.toString().isNotEmpty)
                        ? supabase.storage
                            .from('programImage')
                            .getPublicUrl(rawImage)
                        : null;

                    return _programCard(
                      programType: programType,
                      programName: programName,
                      dateRange: "$start → $end",
                      data: item,
                      imageUrl: imageUrl,
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
    required String? imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgramDetailPage(
              program: Map<String, dynamic>.from(data),
            ),
          ),
        );
      },
      child: Container(
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
            // image / gradient header
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: (imageUrl == null || imageUrl.isEmpty)
                    ? generateRandomGradient()
                    : null,
              ),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: generateRandomGradient(),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: generateRandomGradient(),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18)),
                            ),
                          );
                        },
                      ),
                    )
                  : null,
            ),

            // content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    programName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateRange,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // EDIT BUTTON
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
      ),
    );
  }
}
