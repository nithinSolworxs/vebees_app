import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgramEditPage extends StatefulWidget {
  final Map<String, dynamic>? program; // null => Add mode

  const ProgramEditPage({super.key, this.program});

  @override
  State<ProgramEditPage> createState() => _ProgramEditPageState();
}

class _ProgramEditPageState extends State<ProgramEditPage> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ownerController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _partnerController = TextEditingController();
  final _eligibilityController = TextEditingController();

  // Dropdown values
  String? programType;
  String? programStatus;
  String? programMode;

  DateTime? startDate;
  DateTime? endDate;

  bool isEdit = false;

  @override
  void initState() {
    super.initState();

    isEdit = widget.program != null;

    if (isEdit) {
      final p = widget.program!;
      programType = p['programType'];
      programStatus = p['programStatus'];
      programMode = p['programMode'];

      _nameController.text = p['programName'] ?? '';
      _descController.text = p['programDescrip'] ?? '';
      _ownerController.text = p['programOwner'] ?? '';
      _priceController.text = p['programPrice']?.toString() ?? '';
      _discountController.text = p['programDiscount']?.toString() ?? '';
      _partnerController.text = p['programPartner'] ?? '';
      _eligibilityController.text = p['programEligiblity'] ?? '';

      if (p['programStartDate'] != null) {
        startDate = DateTime.parse(p['programStartDate']);
      }
      if (p['programEndDate'] != null) {
        endDate = DateTime.parse(p['programEndDate']);
      }
    }
  }

  Future<void> saveProgram() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start & end date")),
      );
      return;
    }

    final numDays = endDate!.difference(startDate!).inDays + 1;

    final data = {
      "programType": programType,
      "programName": _nameController.text.trim(),
      "programDescrip": _descController.text.trim(),
      "programStatus": programStatus,
      "programStartDate": startDate!.toIso8601String(),
      "programEndDate": endDate!.toIso8601String(),
      "programNumDays": numDays,
      "programOwner": _ownerController.text.trim(),
      "programPrice": int.tryParse(_priceController.text.trim()) ?? 0,
      "programDiscount": int.tryParse(_discountController.text.trim()) ?? 0,
      "programPartner": _partnerController.text.trim(),
      "programMode": programMode,
      "programEligiblity": _eligibilityController.text.trim(),
    };

    if (isEdit) {
      // UPDATE
      await supabase
          .from("program")
          .update(data)
          .eq("programId", widget.program!['programId']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Program updated successfully")),
      );
    } else {
      // INSERT
      await supabase.from("program").insert(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Program added successfully")),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Program" : "Add Program"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Program Type
              DropdownButtonFormField<String>(
                value: programType,
                decoration: const InputDecoration(labelText: "Program Type"),
                items: const [
                  "Cohort",
                  "Sprint",
                  "Huddle",
                  "Hackathon",
                  "Pitchathon",
                  "Promotion",
                  "Celebration",
                  "Health Check and Metrics",
                  "New Startup"
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => programType = v),
                validator: (v) => v == null ? "Select program type" : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Program Name"),
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),

              const SizedBox(height: 10),

              // Program Status
              DropdownButtonFormField<String>(
                value: programStatus,
                decoration: const InputDecoration(labelText: "Program Status"),
                items: const ["Upcoming", "Live", "Closed"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => programStatus = v),
                validator: (v) => v == null ? "Select status" : null,
              ),

              const SizedBox(height: 20),

              // Start Date
              ListTile(
                title: Text(
                  startDate == null
                      ? "Select Start Date"
                      : "Start Date: ${startDate!.toLocal()}".split(" ")[0],
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),

              // End Date
              ListTile(
                title: Text(
                  endDate == null
                      ? "Select End Date"
                      : "End Date: ${endDate!.toLocal()}".split(" ")[0],
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                  }
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(labelText: "Program Owner"),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: "Discount %"),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _partnerController,
                decoration:
                    const InputDecoration(labelText: "Partner"),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: programMode,
                decoration: const InputDecoration(labelText: "Program Mode"),
                items: const ["Online", "Offline"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => programMode = v),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _eligibilityController,
                decoration: const InputDecoration(labelText: "Eligibility"),
                maxLines: 2,
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: saveProgram,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(isEdit ? "Update Program" : "Add Program"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
