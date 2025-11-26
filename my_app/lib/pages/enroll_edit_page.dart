import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class EnrollEditPage extends StatefulWidget {
  final dynamic programId;
  


  const EnrollEditPage({super.key, required this.programId});

  @override
  State<EnrollEditPage> createState() => _EnrollEditPageState();
}

class _EnrollEditPageState extends State<EnrollEditPage> {
  final supabase = Supabase.instance.client;

  final _utrController = TextEditingController();
  final _remarkController = TextEditingController();

  bool loading = false;

  Future<void> _submitEnrollment() async {
    if (_utrController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter UTR number")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      await supabase.from('enroll').insert({
        'enProgram': widget.programId,
        'enUuid': user.id,
        'utrNum': _utrController.text.trim(),
        'enRemark': _remarkController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context, true); // Send success back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _utrController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enroll Program"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                labelText: "UTR Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 18),

            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: "Remarks",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submitEnrollment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Enrollment",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
