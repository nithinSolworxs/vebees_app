import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'enroll_edit_page.dart';
import 'program_detail_page.dart'; // <-- ADDED: for navigation

class UserProgramPage extends StatefulWidget {
  const UserProgramPage({super.key});

  @override
  State<UserProgramPage> createState() => _UserProgramPageState();
}

class _UserProgramPageState extends State<UserProgramPage> {
  final supabase = Supabase.instance.client;

  late Box programBox;
  late Box likedBox;
  late Box enrolledBox;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    initHive();
  }

  Future<void> initHive() async {
    programBox = Hive.box('programBox');
    likedBox = Hive.box('likedPrograms');
    enrolledBox = Hive.box('enrolledPrograms');

    await fetchPrograms();
    setState(() => loading = false);
  }

  Future<void> fetchPrograms() async {
    try {
      final response = await supabase
          .from('program')
          .select()
          .or('programStatus.eq.Upcoming,programStatus.eq.Live')
          .order('programStartDate', ascending: true);

      await programBox.put('list', response);
    } catch (e) {
      debugPrint("❌ Error fetching programs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final programList = programBox.get('list', defaultValue: []);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Image.asset("assets/logo.jpg", height: 32),
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
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : programList.isEmpty
              ? const Center(child: Text("No Live or Upcoming Programs"))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: programList.length,
                  itemBuilder: (context, index) {
                    final program = programList[index];
                    return buildProgramCard(program);
                  },
                ),
    );
  }

  Widget buildProgramCard(dynamic program) {
    final programId = program['programId'];
    final programImage = program['programImage'];

    final isLiked = likedBox.get(programId, defaultValue: false);
    final isEnrolled = enrolledBox.get(programId, defaultValue: false);

    final dateRange =
        "${program['programStartDate'] ?? ""} - ${program['programEndDate'] ?? ""}";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade200,
            Colors.orange.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          // -----------------------
          // HEADER IMAGE + TAP TO OPEN DETAILS
          // -----------------------
          GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailPage(program: program),
      ),
    );
  },
  child: ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
    child: programImage != null && programImage.toString().startsWith("http")
        ? Image.network(
            programImage,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              return fallbackHeader(program['programName']);
            },
          )
        : fallbackHeader(program['programName']),
  ),
),


          // ENROLLED TAG
          if (isEnrolled)
            Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "ENROLLED",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

          // -----------------------
          // CONTENT
          // -----------------------
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program['programName'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(program['programDescrip'] ?? '',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(dateRange, style: TextStyle(color: Colors.grey.shade900)),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LIKE BUTTON
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.black,
                      ),
                      onPressed: () {
                        likedBox.put(programId, !isLiked);
                        setState(() {});
                      },
                    ),

                    // ENROLL BUTTON
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEnrolled ? Colors.grey : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isEnrolled
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EnrollEditPage(programId: programId),
                                ),
                              );

                              enrolledBox.put(programId, true);
                              setState(() {});
                            },
                      child: Text(isEnrolled ? "Enrolled" : "Enroll"),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // -----------------------
  // FALLBACK HEADER UI
  // -----------------------
  Widget fallbackHeader(String title) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black45,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
