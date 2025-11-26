import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/auth/auth_service.dart';
import 'package:my_app/pages/profile_edit_page.dart';
import 'package:my_app/auth/auth_gate.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  // Fetch current user profile
  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profile')
          .select()
          .eq('userId', user.id)
          .maybeSingle();

      setState(() {
        _profileData = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  // Logout
  Future<void> _logout() async {
  await authService.signOut();

  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }
}


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
     appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.black),

  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/logo.jpg', height: 28),
      const SizedBox(width: 8),
      const Text(
        "Profile",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    ],
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: _logout,
    ),
  ],
),


      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No profile found."),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          // Navigate to create new profile for this user
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileEditPage(
                                userId: user?.id ?? '',

                              ),
                            ),
                          );
                          _loadProfile();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text("Create Profile"),
                      )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Orange profile header card
                      Container(
                        width: double.infinity,
                        color: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              backgroundImage: _profileData!['profile_image_url'] != null
                                  ? NetworkImage(_profileData!['profile_image_url'])
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profileData!['nickName'] ?? 'No Nickname',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _profileData!['name'] ?? 'No Name',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    _profileData!['phone_number'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Details List
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person,
                                  color: Colors.orange),
                              title: const Text("Full Name"),
                              subtitle: Text(_profileData!['name'] ?? 'N/A'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.work_outline,
                                  color: Colors.orange),
                              title: const Text("Stream"),
                              subtitle: Text(_profileData!['stream'] ?? 'N/A'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.orange),
                              title: const Text("Address"),
                              subtitle: Text(_profileData!['address'] ?? 'N/A'),
                            ),
                          ],
                        ),
                      ),

                      // Edit button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileEditPage(
        userId: user?.id ?? '', // ✅ Pass current auth user UUID
      ),
    ),
  ).then((_) => _loadProfile());
},
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            "Edit Profile",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
