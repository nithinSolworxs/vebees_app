import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_profile_edit_page.dart';

final supabase = Supabase.instance.client;

class AdminUserPage extends StatefulWidget {
  const AdminUserPage({super.key});

  @override
  State<AdminUserPage> createState() => _AdminUserPageState();
}

class _AdminUserPageState extends State<AdminUserPage> {
  List<Map<String, dynamic>> users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _syncFromSupabase();
  }

  /// Load from Hive (Offline)
  Future<void> _loadCachedData() async {
    try {
      final box = await Hive.openBox('admin_users');
      final cached = box.get('all') ?? [];

      final mapped = (cached as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      setState(() => users = mapped);
    } catch (e) {
      debugPrint("Hive load error: $e");
    }
  }

  /// Sync from Supabase → Update Hive → Update UI
  Future<void> _syncFromSupabase() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('profile')
          .select('*')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fresh =
          (response as List).map((e) => Map<String, dynamic>.from(e)).toList();

      final box = await Hive.openBox('admin_users');
      await box.put('all', fresh);

      setState(() => users = fresh);
    } catch (e, st) {
      debugPrint("User sync error: $e\n$st");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Group users by typeOfUser
  Map<String, List<Map<String, dynamic>>> _groupByType() {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final item in users) {
      final type = (item['typeOfUser'] ?? 'New').toString();

      groups.putIfAbsent(type, () => []);
      groups[type]!.add(item);
    }
    return groups;
  }

  /// Format date
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return "-";
    return date.split("T").first;
  }

  /// Make Phone Call
  void _call(String number) async {
  final uri = Uri(scheme: "tel", path: number);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}


  /// Email
  void _mail(String email) async {
  final uri = Uri(
    scheme: "mailto",
    path: email,
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}


  @override
  Widget build(BuildContext context) {
    final groups = _groupByType();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Image.asset("assets/logo.jpg", height: 32),
        ),
        centerTitle: true,
        title: const Text("Users", style: TextStyle(color: Colors.black)),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _syncFromSupabase,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: groups.entries.map((entry) {
                  final type = entry.key;
                  final list = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...list.map((item) {
                        final name = item['name'] ?? "No Name";
                        final stream = item['stream'] ?? "-";
                        final date = _formatDate(item['created_at']);
                        final image = item['profile_image_url'];
                        final email = item['email'] ?? "";
                        final phone = item['phone_number'] ?? "";
                        //final user = item['userId'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  image != null && image.toString().isNotEmpty
                                      ? NetworkImage(image)
                                      : null,
                              child: image == null
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stream,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  "Joined: $date",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            trailing: Wrap(
                              spacing: 10,
                              children: [
                               // Call
IconButton(
  icon: const Icon(Icons.phone, color: Colors.green),
  onPressed: phone.isEmpty ? null : () => _call(phone),
),

// Email
IconButton(
  icon: const Icon(Icons.mail, color: Color.fromARGB(255, 1, 80, 110)),
  onPressed: email.isEmpty ? null : () => _mail(email),
),


                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.black),
                                  onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminProfileEditPage(
        userProfile: item,   // Send entire record
      ),
    ),
  );
},

                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 25),
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
