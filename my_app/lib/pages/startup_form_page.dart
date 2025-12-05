import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StartupFormPage extends StatefulWidget {
  final Map? editData;   // <-- ADD THIS

  const StartupFormPage({super.key, this.editData});

  @override
  State<StartupFormPage> createState() => _StartupFormPageState();
}

class _StartupFormPageState extends State<StartupFormPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final nameCtrl = TextEditingController();
  final sectorCtrl = TextEditingController();
  final problemCtrl = TextEditingController();
  final solutionCtrl = TextEditingController();
  final uspCtrl = TextEditingController();
  final stageCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final founderNameCtrl = TextEditingController();
  final founderEmailCtrl = TextEditingController();
  final founderPhoneCtrl = TextEditingController();
  final founderLinkedInCtrl = TextEditingController();
  final founderRoleCtrl = TextEditingController();

  bool loading = false;
  late Box startupBox;

  bool get isEditing => widget.editData != null;

  @override
  void initState() {
    super.initState();
    initHiveAndLoadData();
  }

  Future<void> initHiveAndLoadData() async {
    startupBox = await Hive.openBox('startupBox');

    // ---------- PREFILL FORM IN EDIT MODE ----------
    if (isEditing) {
      final d = widget.editData!;
      nameCtrl.text = d['legalName'] ?? "";
      sectorCtrl.text = d['sector'] ?? "";
      problemCtrl.text = d['problem'] ?? "";
      solutionCtrl.text = d['solution'] ?? "";
      uspCtrl.text = d['usp'] ?? "";
      stageCtrl.text = d['stage'] ?? "";
      addressCtrl.text = d['address'] ?? "";
      websiteCtrl.text = d['websiteLink'] ?? "";
      founderNameCtrl.text = d['founderName'] ?? "";
      founderEmailCtrl.text = d['founderEmail'] ?? "";
      founderPhoneCtrl.text = d['founderPhone'] ?? "";
      founderLinkedInCtrl.text = d['founderLinkedin'] ?? "";
      founderRoleCtrl.text = d['founderRole'] ?? "";
    }
  }

  // -------------------------------------------------------------------
  // INSERT OR UPDATE
  // -------------------------------------------------------------------

  Future<void> saveStartup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    final payload = {
      "startupUuid": user.id,
      "legalName": nameCtrl.text.trim(),
      "sector": sectorCtrl.text.trim(),
      "problem": problemCtrl.text.trim(),
      "solution": solutionCtrl.text.trim(),
      "usp": uspCtrl.text.trim(),
      "stage": stageCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "websiteLink": websiteCtrl.text.trim(),
      "founderName": founderNameCtrl.text.trim(),
      "founderEmail": founderEmailCtrl.text.trim(),
      "founderPhone": founderPhoneCtrl.text.trim(),
      "founderLinkedIn": founderLinkedInCtrl.text.trim(),
      "founderRole": founderRoleCtrl.text.trim(),
    };

    try {
      if (isEditing) {
        // =============================
        // UPDATE STARTUP
        // =============================
        final id = widget.editData!['startupld'];

        final response = await supabase
            .from('startup')
            .update(payload)
            .eq('startupld', id)
            .select();

        // ---- update Hive cache ----
        final list = startupBox.get('list', defaultValue: []);
        final index = list.indexWhere((e) => e['startupld'] == id);
        if (index != -1) {
          list[index] = response.first;
          await startupBox.put('list', list);
        }
      } else {
        // =============================
        // INSERT NEW STARTUP
        // =============================
        final response = await supabase.from('startup').insert(payload).select();

        final list = startupBox.get('list', defaultValue: []);
        list.insert(0, response.first);
        await startupBox.put('list', list);
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      debugPrint("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving startup: $e")),
      );
    }

    setState(() => loading = false);
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Startup" : "Add Startup"),
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _headerCard(),

                    const SizedBox(height: 20),

                    _buildTextField("Startup Legal Name", nameCtrl),
                    _buildTextField("Sector", sectorCtrl),
                    _buildTextField("Problem", problemCtrl, maxLines: 3),
                    _buildTextField("Solution", solutionCtrl, maxLines: 3),
                    _buildTextField("Unique Selling Point (USP)", uspCtrl),
                    _buildTextField("Stage", stageCtrl),
                    _buildTextField("Address", addressCtrl),
                    _buildTextField("Website", websiteCtrl),
                    _buildTextField("Founder Name", founderNameCtrl),
                    _buildTextField("Founder Email", founderEmailCtrl),
                    _buildTextField("Founder Phone", founderPhoneCtrl),
                    _buildTextField("Founder LinkedIn", founderLinkedInCtrl),
                    _buildTextField("Founder Role", founderRoleCtrl),

                    const SizedBox(height: 25),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEditing ? Colors.blue : Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: saveStartup,
                      icon: Icon(
                        isEditing ? Icons.check : Icons.save,
                        color: Colors.white,
                      ),
                      label: Text(
                        isEditing ? "Update Startup" : "Save Startup",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // -------------------------------------------------------------------

  Widget _buildTextField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: (v) => v == null || v.isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // HEADER CARD
  // -------------------------------------------------------------------

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFB74D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing
                ? "Edit Your Startup Profile"
                : "Create Your Startup Profile",
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEditing
                ? "Update the details below."
                : "Fill the details below to add your startup.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
