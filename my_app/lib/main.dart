import 'package:flutter/material.dart';
import 'package:my_app/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // REQUIRED before async init

  // 🔹 Initialize Hive
  await Hive.initFlutter();

  // 🔹 Open your Hive boxes here (add all your boxes)
  await Hive.openBox('ticketsBox');
  await Hive.openBox('startupBox');
  await Hive.openBox('programBox');
  await Hive.openBox('likedPrograms');
  await Hive.openBox('enrolledPrograms');
 

  // 🔹 Initialize Supabase
  await Supabase.initialize(
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tbWJkcHBtcGl3dnVmYXVqeHhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0MDM4MzIsImV4cCI6MjA3Nzk3OTgzMn0.EYS21ms5dr0T9j886-9dXfGqAonJfXdO6Bjvj0Gdhh0",
    url: "https://ommbdppmpiwvufaujxxo.supabase.co",
  );

  await NotificationService.init(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}
