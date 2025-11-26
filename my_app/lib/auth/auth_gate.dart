import 'package:flutter/material.dart';
import 'package:my_app/pages/login_page.dart';
import 'package:my_app/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String> fetchUserRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return "default";

    final profile = await supabase
        .from('profile')
        .select('typeOfUser')
        .eq('userId', user.id)
        .maybeSingle();

    return profile?['typeOfUser'] ?? "default";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // 🟡 While waiting on auth state stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔵 If NOT logged in → go to login page
        if (session == null) return const LoginPage();

        // 🟢 User logged in → now fetch role
        return FutureBuilder(
          future: fetchUserRole(),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userRole = roleSnapshot.data!;
            return HomePage(userRole: userRole);
          },
        );
      },
    );
  }
}
