import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEditPage extends StatefulWidget {
  final String userId;
  const ProfileEditPage({super.key, required this.userId});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final supabase = Supabase.instance.client;

  final _nameController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedStream;
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;

  final List<String> _streamOptions = ['TSC', 'Startbee', 'Millionminds'];

  // 🟧 Load or Create Profile
  Future<void> _loadOrCreateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existingProfile = await supabase
        .from('profile')
        .select()
        .eq('userId', user.id)
        .maybeSingle();

    // 💡 CREATE profile ONLY IF first time
    if (existingProfile == null) {
      await supabase.from('profile').insert({
        'userId': user.id,
        'typeOfUser': 'User', // set only on creation
      });
      debugPrint("✅ New profile created");
    }

    final response = await supabase
        .from('profile')
        .select()
        .eq('userId', user.id)
        .maybeSingle();

    setState(() {
      _profileData = response;
      _nameController.text = response?['name'] ?? '';
      _nickNameController.text = response?['nickName'] ?? '';
      _phoneController.text = response?['phone_number'] ?? '';
      _addressController.text = response?['address'] ?? '';
      _selectedStream = response?['stream'];
    });
  }

  // 🟧 Pick Image
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // 🟧 Upload Image
  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return _profileData?['profile_image_url'];

    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final filePath = "$userId/$fileName";

    try {
      await supabase.storage.from('profileImage').upload(
        filePath,
        _imageFile!,
        fileOptions: FileOptions(
          upsert: true,
          metadata: {'owner': userId},
        ),
      );

      return supabase.storage.from('profileImage').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  // 🟧 Save Profile
  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final imageUrl = await _uploadImage(user.id);

    // 💡 DO NOT include typeOfUser here!
    final profileData = {
      'name': _nameController.text.trim(),
      'nickName': _nickNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'stream': _selectedStream,
      'profile_image_url': imageUrl,
      'userId': user.id,
    };

    try {
      await supabase.from('profile').upsert(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrCreateProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _profileData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profileData?['profile_image_url'] != null
                              ? NetworkImage(_profileData!['profile_image_url'])
                              : const AssetImage('assets/default_profile.png'))
                          as ImageProvider,
                      child: (_imageFile == null &&
                              _profileData?['profile_image_url'] == null)
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nickNameController,
                    decoration: InputDecoration(
                      labelText: "Nick Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _selectedStream,
                    items: _streamOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStream = v),
                    decoration: InputDecoration(
                      labelText: "Stream",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: "Address",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Changes",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
