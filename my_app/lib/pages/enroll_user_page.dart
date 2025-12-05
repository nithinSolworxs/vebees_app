import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';


import '../models/enrollment_model.dart';
import '../razorpay/razorpay_keys.dart';


final supabase = Supabase.instance.client;


class EnrollUserPage extends StatefulWidget {
 const EnrollUserPage({super.key});


 @override
 State<EnrollUserPage> createState() => _EnrollUserPageState();
}


class _EnrollUserPageState extends State<EnrollUserPage>
   with SingleTickerProviderStateMixin {
 late TabController _tabController;
 late Razorpay _razorpay;


 final user = Supabase.instance.client.auth.currentUser;
 List<EnrollmentModel> enrollments = [];
 int? selectedEnrollId;


 @override
 void initState() {
   super.initState();


   _tabController = TabController(length: 2, vsync: this);
   _setupRazorpay();


   _loadCachedData();
   _syncFromSupabase();
 }


 /// ---------------------- RAZORPAY SETUP --------------------------
 void _setupRazorpay() {
   _razorpay = Razorpay();
   _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
   _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
   _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
 }


 /// ---------------------- PAYMENT SUCCESS -------------------------
 Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
   ScaffoldMessenger.of(context).showSnackBar(
     const SnackBar(content: Text("Payment Successful")),
   );


   if (selectedEnrollId == null) return;


   // Find this enrollment
   final enrollment =
       enrollments.firstWhere((e) => e.enrollId == selectedEnrollId);


   final programPrice =
       int.tryParse(enrollment.program['programPrice'].toString()) ?? 0;


   // 1️⃣ UPDATE ENROLL TABLE (status updated to Paid)
   await supabase.from("enroll").update({
     "paymentStatus": "Paid",
     "paymentId": response.paymentId,
     "orderId": response.orderId,
     "signature": response.signature,
     "paymentAmount": programPrice,
     "paymentCurrency": "INR",
     "paymentDate": DateTime.now().toIso8601String(),
     "paymentMode": "online",
   }).eq("enId", selectedEnrollId!);


   // 2️⃣ INSERT PAYMENT RECORD
   await supabase.from("payments").insert({
     "user_id": user!.id,
     "enroll_id": selectedEnrollId,
     "payment_id": response.paymentId,
     "order_id": response.orderId,
     "signature": response.signature,
     "amount": programPrice,
     "currency": "INR",
     "status": "success",
     "payment_mode": "online",
   });


   await _syncFromSupabase();
   selectedEnrollId = null;
 }


 /// ---------------------- PAYMENT FAILURE -------------------------
 void _handlePaymentError(PaymentFailureResponse response) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text("Payment failed: ${response.message}")),
   );
 }


 /// ---------------------- EXTERNAL WALLET -------------------------
 void _handleExternalWallet(ExternalWalletResponse response) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text("External Wallet: ${response.walletName}")),
   );
 }


 /// ---------------------- OPEN PAYMENT ----------------------------
 void _startPayment(String programName, int price) {
   var options = {
     'key': RazorpayKeys.keyId,
     'amount': price * 100,
     'name': programName,
     'description': 'Program Enrollment Fee',
     'prefill': {
       'contact': '9876543210',
       'email': user?.email ?? "user@example.com"
     },
     // 👇 You will later add: 'order_id': <from edge function>
   };


   _razorpay.open(options);
 }


 /// ---------------------- LOAD CACHED DATA ------------------------
 Future<void> _loadCachedData() async {
   final box = await Hive.openBox("enrollments");
   final cached = box.get(user!.id) ?? [];


   final mapped = (cached as List)
       .map((e) => EnrollmentModel.fromJson(Map<String, dynamic>.from(e)))
       .toList();


   setState(() => enrollments = mapped);
 }


 /// ---------------------- SYNC DATA FROM SUPABASE -----------------
 Future<void> _syncFromSupabase() async {
   final response = await supabase
       .from('enroll')
       .select('*, program:enProgram(*)')
       .eq('enUuid', user!.id)
       .order('created_at', ascending: false);


   final fresh = (response as List)
       .map((e) => EnrollmentModel.fromJson(e))
       .toList();


   final box = await Hive.openBox("enrollments");
   await box.put(user!.id, response);


   setState(() => enrollments = fresh);
 }


 @override
 void dispose() {
   _razorpay.clear();
   super.dispose();
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
 backgroundColor: Colors.white,
 centerTitle: true,
 elevation: 0,


 // ---------------- TOP BAR WITH LOGO + TITLE ----------------
 title: Row(
   mainAxisSize: MainAxisSize.min,
   children: [
     Image.asset(
       "assets/logo.jpg",
       height: 32,
     ),
     const SizedBox(width: 10),
     const Text(
       "Cohort",
       style: TextStyle(
         color: Colors.black,
         fontWeight: FontWeight.w600,
         fontSize: 18,
       ),
     ),
   ],
 ),


 // ---------------- TAB BAR ----------------
 bottom: TabBar(
   controller: _tabController,
   indicatorColor: Colors.orange,
   labelColor: Colors.orange,
   unselectedLabelColor: Colors.grey,
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


 /// ---------------------- PROGRAM LIST ----------------------------
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
           enrollId: list[index].enrollId,
           programName: program['programName'] ?? "No Name",
           price: int.tryParse(program['programPrice'].toString()) ?? 0,
           status: program['programStatus'] ?? "Unknown",
           paymentStatus: list[index].paymentStatus,     // ✅ FIXED
         );
       },
     ),
   );
 }


 /// ---------------------- CARD UI ----------------------------
 Widget _buildProgramCard({
   required int enrollId,
   required String programName,
   required int price,
   required String status,
   required String paymentStatus,
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
                       fontSize: 18, fontWeight: FontWeight.w700)),
               const SizedBox(height: 4),
               Text("₹ $price",
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.orange.shade800,
                     fontWeight: FontWeight.w600,
                   )),
               const SizedBox(height: 4),
               Text(status,
                   style: const TextStyle(
                     fontSize: 13,
                     color: Colors.grey,
                   )),
             ],
           ),
         ),


         (paymentStatus == "Paid")
             ? const Text("Paid",
                 style: TextStyle(color: Colors.green, fontSize: 16))
             : ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.orange,
                   foregroundColor: Colors.white,
                 ),
                 onPressed: () {
                   selectedEnrollId = enrollId;
                   _startPayment(programName, price);
                 },
                 child: const Text("Pay"),
               ),
       ],
     ),
   );
 }
}
