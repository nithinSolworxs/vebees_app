import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enrollment_model.dart';

final supabase = Supabase.instance.client;

class EnrollUserPage extends StatefulWidget {
  const EnrollUserPage({super.key});

  @override
  State<EnrollUserPage> createState() => _EnrollUserPageState();
}

class _EnrollUserPageState extends State<EnrollUserPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final user = Supabase.instance.client.auth.currentUser; 
  List<EnrollmentModel> enrollments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedData();
    _syncFromSupabase();
  }

  /// ---------------- LOAD FROM HIVE ----------------
  Future<void> _loadCachedData() async {
    final box = await Hive.openBox("enrollments");
    final cached = box.get(user!.id) ?? [];

    final mapped = (cached as List)
        .map((e) => EnrollmentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    setState(() => enrollments = mapped);
  }

  /// ---------------- FETCH FROM SUPABASE ----------------
  Future<void> _syncFromSupabase() async {
    final response = await supabase
        .from('enroll')
        .select('*, program:enProgram(*)')
        .eq('enUuid', user!.id)
        .order('created_at', ascending: false);

    final fresh = (response as List)
        .map((e) => EnrollmentModel.fromJson(e))
        .toList();

    // Update memory + Hive
    final box = await Hive.openBox("enrollments");
    await box.put(user!.id, response);

    setState(() => enrollments = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final enrollFiltered = enrollments.where((item) {
      final status = item.program['programStatus'];
      return status == "Upcoming" || status == "Live";
    }).toList();

    final learningFiltered = enrollments.where((item) {
      final status = item.program['programStatus'];
      return status == "Closed";
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cohort"),
        backgroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: "Enroll"),
            Tab(text: "Learnings"),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _programList(enrollFiltered, "No Active or Upcoming Programs 🎯"),
          _programList(learningFiltered, "No Completed Programs Yet 📚"),
        ],
      ),
    );
  }

  /// ---------------- LIST VIEW BUILDER ----------------
  Widget _programList(List<EnrollmentModel> list, String emptyText) {
    if (list.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return RefreshIndicator(
      onRefresh: _syncFromSupabase,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final program = list[index].program;
          return _buildProgramCard(
            programName: program['programName'],
            price: program['programPrice'].toString(),
            status: program['programStatus'],
          );
        },
      ),
    );
  }

  /// ---------------- CARD UI ----------------
  Widget _buildProgramCard({
    required String programName,
    required String price,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.orange.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(programName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 4),
                Text(
                  "₹ $price",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
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
