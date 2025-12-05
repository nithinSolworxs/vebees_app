import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AdminEnrollPage extends StatefulWidget {
  const AdminEnrollPage({super.key});

  @override
  State<AdminEnrollPage> createState() => _AdminEnrollPageState();
}

class _AdminEnrollPageState extends State<AdminEnrollPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> enrollments = [];
  Map<String, String> enrollerNames = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCachedData();
    _syncFromSupabase();
  }

  // -------------------------------------------------------------
  // LOAD CACHED
  // -------------------------------------------------------------
  Future<void> _loadCachedData() async {
    try {
      final box = await Hive.openBox('admin_enrollments');
      final cached = box.get('all') ?? [];

      final List<Map<String, dynamic>> mapped =
          (cached as List).map((e) => Map<String, dynamic>.from(e)).toList();

      setState(() => enrollments = mapped);

      final uuids = mapped.map((e) => e['enUuid'] as String).toSet().toList();
      if (uuids.isNotEmpty) await _fetchEnrollerNames(uuids);
    } catch (e) {
      debugPrint('Hive load error: $e');
    }
  }

  // -------------------------------------------------------------
  // SYNC FROM SUPABASE
  // -------------------------------------------------------------
  Future<void> _syncFromSupabase() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('enroll')
          .select('*, program:enProgram(*)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fresh =
          (response as List).map((e) => Map<String, dynamic>.from(e)).toList();

      final uuids = fresh.map((e) => e['enUuid'] as String).toSet().toList();

      if (uuids.isNotEmpty) {
        final profileResp = await supabase
            .from('profile')
            .select('userId, name')
            .inFilter('userId', uuids);

        final List<Map<String, dynamic>> profileList =
            (profileResp as List).map((e) => Map<String, dynamic>.from(e)).toList();

        final nameMap = {
          for (var p in profileList) p['userId']: p['name'],
        };

        for (var item in fresh) {
          item['enrollerName'] = nameMap[item['enUuid']] ?? "Unknown";
        }
      }

      final box = await Hive.openBox('admin_enrollments');
      await box.put('all', fresh);

      setState(() => enrollments = fresh);
    } catch (e, st) {
      debugPrint("Sync error: $e\n$st");
    } finally {
      setState(() => _loading = false);
    }
  }

  // -------------------------------------------------------------
  // FETCH NAMES
  // -------------------------------------------------------------
  Future<void> _fetchEnrollerNames(List<String> uuids) async {
    if (uuids.isEmpty) return;

    try {
      final resp = await supabase
          .from('profile')
          .select('userId, name')
          .inFilter('userId', uuids);

      final List<Map<String, dynamic>> profiles =
          (resp as List).map((p) => Map<String, dynamic>.from(p)).toList();

      final Map<String, String> map = {};
      for (final p in profiles) {
        map[p['userId'].toString()] = p['name'].toString();
      }

      setState(() {
        enrollerNames = {...enrollerNames, ...map};
      });
    } catch (e) {
      debugPrint('profile fetch error: $e');
    }
  }

  // -------------------------------------------------------------
  // STATUS FILTER HELPERS
  // -------------------------------------------------------------
  bool _isEnrollStatus(String status) =>
      status == 'Upcoming' || status == 'Live';

  bool _isLearningStatus(String status) => status == 'Closed';

  // -------------------------------------------------------------
  // GROUP BY PROGRAM NAME  (SAFE MAP CONVERSION)
  // -------------------------------------------------------------
  Map<String, List<Map<String, dynamic>>> _groupByProgramName(
      List<Map<String, dynamic>> list) {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final item in list) {
      final program = item['program'] != null
          ? Map<String, dynamic>.from(item['program'])
          : <String, dynamic>{};

      final programName = (program['programName'] ?? 'Unknown Program').toString();

      groups.putIfAbsent(programName, () => []);
      groups[programName]!.add(item);
    }

    return groups;
  }

  // -------------------------------------------------------------
  // DATE FORMATTER (SAFE)
  // -------------------------------------------------------------
  String _formatDateRange(dynamic rawProgram) {
    if (rawProgram == null) return '-';

    final program = Map<String, dynamic>.from(rawProgram);

    final start = program['programStartDate']?.toString() ?? '';
    final end = program['programEndDate']?.toString() ?? '';

    if (start.isEmpty && end.isEmpty) return '-';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  // -------------------------------------------------------------
  // BUILD UI
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final enrollList = enrollments.where((e) {
      final program = e['program'] != null
          ? Map<String, dynamic>.from(e['program'])
          : <String, dynamic>{};

      final status = (program['programStatus'] ?? '').toString();
      return _isEnrollStatus(status);
    }).toList();

    final learningList = enrollments.where((e) {
      final program = e['program'] != null
          ? Map<String, dynamic>.from(e['program'])
          : <String, dynamic>{};

      final status = (program['programStatus'] ?? '').toString();
      return _isLearningStatus(status);
    }).toList();

    final enrollGroups = _groupByProgramName(enrollList);
    final learningGroups = _groupByProgramName(learningList);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset("assets/logo.jpg", height: 32),
        ),
        title: const Text(
          "Enrollers",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Enrollers"),
            Tab(text: "Learnings"),
          ],
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupedListView(groups: enrollGroups, emptyText: "No Active or Upcoming Enrollments"),
                _buildGroupedListView(groups: learningGroups, emptyText: "No Closed Programs / Learnings"),
              ],
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: _syncFromSupabase,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // -------------------------------------------------------------
  // GROUPED LIST VIEW
  // -------------------------------------------------------------
  Widget _buildGroupedListView({
    required Map<String, List<Map<String, dynamic>>> groups,
    required String emptyText,
  }) {
    if (groups.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final entries = groups.entries.toList();

    return RefreshIndicator(
      onRefresh: _syncFromSupabase,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        itemBuilder: (context, idx) {
          final programName = entries[idx].key;
          final items = entries[idx].value;

          final programRaw = items.first['program'];
          final program = programRaw != null
              ? Map<String, dynamic>.from(programRaw)
              : <String, dynamic>{};

          final programType = program['programType']?.toString() ?? '';
          final dateRange = _formatDateRange(program);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(dateRange,
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),

              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  programType,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),

              children: items.map((enrollItem) {
                final enUuid = enrollItem['enUuid'].toString();
                final name = enrollerNames[enUuid] ?? "Unknown Enroller";

                final programRaw2 = enrollItem['program'];
                final program2 = programRaw2 != null
                    ? Map<String, dynamic>.from(programRaw2)
                    : <String, dynamic>{};

                final dateRange2 = _formatDateRange(program2);

                final createdAt = enrollItem['created_at']?.toString() ?? '';
                final utr = enrollItem['utrNum']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
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

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateRange2,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              program2['programType']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            createdAt.isNotEmpty ? createdAt.split('T').first : '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          if (utr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                utr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
